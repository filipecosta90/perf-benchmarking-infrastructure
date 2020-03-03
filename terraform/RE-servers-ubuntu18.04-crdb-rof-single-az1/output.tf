
output "az1_master_instance_public_ip" {
  value = ["${aws_instance.az1_master_instance.public_ip}"]
}

output "az1_master_instance_private_ip" {
  value = ["${aws_instance.az1_master_instance.private_ip}"]
}
output "az1_master_instance_netdata_host" {
  value = ["${aws_instance.az1_master_instance.public_ip}:49999"]
}

output "az1_replica_instance_public_ip" {
  value = ["${aws_instance.az1_replica_instance.public_ip}"]
}

output "az1_replica_instance_private_ip" {
  value = ["${aws_instance.az1_replica_instance.private_ip}"]
}

output "az1_replica_instance_netdata_host" {
  value = ["${aws_instance.az1_replica_instance.public_ip}:49999"]
}
