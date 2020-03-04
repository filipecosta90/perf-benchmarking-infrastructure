
output "memtier_1_50" {
  value = ["${aws_instance.memtier_1_50.public_ip}"]
}

output "memtier_2_50" {
  value = ["${aws_instance.memtier_2_50.public_ip}"]
}

output "memtier_3_50" {
  value = ["${aws_instance.memtier_3_50.public_ip}"]
}

output "memtier_1_85" {
  value = ["${aws_instance.memtier_1_85.public_ip}"]
}

output "memtier_2_85" {
  value = ["${aws_instance.memtier_2_85.public_ip}"]
}

output "memtier_3_85" {
  value = ["${aws_instance.memtier_3_85.public_ip}"]
}
