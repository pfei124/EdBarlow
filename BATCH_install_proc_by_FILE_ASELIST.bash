#!/bin/bash
FILENAME="$1"
ASELIST="$2"

while read ase
do
   echo "installing $FILENAME on $ase"
   ./install_proc_by_ASE_FILENAME.bash $ase $FILENAME
done < "$ASELIST"

echo "file $FILENAME was installed on ASE's in list $ASELIST"

exit 0
