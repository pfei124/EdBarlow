#!/bin/bash
ASE="$1"
DBNAME="$2"

s+ --server=${ASE} <<EOF
select @@servername ;
sp__helpdb $DBNAME ;
EOF

exit 0
