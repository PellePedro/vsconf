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

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color (reset)

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

function log_start {
    echo -e "${YELLOW}Starting test: $1${NC}"
}

function log_success {
    echo -e "${GREEN}Test succeeded: $1${NC}"
}

function log_failure {
    echo -e "${RED}Test failed: $1${NC}"
}

source $SKYRAMPDIR/scripts/v1/run_all.sh

actions=(
test_generate_graphql_spacex
test_generate_javascript_crud
test_generate_javascript_grpc
test_generate_using_faker
sample_microservices
helloworld_test  
override_test
echo_test
rafay_test
formdata_test
mongo
mocker_tester_create
docker_compose_test
docker_standalone_test
aws_test
dashboard_reading_worker_data
validation_test
graphql_test
test_generate_using_sample_request  # TODO: fix test failure (step is empty)
crud_negative_test
proxy_rest
mocker_generate
third_party_api_test
)

git clean -fd $SKYRAMPDIR/examples
# selected_index=$(printf "%s\n" "${actions[@]}" | fzf)

LOGFILE="$SKYRAMPDIR/logfile.log"

for action in "${actions[@]}"; do
    # if [ "$action" == "$selected_index" ]; then
        log_start "Running test: $action"

        # Run the action in a subshell and capture the exit status
        if ( $action &>> "$LOGFILE" ); then
            log_success "Test succeeded: $action"
        else
            log_failure "Test failed: $action"
            exit 1  # Stop execution if the action failed
        fi
    # fi
done

