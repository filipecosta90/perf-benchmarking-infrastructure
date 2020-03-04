
output "az1_master_instance_public_ip" {
  value = ["${aws_instance.az1_c1_master_instance.public_ip}"]
}
