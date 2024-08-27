#! /bin/bash
set -e

# Get the directory of the script (works on macOS and other Unix-like systems)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "SCRIPT_DIR: $SCRIPT_DIR"

if ! command -v fzf &> /dev/null; then
    echo "fzf is not installed."
    echo "You can install fzf on Linux using:"
    echo "  sudo apt-get install fzf    # Debian/Ubuntu"
    echo "  sudo yum install fzf        # CentOS/RHEL"
    echo "  sudo pacman -S fzf          # Arch Linux"
    echo "  brew install fzf            # macOS"
fi


# Environment setup
: ${SKYRAMPDIR:=$HOME/git/letsramp/skyramp}
: ${SAMPLE:=$SKYRAMPDIR/skyramp}
: ${SKYRAMP:=$SKYRAMPDIR/bin/skyramp}
cluster_name=$($SKYRAMP cluster list | grep context | awk '{ print $3 }' | sed 's/^kind-//')

function list_cluster_images {
    docker exec -it $cluster_name-control-plane crictl images
}

function load_worker_image_to_cluster {
    worker_url=$($SKYRAMP version | grep "Worker Repo" | awk '{print $4}')
    worker_tag=$($SKYRAMP version | grep "Worker Tag" | awk '{print $4}')
    kind load docker-image $worker_url:$worker_tag --name $cluster_name
}

# launch compose with worker in debug dev container
function compose_up_debug_worker {
    compose_dir=$SCRIPT_DIR/../dockerfiles/worker-debug
    pushd $compose_dir
    docker compose up -d --wait
    docker compose exec -it worker /scripts/run-once.sh 
    echo "Debug worker started on http://localhost:6001/?folder=/home/workspace/skyramp"
    popd
}

function compose_down_debug_worker {
    compose_dir=$SCRIPT_DIR/../dockerfiles/worker-debug
    pushd $compose_dir
    docker compose down 
    popd
}

function docker_clean {
    docker ps | grep worker | awk '{print $1}' | xargs -I{} docker rm {} --force
    docker ps | grep public.ecr | awk '{print $1}' | xargs -I{} docker rm {} --force
    docker ps | grep dockerfiles | awk '{print $1}' | xargs -I{} docker rm {} --force
}

function build_so {
    pushd $SKYRAMPDIR
    make release-so
    popd
}

function build_pip {
    pushd $SKYRAMPDIR
    rm -rf $SKYRAMPDIR/venv || true
    python3 -m venv venv
    source $SKYRAMPDIR/venv/bin/activate
    pip install pytest
    # Use PYTHONPATH to import the skyramp module
    # pushd libs/pip
    # python3 -m pip install --upgrade pip
    # python3 -m pip install --upgrade build
    # python3 -m build
    # pip install dist/*.tar.gz
    # popd
    popd
}

function build_npm {
    pushd $SKYRAMPDIR/libs/npm
    npm pack
    popd
}

function make_all {
    pushd $SKYRAMPDIR
    make all
    popd
}

function build_all {
    echo "build cli, worker, release-so, venv, npm..."
    make all
    make build-worker
    build_so
    build_pip
    build_npm
}

# configure python for debugging 
# 1. build the pip package
# 2. uninstall skyramp if it is installed
# 3. export PYTHONPATH to the pip package
function configure_python_for_debugging {
    build_pip
    if pip show skyramp > /dev/null 2>&1; then
        echo "Uninstalling skyramp..."
        pip uninstall -y skyramp
    fi
    export PYTHONPATH=$SKYRAMPDIR/libs/pip
}

# In order to debug the npm module with the working code, we need to:
# 1. link the npm module @skyramp/skyramp to the global npm
# 2. link the npm module @skyramp/skyramp to the current project
function configure_npm_for_debugging {
    if ! npm list -g @skyramp/skyramp > /dev/null 2>&1; then
        echo "linking npm module @skyramp/skyramp"
        pushd $SKYRAMPDIR/libs/npm
        sudo npm link
        popd
    fi
    # Check if package.json exists, if not create it
    if [ ! -f package.json ]; then
        npm init -y
    fi

    # Check if @skyramp/skyramp is installed and uninstall if it is
    if npm list @skyramp/skyramp > /dev/null 2>&1; then
        echo "Uninstalling @skyramp/skyramp..."
        npm uninstall @skyramp/skyramp
    fi

    # link @skyramp/skyramp to the current project
    npm link @skyramp/skyramp
}

function build_all_and_run_all_test {
    pushd $SKYRAMPDIR
    rm -rf mocker_test || true
    git clean -fd examples/v1
    build_all
    ./scripts/v1/run_all.sh
    popd
}

function remove_cluster {
    pushd $SKYRAMPDIR
    $SKYRAMP cluster remove -l || true
    popd
}

function recreate_cluster {
    pushd $SKYRAMPDIR
    $SKYRAMP cluster remove -l || true
    $SKYRAMP cluster create -l
    cp ~/.skyramp/kind-cluster.kubeconfig ~/.kube/config
    popd
}

# Define two parallel arrays
descriptions=(
    "make all"
    "Build all"
    "Build library (make release-so)"
    "Recreate cluster"
    "Execute run_all"
    "Remove cluster"
    "Configure current npm project for debugging"
    "Configure current pip project for debugging"
    "List images in k8s cluster"
    "Load worker image to k8s cluster"
    "Debug (up) worker in compose"
    "Debug (down) worker in compose"
)

actions=(
    "make_all"
    "build_all"
    "build_so"
    "recreate_cluster"
    "build_all_and_run_all_test"
    "remove_cluster"
    "configure_npm_for_debugging"
    "configure_python_for_debugging"
    "list_cluster_images"
    "load_worker_image_to_cluster"
    "compose_up_debug_worker"
    "compose_down_debug_worker"
)

# Use fzf to select a description
selected_index=$(printf "%s\n" "${descriptions[@]}" | fzf)

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

echo "DONE"
