#!/usr/bin/env python

import os
import sys
import subprocess

import urlparse
import pygithub3

try:
    import angr
    angr_dir = os.path.realpath(os.path.join(os.path.dirname(angr.__file__), '../..'))
except ImportError:
    print 'Please run this script in the angr virtualenv!'
    sys.exit(1)

def main(branch_name=None):
    print 'Enter the urls of the pull requests, separated by newlines. EOF to finish:'
    urls = sys.stdin.read().strip().split('\n')

    if len(urls) == 0:
        sys.exit(0)

    prs = []
    gh = pygithub3.Github()

    for url in urls:
        try:
            path = urlparse.urlparse(url).path
            pathkeys = path.split('/')
            prs.append(gh.pull_requests.get(int(pathkeys[4]), pathkeys[1], pathkeys[2]))
            assert pathkeys[3] == 'pull'
        except Exception: # pylint: disable=broad-except
            print url, 'is not a github pull request url'
            import ipdb; ipdb.set_trace()
            sys.exit(1)

    if branch_name is None:
        branch_name = 'pr/' + prs[0].head['label'].replace(':','/')

    for pr in prs:
        repo_path = os.path.join(angr_dir, pr.base['repo']['name'])
        print '\x1b[32;1m$', 'git', 'checkout', '-B', branch_name, 'master', '\x1b[0m'
        subprocess.call(['git', 'checkout', '-B', branch_name, 'master'], cwd=repo_path)
        print '\x1b[32;1m$', 'git', 'pull', pr.head['repo']['git_url'], pr.head['ref'], '\x1b[0m'
        subprocess.call(['git', 'pull', pr.head['repo']['git_url'], pr.head['ref']], cwd=repo_path)
        print '\x1b[32;1m$', 'git', 'push', '-f', '-u', 'origin', branch_name, '\x1b[0m'
        subprocess.call(['git', 'push', '-f', '-u', 'origin', branch_name], cwd=repo_path)

if __name__ == '__main__':
    if len(sys.argv) > 1:
        main(sys.argv[1])
    else:
        main()
