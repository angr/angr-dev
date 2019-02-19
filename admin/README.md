
## Creating a virtual environment for angr release

```
mkvirtualenv angr-release
pip install -U pip setuptools
pip install twine sphinx sphinx_rtd_theme recommonmark
```

## Releasing to PyPI/TestPyPI

- Make sure you are in a virtual environment with angr installed.

- Suppose the root directory of your angr release workspace is `~/angr-release`.
Make sure the following repos exist:

```
ailment, angr, angr-dev, angr-doc, angr.github.io, angr-management, angrop, archinfo, binaries, claripy, cle, pyvex, vex
```

- Make sure `git_all.sh` is at `~/angr-release`.

- Use `git_all.sh` to make sure all repositories are up-to-date.

- Release to TestPyPI first.

```
./angr-dev/admin/releaser.sh release yes
```

- We may then create a new virtual environment `angr-release-test` and try pip installing angr from TestPyPI.

```
mkvirtualenv angr-release-test
pip install -U pip setuptools
pip install --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple angr
```

- After everything is tested, now you can release to PyPI.

```
./angr-dev/admin/releaser.sh release
```

