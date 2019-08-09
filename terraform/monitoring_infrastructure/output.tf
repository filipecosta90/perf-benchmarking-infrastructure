
output "monitoring_instance_prometheus" {
  value = ["${aws_instance.monitoring_instance[0].public_ip}:9090"]
}

output "monitoring_instance_grafana" {
  value = ["${aws_instance.monitoring_instance[0].public_ip}:3000"]
}