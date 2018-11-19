#!/bin/bash

DATA_DIR=${1:-.}

pushd $DATA_DIR > /dev/null

COUNT=`ls fc-sb* | sort -V | tail -1 | cut -d '-' -f 2 | cut -f 2 -d 'b'`

for i in `seq 0 $COUNT`
do
  setup_time=`grep Bash bashlog-fc-sb${i} | cut -d ' ' -f 4`
  curl_time=`grep Curl bashlog-fc-sb${i} | cut -d ' ' -f 3`
  boot_time=`grep Guest-boot fc-sb${i}-log | cut -f 2 -d '=' | cut -f 4 -d ' '`
  total=$(($setup_time + $curl_time + $boot_time))
  echo "$i setup $setup_time curl $curl_time boot $boot_time total $total ms"
done

popd > /dev/null

