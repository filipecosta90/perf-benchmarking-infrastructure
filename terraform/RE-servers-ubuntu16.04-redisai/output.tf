
output "perf_cto_server_public_ip" {
  value = ["${aws_instance.perf_cto_server[0].public_ip}"]
}

output "perf_cto_server_private_ip" {
  value = ["${aws_instance.perf_cto_server[0].private_ip}"]
}

output "perf_cto_server_netdata" {
  value = ["${aws_instance.perf_cto_server[0].public_ip}:49999"]
}

output "perf_cto_server_redisenterprise" {
  value = ["${aws_instance.perf_cto_server[0].public_ip}:8443"]
}