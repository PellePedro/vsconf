#! /bin/bash
set -e

# This script is used to sync the VSCode configurations between 
# a target repo and vscode configuration repo.

CONF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
: ${SKYRAMPDIR:=$HOME/git/letsramp/skyramp}

skyramp_repo=$SKYRAMPDIR
config_repo=$CONF_DIR

# Function to print usage
usage() {
  echo "Usage: $0 {pull|push}"
  echo "  pull  - Sync from mono repo to shadow directory"
  echo "  push  - Sync from shadow directory to mono repo"
  exit 1
}

# Check if exactly one argument is provided
if [ "$#" -ne 1 ]; then
  usage
fi

# Perform the requested operation
case "$1" in
  pull)
    echo "Pulling VSCode configurations from mono repo to shadow directory..."
    rsync -avm --include='*/' --include='.vscode/***' --exclude='*' "$skyramp_repo/" "$config_repo/"
    echo "Pull complete."
    ;;
  push)
    echo "Pushing VSCode configurations from shadow directory to mono repo..."
    rsync -avm --include='*/' --include='.vscode/***' --exclude='*' "$config_repo/" "$skyramp_repo/"
    echo "Push complete."
    ;;
  *)
    usage
    ;;
esac

