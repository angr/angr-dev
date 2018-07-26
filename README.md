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

If you are working on macOS, you have to run the fix_macOS.sh script while in your virtualenv to fix the native libraries in angr. This is necessary, since macOS introduced restrictions for relative paths in dynamic libraries.
```bash
./fix_macOS.sh
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

## Issues

### Git keeps asking me for username and password. Are you trying to steal them from me?

No.
This is because GitHub does not differentiate between "a non-existent repo" and "a private repo" (which they should not), and we cannot correctly handle this in our script right now.

Here are some solutions:

- Pass -n

or

- Check out angr-dev using `git@github.com:angr/angr-dev.git` instead of https.
This requires you to have a GitHub account.

or

- Run the following command instead:
```
setsid sh -c 'tty; ps -jp "$$"; ./angr-dev/setup.sh <your arguments go here>' < /dev/null
```

