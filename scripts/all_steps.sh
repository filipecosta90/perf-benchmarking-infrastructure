#!/bin/sh

#ensure numad is turned off
numad -i 0

#ensure automatic numa balancing is turned off 
sudo echo 0 > /proc/sys/kernel/numa_balancing

sudo /opt/redislabs/bin/rladmin tune proxy all max_threads 32 threads 32 
sudo /opt/redislabs/bin/dmc_ctl restart
redis_ctl restart-all

 # 1 TO 18 
 # REDIS IS ON CPUs 0-4, 36-40, 18-22, 54-58
 # enable CPUs 5-17
 # Core 1 to 20
 # 0001 1111 1111 1110 0000  (binary)
 #    1   15   15   14    0 (decimal)
 #    1    F    F    E    0     (hex)

 # Core 21 to 40
 # 0000 0111 1111 1111 1100  (binary)
 #    0    7   15   15   12 (decimal)
 #    0    7    F    F    C     (hex)

 # Core 41 to 60
 # 1100 0001 1111 1111 1111  (binary)
 #   12    1   15   15   15 (decimal)
 #    C    1    F    F    F     (hex)

 # Core 61 to 72
 # 1111 1111 1111  (binary)
 #   15   15   15 (decimal)
 #    F    F    F     (hex)
 
# disable RPS and set IRQ affinity to dmcproxy threads
./IRQ_affinity.sh eth0 0-71 ff,fc1fff07,ffc1ffe0 # ff,fc1fff07,ffc1ffe0 # ffffffffffffffffff
./IRQ_affinity.sh eth1 5-17,41-53,23-35,59-71 ff,fc1fff07,ffc1ffe0 # fffc1fff07ffc1ffe0

# balance dmc 
./dmc_affinity.sh 5-17,41-53 23-35,59-71

# balance redis 
./balance_redis.sh 0-4,36-40 18-22,54-58

