#!/bin/sh

function disable_rps_rx_tx_affinity()
{
    echo 0 > /sys/class/net/$IFACE/queues/rx-$RXTX/rps_cpus
	echo "SET affinity of rx-$RXTX to 0 ( disable RPS )"
}
enableAllCores
total_cores=$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l)
IFACE=eth0
redis_list=$(pgrep redis-server | sort )
irq_threads=$(grep $IFACE /proc/interrupts | awk -F: '{print $1}')

#this is only used to enable disable hyperthreading for redis on runtime
HYPERTHREADING=1
CORE=0
RXTX=0
echo "total cores  "$total_cores
for pid in $redis_list
do  
	echo "REDIS " ${pid} " pinnned to core # " ${CORE}
	sudo taskset -apc $CORE $pid > /dev/null
    #disable hyperthreading for redis core
    #toggleHT_In_2nd_Thread_Sibling
	
    #echo "setting IRQ $IRQ affinity to $CORE_IRQ"
	#sudo sh -c "echo $CORE > /proc/irq/$IRQ/smp_affinity_list"
    #disable_rps_rx_tx_affinity
    #RXTX=$(expr $RXTX + 1)

    CORE=$(expr $CORE + 1)
done

CORE=0

for IRQ in $irq_threads
do 

    echo "setting IRQ $IRQ affinity to $CORE"
	sudo sh -c "echo $CORE > /proc/irq/$IRQ/smp_affinity_list"
    # core 5 starting at 0, will have the 6 mask when setting rps rx tx affinity
    disable_rps_rx_tx_affinity
    RXTX=$(expr $RXTX + 1)

    CORE=$(expr $CORE + 1)
    
done