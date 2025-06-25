#!/bin/bash
ASE="$1"
LIST="$2"

while read filename
do
   echo $filename
   ./install_proc_by_ASE_FILENAME.bash $ASE $filename
done < "$LIST"

echo ""
echo "list $LIST of files was installed on $ASE"

exit 0
