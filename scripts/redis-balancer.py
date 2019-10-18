#!/opt/redislabs/bin/python
# Redis Balancer for NUMA Class Systems
# Python 2.7.X
# Based on scripts from Nail Sirazitdinov and Shankhadeep Shome
# Version 0.1
import argparse
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


class ProcessInfo:
    def __init__(self, processid, numa_node_id=-1,
                 affinity_list=None):
        self.pid = processid
        self.numa_node_id = numa_node_id
        self.affinity_list = affinity_list

        def __str__(self):
            return "Process with pid: {pid}, numa_node_id: {numa_node_id}, affinity_list {numa_node_id}".format(
                pid=self.pid,
                numa_node_id=self.numa_node_id,
                affinity_list=self.affinity_list
            )


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
        # self.current_psr = None parse_pid_psr(processid)

        for v in command_args:
            if ".conf" in v:
                self.conf_file_name = v

        if self.conf_file_name is not None:
            self.read_conf_file(self.conf_file_name)

    def read_conf_file(self, filename):
        print "\t\treading {}".format(filename)
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
            redis_dict[pid] = RedisProcessInfo(pid, pid, conf)

    return redis_dict


# Python dmc process list parsing

def parse_dmc_processlist(process_grep_str):
    process = subprocess.Popen(['/opt/redislabs/bin/dmc-cli -ts root list | grep ' + process_grep_str], shell=True,
                               stdout=subprocess.PIPE)

    vmraw_list = process.communicate()
    vmraw_list = str.splitlines(vmraw_list[0])
    process_dict = {}
    for index in range(len(vmraw_list)):
        row = str.split(vmraw_list[index])
        pid = row[2]
        if pid != process.pid:
            process_dict[pid] = ProcessInfo(pid)

    return process_dict


#  Check the processor that process is currently assigned to.
def parse_pid_psr(processid):
    psr = None
    process = subprocess.Popen(['ps -o psr -p ' + processid], shell=True, stdout=subprocess.PIPE)

    vmraw_list = process.communicate()
    vmraw_list = str.splitlines(vmraw_list[0])
    if len(vmraw_list) > 1:
        psr = vmraw_list[1]

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


# Add a process and it's threads to a cpuset

def taskset_numa_process(processid, numa_cpus):
    if len(numa_cpus) > 0:
        numa_cpus_str = "{}".format(numa_cpus[0])
        for cpu_num in numa_cpus[1:]:
            numa_cpus_str = numa_cpus_str + ",{}".format(cpu_num)
        runcmd = 'taskset -apc {numa_cpus} {processid}'.format(numa_cpus=numa_cpus_str, processid=processid)
        print "\t\t{}".format(runcmd)
        process = subprocess.Popen([runcmd], shell=True, stdout=subprocess.PIPE)
        output = process.communicate()
        return 1
    else:
        return 0


def migratepages_numa_process(processid, from_nodes, to_nodes):
    runcmd = 'migratepages {processid} {from_nodes} {to_nodes}'.format(to_nodes=to_nodes, from_nodes=from_nodes,
                                                                       processid=processid)
    print "\t\t{}".format(runcmd)
    process = subprocess.Popen([runcmd], shell=True, stdout=subprocess.PIPE)
    output = process.communicate()
    return 1


def process_rebalancer(numa_list, redis_dict, debug=0):
    # sort the pid list
    redis_pids = redis_dict.keys()
    redis_pids.sort()
    numa_node_ids = numa_list.keys()
    nredis = len(redis_pids)
    nnodes = len(numa_node_ids)
    rediss_per_numa = math.ceil(nredis / nnodes)
    print "Will split {nredis} pids among {nnodes} numa nodes. {per_node} Process's per numa node".format(
        nredis=nredis,
        nnodes=nnodes,
        per_node=rediss_per_numa)

    for id in numa_node_ids:
        nelems = rediss_per_numa
        cpu_list = numa_list[id].cpu_list
        node_number = numa_list[id].node_number
        while nelems > 0 and len(redis_pids) > 0:
            pid = redis_pids.pop(0)
            nelems = nelems - 1
            if debug > 2:
                print "\tSetting Process with pid {pid} affinity to numa node {nodeid} with cpu's({cpulist})".format(
                    pid=pid,
                    nodeid=node_number,
                    cpulist=cpu_list
                )
            taskset_numa_process(pid, cpu_list)
            migratepages_numa_process(pid, "all", node_number)

    return 1


# Main Function
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Redis Balancer for NUMA Class Systems.')
    parser.add_argument('--balance_redis', default=False, action='store_true')
    parser.add_argument('--balance_dmc', default=False, action='store_true')
    parser.add_argument('--redis_grep', type=str, default="redis-server", help='string used to grep after ps')
    args = parser.parse_args()
    dmc_grep = "worker"

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

    #### Real Work

    if args.balance_redis is True:
        print 'Reading Redis info'
        redis_dict = parse_redis_processlist(args.redis_grep)
        if len(redis_dict.keys()) < 1:
            print 'No {} running. Exiting..'.format(args.redis_grep)
        print 'Balancing Redis'
        if process_rebalancer(numa_list, redis_dict) == 0:
            print 'Redis Rebalancer failed to execute properly'
            sys.exit(1)

    if args.balance_dmc is True:
        dmc_dict = parse_dmc_processlist(dmc_grep)
        if len(dmc_dict.keys()) < 1:
            print 'No dmc {} running. Exiting..'.format(dmc_grep)
        print 'Balancing DMC'
        if process_rebalancer(numa_list, dmc_dict) == 0:
            print 'DMC Rebalancer failed to execute properly'
            sys.exit(1)

sys.exit(0)
