#!/bin/bash
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

DATE=$(date '+%Y-%b-%d_%Hh%Mm%Ss')

echo "Starting NAS test /root/NAS_parallel_benchmark-test/reproduce.sh > tmp/${DATE}_NAS.log" | tee /dev/kmsg
(cd /root/NAS_parallel_benchmark-test ; ./reproduce.sh ) > /tmp/${DATE}_NAS.log &

PID=$!

sleep 10
echo "Loading module sched_profiler.ko" | tee /dev/kmsg
insmod sched_profiler.ko


echo "Waiting for the NAS test to finish" | tee /dev/kmsg
wait $PID
sleep 1
echo "NAS test has finished, dumping scheduler events to /tmp/${DATE}_sched_profiler.xz" | tee /dev/kmsg

#stdbuf -oL -eL cat /proc/sched_profiler > /tmp/${DATE}_sched_profiler
cat /proc/sched_profiler | xz --threads=0 > /tmp/${DATE}_sched_profiler.xz

sleep 1
echo "Removing module sched_profiler.ko" | tee /dev/kmsg
rmmod sched_profiler.ko

