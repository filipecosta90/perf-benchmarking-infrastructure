
output "az1_master_instance_public_ip" {
  value = ["${aws_instance.az1_master_instance.public_ip}"]
}

output "az1_replica_instance_public_ip" {
  value = ["${aws_instance.az1_replica_instance.public_ip}"]
}

# output "az2_master_instance_public_ip" {
#   value = ["${aws_instance.az2_master_instance.public_ip}"]
# }

output "az2_replica_instance_public_ip" {
  value = ["${aws_instance.az2_replica_instance.public_ip}"]
}

# output "az3_master_instance_public_ip" {
#   value = ["${aws_instance.az3_master_instance.public_ip}"]
# }

output "az3_replica_instance_public_ip" {
  value = ["${aws_instance.az3_replica_instance.public_ip}"]
}
