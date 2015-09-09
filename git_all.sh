#!/bin/bash

function green
{
	echo "$(tput setaf 6)$@$(tput sgr0)"
}

function red
{
	echo "$(tput setaf 1)$@$(tput sgr0)"
}

for i in */.git/
do
	i=${i/\/.git\//}
	cd $i
	#green "================================================================================"
	#green "================================================================================"
	green "================================================================================"
	green "=== Running on $i."
	git $@ && green "=== SUCCESS" || red "=== FAILURE"
	cd ..
done
