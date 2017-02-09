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

    if "\n0 statements analysed." in pylint_out:
        return [ ], 10.00

    if "Report" not in pylint_out:
        return [ "LINT FAILURE: syntax error in file?" ], 0

    out_lines = pylint_out.split('\n')
    errors = out_lines[1:out_lines.index('Report')-2]
    score = float(out_lines[-3].split("/")[0].split(" ")[-1])
    l.info("File %s has score %.2f", filename, score)
    return errors, score

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

    new_results = lint_files(tolint)
    subprocess.check_call("git checkout origin/master".split())
    try:
        old_results = lint_files(tolint)
    finally:
        subprocess.check_call("git checkout @{-1}".split())

    print ""
    print "###"
    print "### LINT REPORT FOR %s" % repo_name
    print "###"
    print ""

    regressions = [ ]
    for v in new_results:
        new_errors, new_score = new_results[v]
        if v not in old_results:
            if new_score != 10.00:
                print "LINT FAILURE: new file %s lints at %.2f/10.00. Errors:" % (v, new_score)
                print "... " + "\n... ".join(new_errors)
                regressions.append((v, None, new_score))
            else:
                print "LINT SUCCESS: new file %s is a perfect 10.00!" % v
        else:
            _, old_score = old_results[v]
            if new_score < old_score:
                print "LINT FAILURE: %s regressed to %.2f/%.2f" % (v, new_score, old_score)
                print "... " + "\n... ".join(new_errors)
                regressions.append((v, old_score, new_score))
            elif new_score > old_score:
                print "LINT SUCCESS: %s has improved to %.2f (from %.2f)! " % (v, new_score, old_score)
            else:
                print "LINT SUCCESS: %s has remained at %.2f " % (v, new_score)

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
    pylint_rc = os.path.join(os.path.dirname(os.path.abspath(__file__)), '../pylintrc')
    if not os.path.isfile("tests/lint.py"):
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
