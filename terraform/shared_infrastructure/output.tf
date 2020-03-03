output "performance_cto_sg_id" {
  value = "${aws_security_group.performance_cto_sg.id}"
}

output "performance_cto_vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "subnet_public_id" {
  value = "${aws_subnet.subnet_public.id}"
}

output "perf_cto_pg_name" {
  value = "${aws_placement_group.perf_cto_pg.name}"
}

output "placement_group_name_us_east_2b" {
  value = "${aws_placement_group.perf_cto_pg_us_east_2b.name}"
}

output "placement_group_name_us_east_2c" {
  value = "${aws_placement_group.perf_cto_pg_us_east_2c.name}"
}

output "perf_cto_eip_id" {
  value = "${aws_eip.perf_cto_eip.id}"
}

output "perf_cto_eip_public_ip" {
  value = "${aws_eip.perf_cto_eip.public_ip}"
}

output "subnet_us_east_2a_public_id" {
  value = "${aws_subnet.subnet_public.id}"
}

output "subnet_us_east_2b_public_id" {
  value = "${aws_subnet.subnet_public_us_east_2b.id}"
}

output "subnet_us_east_2c_public_id" {
  value = "${aws_subnet.subnet_public_us_east_2c.id}"
}



