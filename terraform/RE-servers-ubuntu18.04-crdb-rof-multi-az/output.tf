
output "perf_cto_server_public_ip" {
  value = ["${aws_instance.az1_master_instance.public_ip}"]
}

output "perf_cto_server_private_ip" {
  value = ["${aws_instance.az1_master_instance.private_ip}"]
}
output "perf_cto_server_netdata_host" {
  value = ["${aws_instance.az1_master_instance.public_ip}:49999"]
}
