#!/bin/bash

#DATA_DIR=${1:-.}
DATA_DIR="output"
DEST="$PWD/data.log"

rm -f $DEST

pushd $DATA_DIR > /dev/null

COUNT=`ls fc-sb* | sort -V | tail -1 | cut -d '-' -f 2 | cut -f 2 -d 'b'`

for i in `seq 0 $COUNT`
do
  boot_time=`grep Guest-boot fc-sb${i}-log | cut -f 2 -d '=' | cut -f 4 -d ' '`
  echo "$i boot $boot_time ms" >> $DEST
done

popd > /dev/null

