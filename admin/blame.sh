#!/usr/bin/env bash

function blame()
{
	PROJ=$1
	cd $PROJ
	for f in $(find . -iname "*.py") $(find . -iname "*.c*") $(find . -iname *.h) $(find . -iname "*.js") $(find . -iname "*.html")
	do
		git blame -w $f 2>/dev/null | cat | sed -e "s/[^(]*(//" | sed -e "s/ .*//" | sed -e "s/Andrew/Audrey/"
	done
	cd - > /dev/null
}

for i in "$@"
do
	blame $i
done | sort | uniq -c | sort -n
