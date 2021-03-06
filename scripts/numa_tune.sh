#!/bin/sh
###
### 
sudo taskset -apc 0-17,36-53 `pgrep dmc` && \
	sudo /opt/redislabs/bin/dmc-cli -ts root list | grep worker | tail -14 | awk '{printf "%i\n",$3}' | xargs -i sudo taskset -pc 18-35,54-71 {}
pgrep redis-server-5 | sort|  head -4 | xargs -i sudo taskset -apc 0-17,36-53 {} && pgrep redis-server-5 | sort | head -4 | xargs -i sudo migratepages {} 1 0
pgrep redis-server-5 | sort |tail -4 | xargs -i sudo taskset -apc 18-35,54-71 {} && pgrep redis-server-5 | sort |tail -4 | xargs -i sudo migratepages {} 0 1




#!/bin/sh

# check for irqbalance running
IRQBALANCE_ON=`ps ax | grep -v grep | grep -q irqbalance; echo $?`
if [ "$IRQBALANCE_ON" == "0" ] ; then
	echo " WARNING: irqbalance is running and will"
	echo "          likely override this script's affinitization."
	echo "          Please stop the irqbalance service and/or execute"
	echo "          'killall irqbalance'"
fi


VEC=17
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

echo $MASK
total_cores=$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l)
total_shards=5
redis_list=$(pgrep redis-server | sort | head -n$total_shards )
dmc_worker_list=$(/opt/redislabs/bin/dmc-cli -ts root list | grep worker | awk '{printf "%i\n",$3}' )
dmc_listener=$(/opt/redislabs/bin/dmc-cli -ts root list | grep listener | awk '{printf "%i\n",$3}' )
irq_threads=$(grep eth0 /proc/interrupts | awk -F: '{print $1}')

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
for IRQ in $irq_threads
do
	echo "setting IRQ $IRQ affinity to $CORE_IRQ"
	sudo sh -c "echo $CORE_IRQ > /proc/irq/$IRQ/smp_affinity_list"
	if [ "$CORE_IRQ" == "$CORE_END_DMC" ]; then
    	CORE_IRQ=$CORE_START_DMC
	else
		CORE_IRQ=$(expr $CORE_IRQ + 1)
	fi
done
