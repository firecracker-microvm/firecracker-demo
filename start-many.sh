#!/bin/bash

#Usage 
## sudo ./start.sh 0 100 # Will start VM#0 to VM#99. 

start="${1:-0}"
upperlim="${2:-1}"

for ((i=start; i<upperlim; i++)); do
  ./start-firecracker.sh "$i"
done
