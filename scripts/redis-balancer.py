#!/usr/bin/python
# VMBalancer for Numa Class Systems
# Python 2.7.X
# Based on scripts from Nail Sirazitdinov and Shankhadeep Shome
# Version 0.1
import math
import os
import subprocess
import sys


# Locating programs in Python, use the following snip to locate programs in python from http://jimmyg.org/blog/2009/working-with-python-subprocess.html

def whereis(program):
    for path in os.environ.get('PATH', '').split(':'):
        if os.path.exists(os.path.join(path, program)) and \
                not os.path.isdir(os.path.join(path, program)):
            return os.path.join(path, program)
    return None


# Python class numa node

class NumaNode:
    def __init__(self, node_number, cpu_list, memorysize, memoryfree, processcount):
        self.node_number = node_number
        self.cpu_list = cpu_list
        self.memorysize = memorysize
        self.memoryfree = memoryfree
        self.processcount = processcount


class RedisProcessInfo:
    def __init__(self, redis_name, processid, command_args, conf_file_name=None, auth=None, numa_node_id=-1,
                 affinity_list=None):
        self.redis_name = redis_name
        self.pid = processid
        self.command_args = command_args
        self.bind = -1
        self.numa_node_id = numa_node_id
        self.conf_file_name = conf_file_name
        self.conf_file_lines = []
        self.auth = auth
        self.affinity_list = affinity_list
        self.current_psr = parse_pid_psr(processid)

        for v in command_args:
            if ".conf" in v:
                self.conf_file_name = v

        if self.conf_file_name is not None:
            self.read_conf_file(self.conf_file_name)

    def read_conf_file(self, filename):
        print "reading {}".format(filename)
        f = open(filename, "r")
        if f.mode == 'r':
            self.conf_file_lines = f.readlines()
            # print self.conf_file_lines

        for v in self.conf_file_lines:
            if "requirepass" in v:
                self.auth = str.split(v)[1]

    def __str__(self):
        return "redis-server in pid: {pid}, requirepass {auth}, with args {command_args}, numa node: {numa_node_id}".format(
            pid=self.pid,
            auth=self.auth,
            command_args=self.command_args,
            numa_node_id=self.numa_node_id
        )


# Python numactl output parsing

def parsenumactl():
    process = subprocess.Popen(['numactl --hardware | grep cpu'], shell=True, stdout=subprocess.PIPE)
    cpu_list = process.communicate()
    process = subprocess.Popen(['numactl --hardware | grep size'], shell=True, stdout=subprocess.PIPE)
    mem_list = process.communicate()
    process = subprocess.Popen(['numactl --hardware | grep free'], shell=True, stdout=subprocess.PIPE)
    memfree_list = process.communicate()
    cpu_list = str.splitlines(cpu_list[0])
    mem_list = str.splitlines(mem_list[0])
    memfree_list = str.splitlines(memfree_list[0])
    node_list = {}
    for index in range(len(cpu_list)):
        node_list[index] = NumaNode(str.split(cpu_list[index])[1], str.split(cpu_list[index])[3:],
                                    str.split(mem_list[index])[3], str.split(memfree_list[index])[3], 0)
    return node_list


# Python redis process list parsing

def parse_redis_processlist(redis_str):
    process = subprocess.Popen(['ps -ef | grep ' + redis_str], shell=True, stdout=subprocess.PIPE)

    vmraw_list = process.communicate()
    vmraw_list = str.splitlines(vmraw_list[0])
    redis_dict = {}
    for index in range(len(vmraw_list)):
        row = str.split(vmraw_list[index])
        pid = row[1]
        conf = row[7:]
        if redis_str in row[7] and pid != process.pid:
            redis_dict[index] = RedisProcessInfo(pid, pid, conf)

    return redis_dict


#  Check the processor that process is currently assigned to.
def parse_pid_psr(processid):
    psr = None
    process = subprocess.Popen(['ps -o psr -p ' + processid], shell=True, stdout=subprocess.PIPE)

    vmraw_list = process.communicate()
    vmraw_list = str.splitlines(vmraw_list[0])
    if len(vmraw_list) > 0:
        psr = vmraw_list[0]

    print "@@@@" + psr
    return psr


# Checks if system is configured for numa

def numa_capable():
    numa_capable = 0
    process = subprocess.Popen(['numactl --hardware | grep available'], shell=True, stdout=subprocess.PIPE)
    test_available = process.communicate()
    test_available = str.splitlines(test_available[0])
    if int(str.split(test_available[0])[1]) > 1:
        numa_capable = 1
    return numa_capable


# Check if system has the required utilities, cset numactl etc

def required_utilities(utility_list):
    required_utilities = 1
    for index in utility_list:
        if whereis(index) == None:
            print 'Cannot locate ' + index + ' in path!'
            required_utilities = 0
        else:
            print 'Found ' + index + ' at ' + whereis(index)
    return required_utilities


# Checks if VM processid is a member of a numa_node set

def member_of_numa_node(processid, node_number):
    runcmd = 'cset proc -l VMBS' + node_number + ' | tail -n +4 | grep ' + processid
    process = subprocess.Popen([runcmd], shell=True, stdout=subprocess.PIPE)
    if len(process.communicate()[0]) > 0:
        return 1
    else:
        return 0


# Add a process and it's threads to a cpuset

def taskset_numa_process(processid, numa_cpus):
    runcmd = 'taskset -apc {numa_cpus} {processid}'.format()
    process = subprocess.Popen([runcmd], shell=True, stdout=subprocess.PIPE)
    # for index in (str.splitlines(process.communicate()[0])):
    #     print index
    return 1


# Main Function
REDIS_NAME = "redis-server"


def redis_rebalancer(numa_list, redis_dict):
    # sort the redis pid list
    redis_pids = redis_dict.keys().sort()
    numa_node_ids = numa_list.keys()
    print redis_dict.keys()
    print redis_pids
    print numa_node_ids
    rediss_per_numa = math.ceil(len(redis_pids) / len(numa_node_ids))
    print "will split {nredis} redis pids among {nnodes} numa nodes. {per_node} redis's per numa node".format(
        nredis=redis_pids,
        nnodes=rediss_per_numa,
        per_node=rediss_per_numa)
    for id in numa_node_ids:
        nelems = rediss_per_numa
        numa_cpus = numa_list[id]
        while nelems > 0 and len(redis_pids) > 0:
            pid = redis_pids.pop(0)
            nelems = nelems - 1
            print "setting redis with pid {pid} affinity to numa node {nodeid} with cpu's({cpulist})".format(
                pid=pid,
                nodeid=id,
                cpulist=numa_cpus
            )

    # self.node_number = node_number
    # self.cpu_list = cpu_list
    # self.memorysize = memorysize
    # self.memoryfree = memoryfree
    # self.processcount = processcount
    #
    return 1


if __name__ == "__main__":
    if len(sys.argv) > 1:
        print 'Utility does not take arguments.. yet'
        sys.exit(1)

    redis_dict = parse_redis_processlist(REDIS_NAME)
    for k, v in redis_dict.items():
        print v

    if len(redis_dict.keys()) < 1:
        print 'No {} running. Exiting..'.format(REDIS_NAME)
        sys.exit(1)

    if required_utilities(['taskset', 'numactl', 'chrt', 'migratepages']) == 0:
        print 'Utilities Missing! Exiting..'
        sys.exit(1)
    if numa_capable() == 0:
        print 'Machine not numa capable or memory is not configured with a numa layout'
        sys.exit(1)
    # Parse numactl, the resulting dictionary should always be greater than 2
    numa_list = parsenumactl()
    if len(numa_list) < 2:
        print 'Cannot parse numactl properly'
        sys.exit(1)

    # # Create cpu sets
    # if create_cset(numa_list) == 0:
    # 	print 'Program Error: could not create cpu sets using cset, see cset documentation for furthur details'
    # 	sys.exit(1)
    # # Create a list of running VMs from virsh
    # virsh_vm_list = parse_vmlist('/var/run/libvirt/qemu/')
    # if not virsh_vm_list:
    # 	print 'No running VMs using libvirt'
    # 	sys.exit(0)
    # # Run vm_rebalancer
    if redis_rebalancer(numa_list, redis_dict) == 0:
        print 'Redis Rebalancer failed to execute properly'
        sys.exit(1)

sys.exit(0)
