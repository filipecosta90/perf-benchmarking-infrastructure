// Instance Name	vCPUs RAM EBS Bandwidth	Network Bandwidth
// c5n.4xlarge	16	42 GiB	3.5 Gbps	Up to 25 Gbps

Uses Ubuntu 16.04 as base
ubuntu/images/hvm-io1/ubuntu-xenial-16.04-amd64-server-20170307 - ami-be7753db

```bash
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
terraform plan
terraform apply
```