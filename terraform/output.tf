
output "perf_cto_client_c5n_9xlarge_public_ip" {
  value = ["${aws_instance.perf_cto_client_c5n_9xlarge[0].public_ip}"]
}

output "perf_cto_client_c5n_9xlarge_private_ip" {
  value = ["${aws_instance.perf_cto_client_c5n_9xlarge[0].private_ip}"]
}

output "perf_cto_server_c5n_9xlarge_public_ip" {
  value = ["${aws_instance.perf_cto_server_c5n_9xlarge[0].public_ip}"]
}

output "perf_cto_server_c5n_9xlarge_private_ip" {
  value = ["${aws_instance.perf_cto_server_c5n_9xlarge[0].private_ip}"]
}

output "perf_cto_client_c5n_9xlarge_vector" {
  value = ["${aws_instance.perf_cto_client_c5n_9xlarge[0].public_ip}:44323"]
}

output "perf_cto_server_c5n_9xlarge_vector" {
  value = ["${aws_instance.perf_cto_server_c5n_9xlarge[0].public_ip}:44323"]
}


# output "perf_cto_server_c5n_9xlarge_hyperthreading_public_ip" {
#   value = ["${aws_instance.perf_cto_server_c5n_9xlarge_hyperthreading[0].public_ip}"]
# }

# output "perf_cto_server_c5n_h18xlarge_yperthreading_private_ip" {
#   value = ["${aws_instance.perf_cto_server_c5n_9xlarge_hyperthreading[0].private_ip}"]
# }

# output "perf_cto_server_c5_9xlarge_hyperthreading_public_ip" {
#   value = ["${aws_instance.perf_cto_server_c5_9xlarge_hyperthreading[0].public_ip}"]
# }

# output "perf_cto_server_c5_9xlarge_hyperthreading_private_ip" {
#   value = ["${aws_instance.perf_cto_server_c5_9xlarge_hyperthreading[0].private_ip}"]
# }

# output "perf_cto_server_c5n_9xlarge_hyperthreading_vector" {
#   value = ["${aws_instance.perf_cto_server_c5n_9xlarge_hyperthreading[0].public_ip}:44323"]
# }


# output "perf_cto_server_c5_9xlarge_hyperthreading_vector" {
#   value = ["${aws_instance.perf_cto_server_c5_9xlarge_hyperthreading[0].public_ip}:44323"]
# }