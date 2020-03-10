
output "az1_master_instance_public_ip" {
  value = ["${aws_instance.master_instance.public_ip}"]
}
