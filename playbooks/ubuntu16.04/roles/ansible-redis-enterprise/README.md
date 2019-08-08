# Redis Enterprise Install with Ansible

## Description
Ansible role for installing [Redis Enterprise](https://redislabs.com/redis-enterprise/) on installs RHEL/CentOS 6/7 and Ubuntu trusty/xenial.


## Role Variables

### Tasks Switches
| Variable             | Default     | Comments                                   |
| :---                 | :---        | :---                                              |
| ```re_run_install```| ```True```| Downloads, configures and installs Redis Enterprise. |
| ```re_run_bootstrap```| ```True```| Bootstraps each node to form a Redis Engerprise Cluster. |
| ```re_run_createdatabase```| ```True```| Creates databases and replications as defined further in variables. |
| ```re_run_updatelicense```| ```False```| Can be used to update the license. |
| ```re_run_uninstall```| ```False```| Self explanatory. |
| ```re_run_rollingupgrade```| ```False```| Same as install but executes the install sequential. |

### Variables
| Variable             | Default     | Comments                                   |
| :---                 | :---        | :---                                              |
| ```re_version```| ```5.4.4```| String, The current version of Redis Enterprise. |
| ```re_version_build```| ```7```| String, The current build of the version of Redis Enterprise. |
| ```re_flash_enabled```| ```False```| Boolean, True if this install is for [Redis on Flash](https://redislabs.com/redis-enterprise-documentation/concepts-architecture/memory-architecture/redis-flash/). |
| ```re_username```| ```demo@redislabs.com```| String, Username for UI and Rest api. |
| ```re_password```| ```123456```| String, Password for UI and Rest api. |
| ```re_license```| ``` ```| String, Your Redis Enterprise License in one line.  New lines should be replaced by '\n'. e.g. '----- LICENSE START -----\nRjzu3RXs96HG1h43kW7a4kQAJX/HiHFnWoYPPK5Qi5AytSbakd+YfLEhFamX\n ... \nHe9ol8UJbv0mFGIHEzkGhcbpciiEszrLr+hYJdhA+Q==\n----- LICENSE END -----' |
| ```re_cluster_name```| ```cluster```| String, The cluster name of your FQDN of this cluster.  The FQDN will be '{{ re_cluster_name }} . {{ re_domain_name }}'. |
| ```re_domain_name```| ```local```| String, The domain name of your FQDN of this cluster.  The FQDN will be '{{ re_cluster_name }} . {{ re_domain_name }}'. |
| ```re_persistent_path```| ```/var/opt/redislabs/persist```| String, Location for [Persistent storage](https://redislabs.com/redis-enterprise-documentation/administering/designing-production/persistent-ephemeral-storage/). |
| ```re_ephemeral_path```| ```/var/opt/redislabs/tmp```| String, Location for [Ephemeral storage](https://redislabs.com/redis-enterprise-documentation/administering/designing-production/persistent-ephemeral-storage/). |
| ```re_flash_path```| ```/var/opt/redislabs/flash```| String, Location for [Flash storage](https://redislabs.com/redis-enterprise-documentation/concepts-architecture/memory-architecture/redis-flash/). |
| ```re_lookup_nodes_dns```| ```False```| Boolean, This flag can be used when ansible is not ran from a single orchestrator and hence on each targeted machine.  In this case nodes can join by looking up the ip of the master via DNS after master has bootstrapped. |
| ```re_databases```| ```[]```| Array of databases that will be created.  Default empty list. See next section. |
| ```re_replications_internal```| ```[]```| Array of internal [database replications](https://redislabs.com/redis-enterprise-documentation/administering/intercluster-replication/replica-of/) that will be created.  Default empty list. See next section. |
| ```re_replications_external```| ```[]```| Array of external [database replications](https://redislabs.com/redis-enterprise-documentation/administering/intercluster-replication/replica-of/) that will be created.  Default empty list. See next section. |

### Database Variables
```re_databases```, ```re_replications_internal``` and ```re_replications_external``` are by default an empty array.  If you'd like to use those variables, you need to specify ALL variables for each item of the lists below.
#### Databases
An example of how to specify this in the playbook file can be found in [tests/test.yml](tests/test.yml).

| Variable             | Comments                                   |
| :---                 | :---                                       |
| ```db_name```| String, name of your database. |
| ```db_password```| String, redis AUTH password. |
| ```db_redis_port```| Integer, port on which the database will be exposed. |
| ```db_memory_size```| Integer, size of database in bytes. |
| ```db_type```| String, option between 'redis' and 'memcached'. |
| ```db_replication```| String (boolean), 'true' or 'false' if database needs to be High Available. |
| ```db_sharding```| String (boolean), 'true' or 'false' if database is sharded. |
| ```db_shards_count```| Integer, number of shards of the database. |
| ```db_version```| Integer, major version of redis or memcachd. e.g. '4'. |
| ```db_oss_cluster```| String (boolean), 'true' or 'false' if you want to use the [Cluster API of redis](https://redis.io/topics/cluster-spec).|
| ```db_proxy_policy```| String, The policy used for proxy binding to endpoints. Options of: 'single','all-master-shards' or 'all-nodes'. |
| ```db_shards_placement```| String, Control the density of shards: should they reside on as few ('dense') or as many nodes as possible ('sparse'). |
| ```db_evict_policy```| String, Policy for evicting data options [here](https://redislabs.com/redis-enterprise-documentation/administering/database-operations/eviction-policy/). |
| ```db_persistence```| String, Database on-disk persistence policy. Options of: 'disabled' or 'aof'.|
| ```db_aof_policy```| String, Policy for Append-Only File data persistence. This field gets ignored if 'db_persistence' is disabled. Options of: 'appendfsync-always' or 'appendfsync-every-sec'.|

#### Replications Internal
| Variable             | Comments                                   |
| :---                 | :---                                       |
| ```from```| String, name (db_name) of the source database in this cluster. |
| ```to```| String, name (db_name) of the target database in this cluster. |

#### Replications External
| Variable             | Comments                                   |
| :---                 | :---                                       |
| ```from```| String, source url of the database e.g. 'redis://<user>:<auth>@<endpoint>:<port>' more info [here] (https://redislabs.com/redis-enterprise-documentation/administering/intercluster-replication/replica-of/). |
| ```to```| String, name (db_name) of the target database in this cluster. |

## Example Playbook
An example of a playbook file can also be found in [tests/test.yml](tests/test.yml).

```yaml
- hosts: re_master:re_node:re_quorum_only
  gather_facts: True
  vars:
    - re_cluster_name: 'rediscluster'
    - re_domain_name: 'redislabs.com'
    - re_username: 'devops@redislabs.com'
    - re_password: '654321'
  roles:
    - ansible-redis-enterprise
```
Add to the beginning of your playbook if you're running against Ubuntu xenial
```yaml
- hosts: re_master:re_node:re_quorum_only
  gather_facts: False
  tasks:
  - name: Install python2 for Ansible
    raw: bash -c "test -e /usr/bin/python || (apt -qqy update && apt install -qqy python-minimal python-simplejson)"
    register: output
    changed_when: output.stdout != ""
    become: yes
```

## Example Inventory
```ini
[re_master]
123.123.123.121

[re_node]
123.123.123.122

[re_quorum_only]
123.123.123.123
```

## Testing / Contributing
Basic testing is added via vagrant which will install on 4 OS: Trusty, Xenial, Coreos6 and Coreos7
```
$> vagrant up
```
