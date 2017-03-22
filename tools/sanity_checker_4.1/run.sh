#!/bin/bash
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

DATE=$(date '+%Y-%b-%d_%Hh%Mm%Ss')

echo "Starting NAS test /root/NAS_parallel_benchmark-test/reproduce.sh > tmp/${DATE}_NAS.log" | tee /dev/kmsg
(cd /root/NAS_parallel_benchmark-test ; ./reproduce.sh ) > /tmp/${DATE}_NAS.log &

PID=$!

sleep 1

echo "Starting dmesg monitoring. Log is /tmp/${DATE}_invariant.log"
# See also dmesg -wH
tail -f /var/log/messages | grep -i invariant > /tmp/${DATE}_invariant.log &
TAIL_PID=$!

echo "Loading module stap_monitor.ko" | tee /dev/kmsg
insmod stap_monitor.ko


echo "Waiting for the NAS test to finish" | tee /dev/kmsg
wait $PID
sleep 1
echo "NAS test has finished" | tee /dev/kmsg

sleep 1

echo "Stopping dmesg monitoring. Log is /tmp/${DATE}_invariant.log"
kill $TAIL_PID

echo "Removing module stap_monitor.ko" | tee /dev/kmsg
rmmod stap_monitor.ko

echo "========================Recorded events=============================="
cat /tmp/${DATE}_invariant.log
echo "====================================================================="
