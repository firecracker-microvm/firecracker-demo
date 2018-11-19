#!/bin/bash

#Usage 
## sudo ./parallel-start-many.sh 0 100 5 # Will start VM#0 to VM#99 5 at a time. 

start="${1:-0}"
upperlim="${2:-1}"
parallel="${3:-1}"

echo start timestamp: `date +%s%N | cut -b1-13` ms
echo "end timestamps (ms):"
for ((i=0; i<parallel; i++)); do
  s=$((i * upperlim / parallel))
  e=$(((i+1) * upperlim / parallel))
  ./start-many.sh $s $e && date +%s%N | cut -b1-13 &
done

