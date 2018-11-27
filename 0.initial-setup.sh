#!/bin/bash

COUNT="${1:-4000}" # Default to 4000

RES=scripts

rm -rf output
mkdir output
chown -R ec2-user:ec2-user output

pushd $RES > /dev/null

./one-time-setup.sh
./setup-network-taps.sh 0 $COUNT 100

popd > /dev/null
