# perf-benchmarking-infrastructure


All performance benchmarks are run as instances in AWS/GCP through our benchmark testing infrastructure. In addition to the primary benchmark/performance analysis scenarios described above, we also enable running baseline benchmarks on network, memory, CPU and IO, in order to understand the underlying network and VM characteristics. 
We lay on benchmarking infrastructure represented as code, easily replicable, and stable. 


This repo aims to provide severall performance aware setups, to ensure the minimum requirements and toolset to be present.

-------
#### Included toolset

- [eBPF extended Berkeley Packet Filter ](https://www.iovisor.org/technology/ebpf)
- [bpftrace High-level tracing language for Linux eBPF](https://github.com/iovisor/bpftrace) ( soon ) 
- [Performance Co-Pilot (PCP)](https://pcp.io/) + pcp vector panda (System Wide Flame Graphs)
- [perf: Linux profiling with performance counters](https://perf.wiki.kernel.org/index.php/Main_Page)
- [netperf 2.7.0](https://hewlettpackard.github.io/netperf/)
- [STREAM: Sustainable Memory Bandwidth in High Performance Computers](https://www.cs.virginia.edu/stream/)
- [Vector ready](https://github.com/netflix/vector)

-------
#### Included optimizations

- Optimizing within Instances deployment: 
  - Via tuned-adm from RedHat:
    - disabling tuned and ktune power saving mechanisms.
    - enabling sysctl settings that improve the throughput performance of your disk and network I/O, and switches to the deadline scheduler.
    - setting CPU governor to performance.
  - Directly via Ansible:
    - disabling Transparent Huge Pages.
    - manually raising somaxconn to 65535.
    - manually setting vm.overcommit_memory from 0 (default) to 1 ( never refuse any malloc ).

- Optimizing within Instances life: 
  - Directly via Ansible:
    - [TODO] Overall Processor affinity and CPU pinning.
    - [TODO] pinning the application and the queue to a specific CPU in the same NUMA node as the network device.


- Optimizing Network Performance: 
  - Always deploy within same placement group ( multiple 10Gbps flows )
  - Addition of more network interfaces
  - [TODO] Adjustment of network IRQ affinities towards the cores designated to dmc proxy
  - [TODO] Usage of 10 x 10Gbps flows per large VM

  - [TODO] TCP tunning
    - [TODO] Adjustments on TCP receive window
    - [TODO] Adjustments on TCP congestion control
    - [TODO] Adjustments on TCP initial congestion window
  
  - [TODO] Adjustments on More RX/TX queues per VM ( 32 vs 8 ), (( better distribute ethernet interrupts across VMs )
Test latency and jitter per VM
  - [TODO] Prefer instances with Rx Checksum offload 



-------
#### Deployment

##### Deployment Agent Pre-requesites
- awscli installed 
- terraform installed
- ansible installed
- Ansible linux-system-roles.tuned installed ( run setup.sh )

The terraform and ansible scripts expect the following env variables to be filled:
```
export EC2_REGION={ ## INSERT REGION ## }
export EC2_ACCESS_KEY={ ## INSERT EC2 ACCESS KEY ## }
export EC2_SECRET_KEY={ ## INSERT EC2 SECRET KEY ## }
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
export GRAFANA_PASSWORD=perf
export RE_LICENSE="{ ## INSERT RE LICENSE KEY ## }"
```

##### Deployment steps
```bash
terraform plan
terraform apply
```

#### Terraform output and Vector usage

An example execution output:
```text
Apply complete! Resources: 13 added, 0 changed, 0 destroyed.

Outputs:

perf_cto_client_c5n_18xlarge_private_ip = [
  "10.3.0.236",
]
perf_cto_client_c5n_18xlarge_public_ip = [
  "3.15.144.11",
]
perf_cto_client_c5n_18xlarge_vector = [
  "3.15.144.11:44323",
]
perf_cto_server_c5n_18xlarge_private_ip = [
  "10.3.0.145",
]
perf_cto_server_c5n_18xlarge_public_ip = [
  "18.191.162.170",
]
perf_cto_server_c5n_18xlarge_vector = [
  "18.191.162.170:44323",
]

```

Based on the variable outputs we can add an connection for at Vector. As an example we're adding host 18.191.162.170, with PCP Web API acessible via port 44323:

![alt text][add_host]

Out of the box CPU Graphs ( some of them ):
![alt text][sample_cpu]

System Wide Flame Graphs request start:
![alt text][flame_start]

System Wide Flame Graphs request end:
![alt text][flame_ended]


System Wide Flame Graphs output:
![alt text][sample_flame]


[add_host]: ./doc/vector_add_host.png "Sample Flamegraph collection ended"
[sample_cpu]: ./doc/vector_sample_cpu.png "Sample Flamegraph collection ended"
[flame_start]: ./doc/vector_flame_start.png "Sample Flamegraph collection ended"
[flame_ended]: ./doc/vector_flame_ended.png "Sample Flamegraph collection ended"
[sample_flame]: ./doc/vector_sample_flame.png "Sample Flamegraph collection ended"
