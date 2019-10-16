#!/bin/bash


function enableAllCores() {
  for CPU in /sys/devices/system/cpu/cpu[0-9]*; do
      [ -e $CPU/online ] && echo "1" > $CPU/online
  done
}

function toggleHT_In_2nd_Thread_Sibling(){
    THREAD1=`cat /sys/devices/system/cpu/cpu$CORE/topology/thread_siblings_list | cut -f1 -d,`
    THREAD2=`cat /sys/devices/system/cpu/cpu$CORE/topology/thread_siblings_list | cut -f2 -d,`
    if [ $CORE = $THREAD1 ]; then
          echo "CORE $CORE is 1st thread on physical core"
          [ -e /sys/devices/system/cpu/cpu$CORE/online ] && echo "1" > /sys/devices/system/cpu/cpu$CORE/online
          if [ "$HYPERTHREADING" -eq "0" ]; then 
            echo "\t ->HT disabled. disabling 2nd thread ( virtual core $THREAD2 )"; 
        else 
            echo "\t ->HT disabled. enabling 2nd thread ( virtual core $THREAD2 )"; 
        fi
          echo "$HYPERTHREADING" > /sys/devices/system/cpu/cpu$THREAD2/online
    else
        echo "CORE $CORE is 2nd thread on physical core. Nothing to make"
    fi
}


function set_rps_rx_tx_affinity()
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


function disable_rps_rx_tx_affinity()
{
    echo 0 > /sys/class/net/$IFACE/queues/rx-$RXTX/rps_cpus
	echo "SET affinity of rx-$RXTX to 0 ( disable RPS )"
}
enableAllCores
total_cores=$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l)
total_shards=$1
IFACE=eth0
redis_list=$(pgrep redis-server | sort | head -n$total_shards )
dmc_worker_list=$(/opt/redislabs/bin/dmc-cli -ts root list | grep worker | awk '{printf "%i\n",$3}' | sort | head -n16 )
dmc_listener=$(/opt/redislabs/bin/dmc-cli -ts root list | grep listener | awk '{printf "%i\n",$3}' )
irq_threads=$(grep $IFACE /proc/interrupts | awk -F: '{print $1}')
#this is only used to enable disable hyperthreading for redis on runtime
HYPERTHREADING=1
CORE=0

echo "total cores  "$total_cores
for pid in $redis_list
do  
	echo "REDIS " ${pid} " pinnned to core # " ${CORE}
	sudo taskset -apc $CORE $pid > /dev/null
    #disable hyperthreading for redis core
    toggleHT_In_2nd_Thread_Sibling
	CORE=$(expr $CORE + 1)
done

dmc_list=()


listener_list=""
CORE_START_DMC=$CORE
for pid in $dmc_worker_list
do  
    CORE_ENABLED=`cat /sys/devices/system/cpu/cpu$CORE/online`
    while [  $CORE_ENABLED -eq "0" ]; do
        echo "$CORE is disabled. skipping it"; 
        CORE=$(expr $CORE + 1)
        CORE_ENABLED=`cat /sys/devices/system/cpu/cpu$CORE/online`
    done
	echo "DMC WORKER" ${pid} " pinnned to core # " ${CORE}
    
	sudo taskset -apc $CORE $pid  > /dev/null
	listener_list=$listener_list$CORE","
    dmc_list=("${dmc_list[@]}" $CORE)
	CORE=$(expr $CORE + 1)
done
CORE=$(expr $CORE - 1)
CORE_END_DMC=$CORE
echo "DMC LISTENER" 
echo $dmc_list
sudo taskset -apc ${listener_list::-1} $dmc_listener

CORE_IRQ=0
DMC_POS=0
RXTX=0
DMC_SIZE=${#dmc_list[@]}
DMC_SIZE=$(expr $DMC_SIZE - 1)
for IRQ in $irq_threads
do 

    CORE_IRQ=${dmc_list[DMC_POS]}
    echo "setting IRQ $IRQ affinity to $CORE_IRQ"
	sudo sh -c "echo $CORE_IRQ > /proc/irq/$IRQ/smp_affinity_list"
    # core 5 starting at 0, will have the 6 mask when setting rps rx tx affinity
    disable_rps_rx_tx_affinity
    RXTX=$(expr $RXTX + 1)
    if [ $DMC_POS = $DMC_SIZE ]; then
    	DMC_POS=0
	else
		DMC_POS=$(expr $DMC_POS + 1)
	fi
    
done