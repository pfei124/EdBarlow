#!/bin/bash

ASE="${SRV_SID}"
DB="sybsystemprocs"

echo "Please enter the sa-password for ASE $ASE : "
read PASSWORD

isql -Usa -P"${PASSWORD}" -S $ASE -Dsybsystemprocs <<EOF
quit
EOF

if [[ $? -ne 0 ]]; then
  echo ""
  echo "password does not work!!"
  echo "Aborting!"
  exit 1
fi

echo ""
echo "You are about to install the EdBarlow procedures on ASE $ASE"
echo "Do you want to continue (y/n): "
read ANSWER

if [[ $ANSWER != "y"  ]];
then
   echo ""
   echo "you did not answer in the affirmative!!"
   echo "Aborting!"
   exit 2
fi

LIST="configure_wp.list"
while read filename
do
  echo "installing $filename"
  isql -Usa -P"${PASSWORD}" -S${ASE} -Dsybsystemprocs -i $filename
  if [[ $? -ne 0 ]];
  then
    echo ""
    echo "there was a problem!!"
    echo "Aborting!"
    exit 3
  fi
done < "$LIST"

echo ""
echo "Exiting."
exit 0
