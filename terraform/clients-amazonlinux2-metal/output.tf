output "perf_cto_client_public_ip" {
  value = ["${aws_instance.perf_cto_client[0].public_ip}"]
}

output "perf_cto_client_private_ip" {
  value = ["${aws_instance.perf_cto_client[0].private_ip}"]
}

output "perf_cto_client_vector" {
  value = ["${aws_instance.perf_cto_client[0].public_ip}:44323"]
}