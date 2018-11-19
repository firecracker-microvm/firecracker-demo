#!/bin/bash

COUNT="${1:-1}"

let total=0

for i in `seq 1 $COUNT`
do
  LOG="output/fc-sb0-log"
  rm -f $LOG
  ./start-firecracker.sh
  until grep Overall $LOG 2>&1 > /dev/null
  do
    true
  done
  time=$(grep Overall $LOG | cut -f 2 -d '=' | tr -d ' ')
  echo "boot #$i took $time us $(($time/1000)) ms"
  let total=$total+$time
  killall firecracker
done

echo "Mean average is $(($total / $COUNT)) us"

