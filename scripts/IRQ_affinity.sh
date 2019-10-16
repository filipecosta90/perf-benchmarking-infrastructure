#!/bin/sh

# Copyright (c) 2019 Redis Labs Ltd.c
# 
# Sets the IRQ affinity, one per core and disables RPS for that RXTX queue
# Parameter 1: network interface ( example eth0 )
# Parameter 2: starting-ending cores ( example 5-17,41-53 )
# Parameter 3: CPU mask in hexadecimal ( set to 0 to disable )

function disable_rps_rx_tx_affinity()
{
    # RPS is configured per network device and receive queue
    # when setting rps_cpus this disables RPS, so the CPU that handles the network interrupt also processes the packet.
    echo $MASK > /sys/class/net/$IFACE/queues/rx-$RXTX/rps_cpus
	echo "SET affinity of rx-$RXTX to $MASK"
}


function irqbalance_stop() 
{
# check for irqbalance running
IRQBALANCE_ON=`ps ax | grep -v grep | grep -q irqbalance; echo $?`
if [ "$IRQBALANCE_ON" == "0" ] ; then
	echo " WARNING: irqbalance is running and will"
	echo "          likely override this script's affinitization."
	echo "          Stoping the irqbalance service and/or execute"
	killall irqbalance
fi
}

total_cores=$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l)
IFACE=$1
irq_threads=$(grep $IFACE /proc/interrupts | awk -F: '{print $1}')

RXTX=0
CORE_INTERVAL=$2
MASK=$3

irqbalance_stop

for IRQ in $irq_threads
do 

    echo "setting IRQ $IRQ affinity to $CORE_INTERVAL"
	sudo sh -c "echo $CORE_INTERVAL > /proc/irq/$IRQ/smp_affinity_list"
    disable_rps_rx_tx_affinity
    RXTX=$(expr $RXTX + 1)
    
done