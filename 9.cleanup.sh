#!/bin/bash

COUNT=`ls /sys/class/net/ | wc -l`

killall iperf3
killall firecracker

for ((i=0; i<COUNT; i++))
do
  ip link del fc-$i-tap0 2> /dev/null &
done

rm -rf output/*
rm -rf /tmp/firecracker-sb*
