
output "az1_memtier_instance_public_ip" {
  value = ["${aws_instance.az1_memtier_instance.public_ip}"]
}

output "az1_memtier_instance_private_ip" {
  value = ["${aws_instance.az1_memtier_instance.private_ip}"]
}
output "az1_memtier_instance_netdata_host" {
  value = ["${aws_instance.az1_memtier_instance.public_ip}:49999"]
}


output "az2_memtier_instance_public_ip" {
  value = ["${aws_instance.az2_memtier_instance.public_ip}"]
}

output "az2_memtier_instance_private_ip" {
  value = ["${aws_instance.az2_memtier_instance.private_ip}"]
}
output "az2_memtier_instance_netdata_host" {
  value = ["${aws_instance.az2_memtier_instance.public_ip}:49999"]
}



output "az3_memtier_instance_public_ip" {
  value = ["${aws_instance.az3_memtier_instance.public_ip}"]
}

output "az3_memtier_instance_private_ip" {
  value = ["${aws_instance.az3_memtier_instance.private_ip}"]
}
output "az3_memtier_instance_netdata_host" {
  value = ["${aws_instance.az3_memtier_instance.public_ip}:49999"]
}
