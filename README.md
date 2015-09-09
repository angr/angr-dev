# angr-dev

This is a repository to make installing a development version of angr easier.

## Install

To set up angr for development, automatically install dependencies, and automatically create a python virtualenv, do:

```bash
./setup.sh -i -e angr
```

This will grab and install angr.
You can launch it with:

```ShellSession
$ workon angr
(angr) $ ipython
[1] import angr
```

## Updating

To update angr, simply pull all the git repositories.

```bash
./git_all pull
```

For repositories that have C components (pyvex), you might have to rebuild.

```bash
pip install -I -e pyvex
```
