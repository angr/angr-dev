#!/usr/bin/env bash
# This script generates a summary of who has contributed the most lines to the
# projects passed as arguments.

function blame()
{
	PROJ=$1
	cd $PROJ
	for f in $(find . -iname "*.py" -o -iname "*.c*" -o -iname "*.h" -o -iname "*.rs" -a '!' \( -path '*/angr/procedures/definitions/*' -o -path '*/angr/protos/*' \))
	do
		git blame -w $f 2>/dev/null | cat | sed -e "s/[^(]*(//" | sed -e "s/ .*//" | sed -e "s/mborgerson/Matt/g" -e "s/Andrew/Audrey/g"
	done
	cd - > /dev/null
}

for i in "$@"
do
	blame $i
done | sort | uniq -c | sort -n
