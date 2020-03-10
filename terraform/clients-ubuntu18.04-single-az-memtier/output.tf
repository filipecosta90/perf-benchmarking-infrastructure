
output "memtier_1_85" {
  value = ["${aws_instance.memtier_1_85.public_ip}"]
}

output "memtier_2_85" {
  value = ["${aws_instance.memtier_2_85.public_ip}"]
}

output "memtier_3_85" {
  value = ["${aws_instance.memtier_3_85.public_ip}"]
}
