#!/bin/bash

usage()
{
  echo "usage: `basename $0` <time in seconds>"
  echo "       time in seconds to collect scheduler events"
}

if [ "$#" -ne 1 ]
then
  usage
  exit 1
fi

TIME=$1

if [[ $((TIME)) != $TIME ]]; then
    echo "Expecting integer number but got \"${TIME}\""
    usage
    exit 1
fi

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

DATE=$(date '+%Y-%b-%d_%Hh%Mm%Ss')

echo "Loading module sched_profiler.ko" | tee /dev/kmsg
if ! insmod sched_profiler.ko ; then
  echo "insmod sched_profiler.ko has failed."
  exit 1
fi

echo "Sleeping for $TIME seconds"
sleep $TIME

echo "Dumping scheduler events to /tmp/${DATE}_sched_profiler.xz" | tee /dev/kmsg

#time stdbuf -oL -eL cat /proc/sched_profiler > /tmp/${DATE}_sched_profiler
time cat /proc/sched_profiler | xz --threads=0 > /tmp/${DATE}_sched_profiler.xz

sleep 1
echo "Removing module sched_profiler.ko" | tee /dev/kmsg
rmmod sched_profiler.ko

pushd ../plots
rm -rf output/*png

echo "Creating plots ./generate_rows_sched_profiler.sh /tmp/${DATE}_sched_profiler.xz"
./generate_rows_sched_profiler.sh /tmp/${DATE}_sched_profiler.xz

popd
echo "Output is here ../plots/output"

