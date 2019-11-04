#!/bin/bash
ansible-galaxy install cloudalchemy.prometheus
ansible-galaxy install cloudalchemy.node-exporter
ansible-galaxy install cloudalchemy.grafana
ansible-galaxy install linux-system-roles.tuned
ansible-galaxy install idealista.prometheus_redis_exporter-role
ansible-galaxy install cloudalchemy.process_exporter
ansible-galaxy install jffz.netdata
ansible-galaxy install gantsign.golang