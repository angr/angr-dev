#!/usr/bin/env bash
set -e

# on github
GITHUB_REPOS="
angr/claripy
angr/tracer
angr/simuvex
angr/pyvex
angr/angr-management
angr/angr-dev
angr/angr-doc
angr/vex
angr/angr
angr/binaries
angr/archinfo
angr/angr.github.io
angr/cle
angr/wheels
angr/fidget
angr/patcherex
shellphish/driller
shellphish/fuzzer
shellphish/rex
shellphish/shellphish-qemu
shellphish/shellphish-afl
shellphish/driller-afl
shellphish/afl-other-arch
mechaphish/colorguard
mechaphish/meister
mechaphish/cgrex
mechaphish/compilerex
mechaphish/network_dude
mechaphish/scriba
mechaphish/povism
mechaphish/path_performance
mechaphish/common-utils
mechaphish/ambassador
mechaphish/vm-workers
mechaphish/network_poll_creator
mechaphish/worker
mechaphish/multiafl
mechaphish/simulator
mechaphish/farnsworth
mechaphish/pov_fuzzing
mechaphish/qemu-cgc
salls/angrop
zardus/mulpyplexer
zardus/cooldict
"

GITLAB_REPOS="
angr/claripy
cgc/tracer
angr/simuvex
angr/pyvex
angr/angr-management
angr/angr-dev
angr/angr-doc
angr/vex
angr/angr
angr/binaries
angr/archinfo
angr/cle
angr/wheels
angr/fidget
cgc/driller
cgc/fuzzer
cgc/rex
cgc/patcherex
cgc/shellphish-qemu
cgc/shellphish-afl
cgc/driller-afl
cgc/afl-other-arch
cgc/colorguard
cgc/meister
cgc/cgrex
cgc/compilerex
cgc/network_dude
cgc/scriba
cgc/povism
cgc/path_performance
cgc/common-utils
cgc/ambassador
cgc/vm-workers
cgc/network_poll_creator
cgc/worker
cgc/multiafl
cgc/simulator
cgc/farnsworth
cgc/pov_fuzzing
cgc/qemu-cgc
angr/angrop
"

function add_remotes
{
	name=$1
	base_url=$2
	repos=$3

	for repo in $repos
	do
		dir=$(basename $repo)
		if [ ! -e $dir ]
		then
			echo "### DOES NOT EXIST: $repo"
			continue
		fi

		git -C $dir remote | grep -q $name && echo "### ALREADY DONE: $repo" && continue

		echo "### DOING: $repo"
		git -C $dir remote add $name $base_url$repo
		git -C $dir fetch $name >/dev/null
	done
}

add_remotes github git@github.com: "$GITHUB_REPOS"
add_remotes gitlab git@git.seclab.cs.ucsb.edu: "$GITLAB_REPOS"

for REPO in */.git
do
	REPO=$(dirname $REPO)
	git -C $REPO remote | grep -q both && echo "### BOTH ALREADY DONE: $REPO" && continue
	GITHUB_URL=$(git -C $REPO remote get-url github 2>/dev/null) || continue
	GITLAB_URL=$(git -C $REPO remote get-url gitlab 2>/dev/null) || continue
	git -C $REPO remote add both $GITHUB_URL
	git -C $REPO remote set-url --add --push both $GITHUB_URL
	git -C $REPO remote set-url --add --push both $GITLAB_URL
done
