#!/bin/bash
ASE="$1"
FILE="$2"

s+ --server=${ASE} --ifile=${FILE}

exit 0
