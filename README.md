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

### Windows
If you are working with Windows, download the setup.ps1 file.

Move the setup.ps1 file to your path for your python virtual environment inside of Scripts.

Open the setup.ps1 file in Visual Code and run a virtual environment pre-created in the terminal by using: 
```ShellSession
(virtualEnvNameHere)/Scripts/Activate.ps1
```

Run the setup.ps1 file in the terminal in Visual Code. All files and dependencies will be installed after running.
```ShellSession
(virtualEnvNameHere)/Scripts/setup.ps1
```

### MacOS

Mojave seems to be working with the current version, so this fixing might not be necessary. Will need to verify.

If you are working on macOS, you have to run the fix_macOS.sh script while in your virtualenv to fix the native libraries in angr. This is necessary, since macOS introduced restrictions for relative paths in dynamic libraries.
```bash
./fix_macOS.sh
```

## Install (docker)

Alternatively, you can use the dockerfile:

```ShellSession
$ docker build -t angr angr-dev
$ docker run -it angr
```

## Updating

To update angr, simply pull all the git repositories.

```bash
./git_all.sh pull
```

For repositories that have C components, you might have to rebuild.

```bash
pip install -e ./pyvex && pip install -e ./angr
```

## Issues

### I want to use my github username and password via https

Comment out the `GIT_ASKPASS=true` line. Or, just use ssh.
