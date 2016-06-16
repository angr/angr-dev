#!/usr/bin/env python

import os
import sys
import logging
import subprocess

logging.basicConfig()
l = logging.getLogger("lint")
#l.setLevel(logging.DEBUG)

def lint_file(filename):
    l.debug("Linting file %s", filename)
    try:
        cmd = [
            "pylint",
            "--rcfile=%s" % pylint_rc,
            os.path.abspath(filename)
        ]
        pylint_out = subprocess.check_output(cmd)
    except subprocess.CalledProcessError as e:
        if e.returncode == 32:
            print "LINT FAILRE: pylint failed to run on %s" % filename
            pylint_out = "-1337/10"
        else:
            pylint_out = e.output

    score = float(pylint_out.split('\n')[-3].split("/")[0].split(" ")[-1])
    l.info("File %s has score %.2f", filename, score)
    return score

def lint_files(tolint):
    return { f: lint_file(f) for f in tolint if os.path.isfile(f) }

def compare_lint():
    repo_dir = subprocess.check_output("git rev-parse --show-toplevel".split()).strip()
    repo_name = os.path.basename(repo_dir)

    os.chdir(repo_dir)
    cur_branch = subprocess.check_output("git rev-parse --abbrev-ref HEAD".split()).strip()
    if cur_branch == "master":
        print "### Aborting linting for %s because it is on master." % repo_name
        return True

    # get the files to lint
    changed_files = [
        o.split()[-1] for o in
        subprocess.check_output("git diff --name-status origin/master".split()).split("\n")[:-1]
    ]
    tolint = [ f for f in changed_files if f.endswith(".py") ]
    print "Changed files: %s" % (tolint,)

    new_scores = lint_files(tolint)
    subprocess.check_call("git checkout origin/master".split())
    try:
        old_scores = lint_files(tolint)
    finally:
        subprocess.check_call("git checkout @{-1}".split())

    print ""
    print "###"
    print "### LINT REPORT FOR %s" % repo_name
    print "###"
    print ""

    regressions = [ ]
    for v in new_scores:
        if v not in old_scores:
            if new_scores[v] != 10.00:
                print "LINT FAILURE: new file %s lints at %.2f/10.00" % (v, new_scores[v])
                regressions.append((v, None, new_scores[v]))
            else:
                print "LINT SUCCESS: new file %s is a perfect 10.00!" % v
        elif v in old_scores:
            if new_scores[v] < old_scores[v]:
                print "LINT FAILURE: %s regressed to %.2f/%.2f" % (v, new_scores[v], old_scores[v])
                regressions.append((v, old_scores[v], new_scores[v]))
            elif new_scores[v] > old_scores[v]:
                print "LINT SUCCESS: %s has improved to %.2f (from %.2f)! " % (v, new_scores[v], old_scores[v])
            else:
                print "LINT SUCCESS: %s has remained at %.2f " % (v, new_scores[v])

    print ""
    print "###"
    print "### END LINT REPORT FOR %s" % repo_name
    print "###"
    print ""

    return len(regressions) == 0

def do_in(directory, function, *args, **kwargs):
    cur_dir = os.path.abspath(os.getcwd())
    try:
        os.chdir(directory)
        return function(*args, **kwargs)
    finally:
        os.chdir(cur_dir)

if __name__ == '__main__':
    pylint_rc = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'pylintrc')
    if not os.path.isfile("lint.py"):
        # lint the cwd
        sys.exit(0 if compare_lint() else 1)
    elif len(sys.argv) == 1:
        # lint all
        sys.exit(0 if all(do_in(r, compare_lint) for r in [
            i for i in os.listdir(".") if os.path.isdir(os.path.join(i, ".git"))
        ]) else 1)
    else:
        # lint several
        sys.exit(0 if all(do_in(r, compare_lint) for r in sys.argv[1:]) else 1)
