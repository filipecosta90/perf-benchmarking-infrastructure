
output "az3_master_instance_public_ip" {
  value = ["${aws_instance.az3_master_instance.public_ip}"]
}

output "az3_replica_instance_public_ip" {
  value = ["${aws_instance.az3_replica_instance.public_ip}"]
}
