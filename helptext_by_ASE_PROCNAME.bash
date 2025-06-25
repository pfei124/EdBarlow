#!/bin/bash
ASE="$1"
PROCNAME="$2"

s+ --server=${ASE} <<EOF
select @@servername ;
use sybsystemprocs ;
sp__helptext $PROCNAME ;
EOF

exit 0
