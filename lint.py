#!/usr/bin/env python

import os
import sys
import logging
import subprocess

logging.basicConfig()
l = logging.getLogger("lint")
#l.setLevel(logging.DEBUG)

def lint_file(filename, pylint_rc):
    l.debug("Linting file %s", filename)
    try:
        pylint_out = subprocess.check_output([ "pylint", "--rcfile=%s" % pylint_rc, filename ])
    except subprocess.CalledProcessError as e:
        if e.returncode == 32:
            print "LINT FAILRE: pylint failed to run on %s" % filename
            pylint_out = "-1337/10"
        else:
            pylint_out = e.output

    score = float(pylint_out.split('\n')[-3].split("/")[0].split(" ")[-1])
    l.info("File %s has score %.2f", filename, score)
    return score

def lint_repo(pylint_rc):
    lint_scores = { }

    changed_files = [
        o.split()[-1] for o in
        subprocess.check_output("git diff --name-status origin/master".split()).split("\n")[:-1]
    ]
    tolint = [ f for f in changed_files if f.endswith(".py") ]

    print "Changed files: %s" % (tolint,)

    for f in tolint:
        lint_scores[f] = lint_file(f, pylint_rc)

    return lint_scores

def compare_lint(dirname):
    pylint_rc = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'pylintrc')
    os.chdir(dirname)
    new_scores = lint_repo(pylint_rc)
    subprocess.check_call("git checkout origin/master".split())
    old_scores = lint_repo(pylint_rc)
    subprocess.check_call("git checkout @{-1}".split())

    print ""
    print "#############################################"
    print "###              LINT REPORT              ###"
    print "#############################################"
    print ""

    regressions = [ ]
    for v in new_scores:
        if v not in old_scores:
            if new_scores[v] != 10.00:
                print "LINT FAILURE: new file %s lints at %.2f/10.00" % (v, new_scores[v])
                regressions.append((v, None, new_scores[v]))
            else:
                print "LINT SUCCESS: %s is a perfect 10.00!" % v
        elif v in old_scores:
            if new_scores[v] < old_scores[v]:
                print "LINT FAILURE: %s regressed to %.2f/%.2f" % (v, new_scores[v], old_scores[v])
                regressions.append((v, old_scores[v], new_scores[v]))
            elif new_scores[v] > old_scores[v]:
                print "LINT SUCCESS: %s has improved to %.2f (from %.2f)! " % (v, new_scores[v], old_scores[v])
            else:
                print "LINT SUCCESS: %s has remained at %.2f " % (v, new_scores[v])

    return len(regressions) == 0

if __name__ == '__main__':
    sys.exit(0 if compare_lint(sys.argv[1]) else 1)
