# angr-dev

This is a repository to make installing a development version of angr easier.

## Install

To set up angr for development, do:

```bash
sudo apt-get install virtualenvwrapper python2.7-dev build-essential libxml2-dev libxslt1-dev git libffi-dev
mkvirtualenv angr
./setup.sh
```

This will grab and install angr.

## Updating

To update angr, simply pull all the git repositories.

```bash
./git_all pull
```

For repositories that have C components (pyvex), you might have to rebuild.

```bash
pip install -I -e pyvex
```
