#!/usr/bin/env python

import glob
import sys
import os
import sh

all_repos = list(map(os.path.dirname, glob.glob("*/.git"))) if 'REPOS' not in os.environ else os.environ['REPOS'].split()
repo_version_commits = { }
repo_timestamp_commits = { }
repo_commit_versions = { }
repo_commit_timestamps = { }
all_version_commits = { }
all_timestamp_commits = { } # might have overwritten commits
all_commit_versions = { }
all_commit_timestamps = { }

def load_commits(repo):
    print("Loading commits for {}...".format(repo))
    version_commits = { }
    timestamp_commits = { }
    commit_versions = { }
    commit_timestamps = { }
    for commit in sh.git('-C', repo, 'log', '--pretty=%H|%ct|%s', _tty_out=False): #pylint:disable=no-member
        commit_hash, timestamp, comment = commit.strip().split('|', 2)
        timestamp = int(timestamp)
        timestamp_commits[timestamp] = commit_hash
        commit_timestamps[commit_hash] = timestamp
        if comment.startswith("ticked version number to"):
            version_commits[comment.split()[-1]] = commit_hash
            commit_versions[commit_hash] = str(comment.split()[-1])
    repo_version_commits[repo] = version_commits
    repo_commit_versions[repo] = commit_versions
    repo_timestamp_commits[repo] = timestamp_commits
    repo_commit_timestamps[repo] = commit_timestamps
    all_version_commits.update(version_commits)
    all_commit_versions.update(commit_versions)
    all_timestamp_commits.update(timestamp_commits)
    all_commit_timestamps.update(commit_timestamps)

def checkout_latest(repo, timestamp):
    try:
        latest_commit = next(
            c
            for t,c in sorted(repo_timestamp_commits[repo].items(), reverse=True)
            if t <= timestamp
        )
    except StopIteration:
        print("Repo %s is too new... No commits found.".format(repo))
        return

    print("Checking out repo {} to commit {}.".format(repo, latest_commit))
    sh.git('-C', repo, 'checkout', latest_commit, _tty_out=False) #pylint:disable=no-member

if __name__ == '__main__':
    for _r in all_repos:
        load_commits(_r)

    if len(sys.argv[1]) == 40:
        # we're synchronizing to a commit
        _timestamp = all_commit_timestamps[sys.argv[1]]
        for _r in list(all_repos):
            checkout_latest(_r, _timestamp)
