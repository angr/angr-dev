#!/bin/bash
path="$1"
find "$path" -name ".pyc"
find "$path" -depth -empty -type d
