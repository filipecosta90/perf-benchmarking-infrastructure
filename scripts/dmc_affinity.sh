# #!/bin/bash
# NUMA_CNT=$(numactl --hardware | grep '^available' | awk '{print $2}')
# if [ $NUMA_CNT -eq 2 ]; then
#   NODE_ID=$(cat /etc/opt/redislabs/node.id)
#   DMC_HALF_COUNT=$(expr $(/opt/redislabs/bin/ccs-cli hget dmc:$NODE_ID threads) / 2)
#   NUMA0_CPUS=$1 
#   NUMA1_CPUS=$2
#   /opt/redislabs/bin/dmc-cli -ts root list | grep worker | awk '{printf "%i\n",$3}' | sort | head -n$DMC_HALF_COUNT | xargs -i sudo taskset -apc $NUMA0_CPUS {}
#   /opt/redislabs/bin/dmc-cli -ts root list | grep worker | awk '{printf "%i\n",$3}' | sort | tail -n$DMC_HALF_COUNT | xargs -i sudo taskset -apc $NUMA1_CPUS {}
# fi  


#!/bin/bash
NUMA_CNT=$(numactl --hardware | grep '^available' | awk '{print $2}')
if [ $NUMA_CNT -eq 2 ]; then
  NODE_ID=$(cat /etc/opt/redislabs/node.id)
  DMC_HALF_COUNT=$(expr $(/opt/redislabs/bin/ccs-cli hget dmc:$NODE_ID threads) / 2)
  NUMA0_CPUS=$(numactl  --hardware | grep 'node 0 cpus' | awk -F ': ' '{print $2}' | sed 's/ /,/g')
  NUMA1_CPUS=$(numactl  --hardware | grep 'node 1 cpus' | awk -F ': ' '{print $2}' | sed 's/ /,/g')
  DMC_PID=$(sudo /opt/redislabs/bin/dmc-cli -ts root list | grep listener | awk '{printf "%i\n",$3}')
  sudo taskset -apc $NUMA0_CPUS $DMC_PID 
    sudo /opt/redislabs/bin/dmc-cli -ts root list | grep worker | tail -$DMC_HALF_COUNT | \
      awk '{printf "%i\n",$3}' | \
      xargs -i sudo taskset -pc $NUMA1_CPUS {}
fi  
