#!/bin/bash
ASE="$1"
DBNAME="$2"

s+ --server=${ASE} <<EOF
select @@servername ;
use $DBNAME ;
sp__dbspace ;
EOF

exit 0
