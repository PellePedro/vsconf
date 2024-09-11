set -ex

SKYRAMP_DEV_WORKER=skyramp-dev-worker:latest
NS=worker
DEBUG_PORT=8001
CLUSTER_NAME=hostpath
GIT_POD_ROOT=/home/workspace/skyramp

# delete cluster if it exists
if kind get clusters | grep -q "${CLUSTER_NAME}"; then
    echo "Cluster 'hostpath' found. Deleting..."
    kind delete cluster --name hostpath
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

# kubectl taint nodes hostpath-control-plane node-role.kubernetes.io/control-plane:NoSchedule-

# build debug image
pushd ${HOME}/git/letsramp/skyramp/.vscode/dockerfiles/worker-debug
docker compose build
popd

kind load docker-image ${SKYRAMP_DEV_WORKER} --name ${CLUSTER_NAME}

kubectl create ns ${NS}
kubectl apply -k overlay -n ${NS}
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=skyramp-worker,app.kubernetes.io/instance=dev -n ${NS} --timeout=300s

POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=skyramp-worker -n worker -o jsonpath="{.items[0].metadata.name}")
kubectl exec -it $POD_NAME -n worker -- /bin/bash <<EOF
pushd ${GIT_POD_ROOT}
git config --global --add safe.directory ${GIT_POD_ROOT}
rm -f /usr/local/lib/skyramp/idl/grpc/skyramp*.*
rm -rf /etc/skyramp/runtime/*
cp ${GIT_POD_ROOT}/scripts/skyramp-init.py /
ln -s ${GIT_POD_ROOT}/web/templates /home/workspace/tmpl
go run ./cmd/airgap
go mod download
EOF

kubectl port-forward --address 0.0.0.0 deployment/skyramp-worker -n ${NS} ${DEBUG_PORT}:3000


