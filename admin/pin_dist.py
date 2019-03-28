#!/usr/bin/env python3

version = '8.1.0'

github_repos = [
    # NOTE this will need a refactor of some sort if we add packages that have different package names than repo names, e.g. bc dashes/underscores differences
    'angr/angr',
    'angr/pyvex',
    'angr/claripy',
    'angr/cle',
    'angr/archinfo',
    'angr/ailment'
]

from git import Repo
import os

location = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')

install_requires = []

for github_name in github_repos:
    namespace, repo_name = github_name.split('/')
    path = os.path.join(location, repo_name)
    repo = Repo(path, search_parent_directories=False)
    commit = repo.commit()
    install_requires.append('%s @ git+https://github.com/%s/%s@%s#egg=%s' % (repo_name, namespace, repo_name, commit, repo_name))

script = f"""\
#!/usr/bin/env python3
from setuptools import setup

install_requires = {install_requires}

setup(name='angr-dev',
      version='{version}',
      description='meta-package for development against angr',
      author='angr team',
      author_email='angr@lists.cs.ucsb.edu',
      maintainer='rhelmot',
      maintainer_email='audrey@rhelmot.io',
      install_requires=install_requires
)
"""

with open('setup.py', 'w') as fp:
    fp.write(script)
os.system('python setup.py sdist')
