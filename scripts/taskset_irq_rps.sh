#!/bin/sh

# check for irqbalance running
IRQBALANCE_ON=`ps ax | grep -v grep | grep -q irqbalance; echo $?`
if [ "$IRQBALANCE_ON" == "0" ] ; then
	echo " WARNING: irqbalance is running and will"
	echo "          likely override this script's affinitization."
	echo "          Please stop the irqbalance service and/or execute"
	echo "          'killall irqbalance'"
fi

set_rps_rx_tx_affinity()
{
	VEC=$CORE_IRQ
	if [ $VEC -ge 32 ]
	then
		MASK_FILL=""
		MASK_ZERO="00000000"
		let "IDX = $VEC / 32"
		for ((i=1; i<=$IDX;i++))
		do
			MASK_FILL="${MASK_FILL},${MASK_ZERO}"
		done

		let "VEC -= 32 * $IDX"
		MASK_TMP=$((1<<$VEC))
		MASK=$(printf "%X%s" $MASK_TMP $MASK_FILL)
	else
		MASK_TMP=$((1<<$VEC))
		MASK=$(printf "%X" $MASK_TMP)
	fi
    echo $MASK > /sys/class/net/$IFACE/queues/rx-$RXTX/rps_cpus
	echo "SET affinity of rx-$RXTX to core $CORE_IRQ"
}


disable_rps_rx_tx_affinity()
{
    echo 0 > /sys/class/net/$IFACE/queues/rx-$RXTX/rps_cpus
	echo "SET affinity of rx-$RXTX to 0 ( disable RPS )"
}

total_cores=$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l)
total_shards=5
IFACE=eth0
redis_list=$(pgrep redis-server | sort | head -n$total_shards )
dmc_worker_list=$(/opt/redislabs/bin/dmc-cli -ts root list | grep worker | awk '{printf "%i\n",$3}' )
dmc_listener=$(/opt/redislabs/bin/dmc-cli -ts root list | grep listener | awk '{printf "%i\n",$3}' )
irq_threads=$(grep $IFACE /proc/interrupts | awk -F: '{print $1}')

CORE=0

echo "total cores  "$total_cores
for pid in $redis_list
do  
	echo "REDIS " ${pid} " pinnned to core # " ${CORE}
	sudo taskset -apc $CORE $pid > /dev/null
	CORE=$(expr $CORE + 1)
done

listener_list=""
CORE_START_DMC=$CORE
for pid in $dmc_worker_list
do  
	echo "DMC WORKER" ${pid} " pinnned to core # " ${CORE}
	sudo taskset -apc $CORE $pid  > /dev/null
	listener_list=$listener_list$CORE","
	CORE=$(expr $CORE + 1)
done
CORE=$(expr $CORE - 1)
CORE_END_DMC=$CORE
echo "DMC LISTENER" 

sudo taskset -apc ${listener_list::-1} $dmc_listener

CORE_IRQ=$CORE_START_DMC
RXTX=0
for IRQ in $irq_threads
do
	echo "setting IRQ $IRQ affinity to $CORE_IRQ"
	sudo sh -c "echo $CORE_IRQ > /proc/irq/$IRQ/smp_affinity_list"
    
	if [ "$CORE_IRQ" == "$CORE_END_DMC" ]; then
    	CORE_IRQ=$CORE_START_DMC
	else
		CORE_IRQ=$(expr $CORE_IRQ + 1)
	fi
    # core 5 starting at 0, will have the 6 mask when setting rps rx tx affinity
    disable_rps_rx_tx_affinity
    RXTX=$(expr $RXTX + 1)
done