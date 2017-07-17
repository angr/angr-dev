#!/bin/bash
path="$1"
find "$path" -name ".pyc" -delete
find "$path" -depth -empty -delete
