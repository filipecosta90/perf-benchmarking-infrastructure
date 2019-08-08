#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""sample module for redistimeseries tsbs benchmark tests
"""

import argparse
import datetime
import logging
import os
import time

parser = argparse.ArgumentParser()
parser.add_argument("--redis_port", type=int, help="redis hosts ips comma separated", required=True,default=6379)
parser.add_argument("--redis_host", type=str, help="redis hosts ips comma separated", required=True,default="localhost")
parser.add_argument("--redis_per_host_start_port", type=int, help="redis  per host start port", default=6379)
parser.add_argument("--redis_hosts_ips", type=str, help="redis hosts ips comma separated", required=True)
parser.add_argument("--redis_per_host_shard_count", type=int, help="redis per host shard count", default=2)

args = parser.parse_args()

log_level = logging.ERROR
logging.basicConfig(level=log_level)

redis_port_start = args.redis_per_host_start_port
redis_count      = args.redis_per_host_shard_count
redis_hosts_ips  = args.redis_hosts_ips.split(",")
output = '~/redis-cli -h {} -p {} --cluster create '.format(args.redis_host, args.redis_port)
for ip in redis_hosts_ips:
    for port in range(redis_count):
        tmp = ('{}:{} '.format(ip, redis_port_start+port))
        output += tmp

print(output + '--cluster-replicas 0')
