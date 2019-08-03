#!/bin/bash
NUMA_CNT=$(numactl --hardware | grep '^available' | awk '{print $2}')
REDIS_HALF_CNT=$(expr $(pgrep redis-server-5 | wc -l) / 2)
NUMA0_CPUS=$(numactl  --hardware | grep 'node 0 cpus' | awk -F ': ' '{print $2}' | sed 's/ /,/g')
NUMA1_CPUS=$(numactl  --hardware | grep 'node 1 cpus' | awk -F ': ' '{print $2}' | sed 's/ /,/g')
pgrep redis-server-5 | sort | head -$REDIS_HALF_CNT | xargs -i sudo taskset -apc $NUMA0_CPUS {} && \
  pgrep redis-server-5 | sort | head -$REDIS_HALF_CNT | xargs -i sudo migratepages {} 1 0
pgrep redis-server-5 | sort | tail -$REDIS_HALF_CNT | xargs -i sudo taskset -apc $NUMA1_CPUS {} && \
  pgrep redis-server-5 | sort | tail -$REDIS_HALF_CNT | xargs -i sudo migratepages {} 0 1
