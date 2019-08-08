output "perf_cto_client_c5n_9xlarge_public_ip" {
  value = ["${aws_instance.perf_cto_client_c5n_9xlarge[0].public_ip}"]
}

output "perf_cto_client_c5n_9xlarge_private_ip" {
  value = ["${aws_instance.perf_cto_client_c5n_9xlarge[0].private_ip}"]
}

output "perf_cto_client_c5n_9xlarge_vector" {
  value = ["${aws_instance.perf_cto_client_c5n_9xlarge[0].public_ip}:44323"]
}