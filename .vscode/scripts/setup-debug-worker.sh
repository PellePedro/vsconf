#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SKYRAMP_DEV_WORKER=skyramp-dev-worker:latest
NS=worker
DEBUG_PORT=8001
CLUSTER_NAME=skyramp-debug
GIT_POD_ROOT=/home/workspace/skyramp
PID_FILE="/tmp/kubectl_port_forward.pid"

compose_dir=$SCRIPT_DIR/moby
kind_dir=$SCRIPT_DIR/k8s

echo "SCRIPT_DIR: $SCRIPT_DIR"

if ! command -v fzf &> /dev/null; then
    echo "fzf is not installed."
    echo "You can install fzf on Linux using:"
    echo "  sudo apt-get install fzf    # Debian/Ubuntu"
    echo "  sudo yum install fzf        # CentOS/RHEL"
    echo "  sudo pacman -S fzf          # Arch Linux"
    echo "  brew install fzf            # macOS"
fi

# Function to check if the port-forward process is running
is_process_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Function to kill the port-forward process if running
kill_existing_port_forward_process() {
    if is_process_running; then
        PID=$(cat "$PID_FILE")
        echo "Killing existing kubectl port-forward process with PID: $PID"
        kill "$PID"
        sleep 5
        rm "$PID_FILE"
    fi
}

function debug_kind_worker {
    DEBUG_PORT=8001
    kill_existing_port_forward_process
    echo "Port forwarding worker to http://localhost:8001?folder=/home/workspace/skyramp"
    kubectl port-forward --address 0.0.0.0 deployment/skyramp-worker -n ${NS} ${DEBUG_PORT}:3000 &
    NEW_PID=$!
    echo $NEW_PID > "$PID_FILE"
    echo "kubectl port-forward started with PID: $NEW_PID"
    if [[ $(uname -s) == "Darwin" ]]; then
        open "http://localhost:8001/?folder=/home/workspace/skyramp"
    fi
}

function debug_compose_worker {
    DEBUG_PORT=6001
    if [[ $(uname -s) == "Darwin" ]]; then
        open "http://localhost:6001/?folder=/home/workspace/skyramp"
    fi
}

# Docker Compose
#
# launch compose with worker in debug dev container
function compose_up_debug_worker {
    pushd $compose_dir
    docker compose up -d --wait
    docker compose exec -T worker /bin/bash <<EOF
pushd ${GIT_POD_ROOT}
git config --global --add safe.directory ${GIT_POD_ROOT}
rm -f /usr/local/lib/skyramp/idl/grpc/skyramp*.*
rm -rf /etc/skyramp/runtime/*
cp ${GIT_POD_ROOT}/scripts/skyramp-init.py /
ln -s ${GIT_POD_ROOT}/web/templates /home/workspace/skyramp/tmpl
go run ./cmd/airgap
go mod download
EOF
    echo "Debug worker started on http://localhost:6001/?folder=/home/workspace/skyramp"
    popd
}

function compose_down_debug_worker {
    pushd $compose_dir
    docker compose down
    popd
}

function create_cluster() {
  # delete cluster if it exists
  if kind get clusters | grep -q "${CLUSTER_NAME}"; then
      echo "Cluster ${CLUSTER_NAME} found. Deleting..."
      kind delete cluster --name "${CLUSTER_NAME}"
  fi

  cat <<EOF | kind create cluster --name=${CLUSTER_NAME} -v7 --wait 1m --retain --config=-
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
nodes:
  - role: control-plane
    extraMounts:
      - hostPath: ${HOME}/git/letsramp/skyramp
        containerPath: /host-mount
    extraPortMappings:
      - containerPort: 3000
        hostPort: 3000
EOF
  kubectl create ns ${NS}
}

function build_devcontainer() {
  # build debug image
  pushd ${compose_dir}
  docker compose build
  popd
}
# kubectl taint nodes hostpath-control-plane node-role.kubernetes.io/control-plane:NoSchedule-

function load_worker() {
  kind load docker-image ${SKYRAMP_DEV_WORKER} --name ${CLUSTER_NAME}
}

function deploy_worker() {
  if ! kubectl get namespace "$NS" > /dev/null 2>&1; then
      kubectl create namespace "$NS"
      if [[ $? -eq 0 ]]; then
          echo "Namespace '$NS' successfully created."
      else
          echo "Failed to create namespace '$NS'."
          return 1
      fi
  else
      echo "Namespace '$NS' already exists."
  fi
  kind load docker-image ${SKYRAMP_DEV_WORKER} --name ${CLUSTER_NAME}
  pushd ${SCRIPT_DIR}/k8s
  kubectl apply -k overlay -n ${NS}
  kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=skyramp-worker,app.kubernetes.io/instance=dev -n ${NS} --timeout=300s
  POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=skyramp-worker -n worker -o jsonpath="{.items[0].metadata.name}")
  kubectl exec -it $POD_NAME -n worker -- /bin/bash <<EOF
pushd ${GIT_POD_ROOT}
git config --global --add safe.directory ${GIT_POD_ROOT}
rm -f /usr/local/lib/skyramp/idl/grpc/skyramp*.*
rm -rf /etc/skyramp/runtime/*
cp ${GIT_POD_ROOT}/scripts/skyramp-init.py /
ln -s ${GIT_POD_ROOT}/web/templates /home/workspace/skyramp/tmpl
go run ./cmd/airgap
go mod download
EOF
  popd
}

# Define two parallel arrays
descriptions=(
    "2.0 Docker compose up"
    "2.2 Docker compose down"
    "2.1 Debug worker in compose"
    "1.1 Create kind cluster"
    "1.2 Build devcontainer"
    "1.3 Deploy devcontainer to kind cluster"
    "1.4 Debug worker in k8s"
)

actions=(
    "compose_up_debug_worker"
    "compose_down_debug_worker"
    "debug_compose_worker"
    "create_cluster"
    "build_devcontainer"
    "deploy_worker"
    "debug_kind_worker"
)

# Use fzf to select a description
selected_index=$(printf "%s\n" "${descriptions[@]}" | fzf --no-sort)

# Find the index of the selected description
for i in "${!descriptions[@]}"; do
    if [[ "${descriptions[$i]}" = "$selected_index" ]]; then
        selected_action=${actions[$i]}
        break
    fi
done

# Call the selected action if it was selected
if [ -n "$selected_action" ]; then
    $selected_action
else
    echo "No action selected."
fi


