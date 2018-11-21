#!/bin/bash

start="${1:-0}"
upperlim="${2:-1}"
parallel="${3:-1}"

for ((i=0; i<parallel; i++)); do
  s=$((i * upperlim / parallel))
  e=$(((i+1) * upperlim / parallel))
  for ((j=s; j<e; j++)); do
    ./setup-tap-with-id.sh $j
  done &
done

