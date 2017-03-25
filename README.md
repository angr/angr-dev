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

## Install (docker)

Alternatively, you can use the dockerfile:

```ShellSession
$ docker build -t angr - < angr-dev/Dockerfile
$ docker run -it angr
```

## Updating

To update angr, simply pull all the git repositories.

```bash
./git_all.sh pull
```

For repositories that have C components (pyvex), you might have to rebuild.

```bash
pip install -e ./pyvex && pip install -e ./simuvex
```
