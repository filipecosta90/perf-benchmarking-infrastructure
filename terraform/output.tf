
output "perf_cto_client_c5n_18xlarge_public_ip" {
  value = ["${aws_instance.perf_cto_client_c5n_18xlarge[0].public_ip}"]
}

output "perf_cto_client_c5n_18xlarge_private_ip" {
  value = ["${aws_instance.perf_cto_client_c5n_18xlarge[0].private_ip}"]
}

output "perf_cto_server_c5n_18xlarge_public_ip" {
  value = ["${aws_instance.perf_cto_server_c5n_18xlarge[0].public_ip}"]
}

output "perf_cto_server_c5n_18xlarge_private_ip" {
  value = ["${aws_instance.perf_cto_server_c5n_18xlarge[0].private_ip}"]
}

# output "perf_cto_server_c5n_18xlarge_hyperthreading_public_ip" {
#   value = ["${aws_instance.perf_cto_server_c5n_18xlarge_hyperthreading[0].public_ip}"]
# }

# output "perf_cto_server_c5n_h18xlarge_yperthreading_private_ip" {
#   value = ["${aws_instance.perf_cto_server_c5n_18xlarge_hyperthreading[0].private_ip}"]
# }

# output "perf_cto_server_c5_18xlarge_hyperthreading_public_ip" {
#   value = ["${aws_instance.perf_cto_server_c5_18xlarge_hyperthreading[0].public_ip}"]
# }

# output "perf_cto_server_c5_18xlarge_hyperthreading_private_ip" {
#   value = ["${aws_instance.perf_cto_server_c5_18xlarge_hyperthreading[0].private_ip}"]
# }


# output "perf_cto_server_c5_18xlarge_hyperthreading_vector" {
#   value = ['http://performance-cto-group-vector.s3-website.us-east-2.amazonaws.com/?q=%5B%7B"p":"http","h":"${aws_instance.perf_cto_server_c5_18xlarge_hyperthreading[0].private_ip}']
# }

#3.16.76.22:44323","hs":"localhost","ci":"_all","cl":%5B"cpu-utilization","disk-latency","memory-utilization","network-throughput","fg-cpu","network-packets","network-tcp-established","custom-chart","custom-table","cpu-pswitch","cpu-percpu-utilization","cpu-runnable"%5D%7D%5D'

output "perf_cto_client_c5n_18xlarge_vector" {
  value = ["${aws_instance.perf_cto_client_c5n_18xlarge[0].public_ip}:44323"]
}

output "perf_cto_server_c5n_18xlarge_vector" {
  value = ["${aws_instance.perf_cto_server_c5n_18xlarge[0].public_ip}:44323"]
}