output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}
output "public_subnets" {
  value = ["${aws_subnet.subnet_public.id}"]
}
output "public_route_table_ids" {
  value = ["${aws_route_table.rtb_public.id}"]
}
output "perf_cto_server_public_ip" {
  value = ["${aws_instance.perf_cto_server[0].public_ip}"]
}

output "perf_cto_client_public_ip" {
  value = ["${aws_instance.perf_cto_client[0].public_ip}"]
}
