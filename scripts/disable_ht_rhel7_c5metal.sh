#!/bin/bash
for i in `seq 48 95`;
do
        echo 0 > /sys/devices/system/cpu/cpu$i/online
done    