# Vscode Configuration files

This repo holds vscode configuration files, and utilities for working with the skyramp codebase.

Prerequirements
### fzf
```
brew install fzf
```

### utilities
Pull/push configuration to skyramp directory
```
vsconf.sh pull|push
```

### utility functions
```
./.vscode/scripts/run-action.sh
```
- "Build all"
- "Build library (make release-so)"
- "Build python package"
- "Build npm package"
- "Recreate cluster"
- "Execute run_all"
- "Remove cluster"
- "Configure current npm project for debugging"
- "Configure current pip project for debugging"
- "List images in k8s cluster"
- "Load worker image to k8s cluster"
- "Debug (up) worker in compose"
- "Debug (down) worker in compose"


## Debugging Python and Node Modules

To debug the Python and Node modules of the Skyramp library, you need access to the Python sources in the Git repository. The workflow involves uninstalling the bundled Skyramp library and linking the Skyramp module with the working tree of Skyramp as follows:

### Python
```bash
export SKYRAMPDIR=$(HOME)/git/letsramp/skyramp
export PYTHONPATH=$SKYRAMPDIR/libs/pip
pip uninstall skyramp
cd $SKYRAMPDIR/libs/test/pip
```

### Node
```bash
export SKYRAMPDIR=$(HOME)/git/letsramp/skyramp
npm uninstall @skyramp/skyramp
cd $SKYRAMPDIR/libs/npm
sudo npm link 
cd $SKYRAMPDIR/libs/test/npm
npm link @skyramp/skyramp
```
