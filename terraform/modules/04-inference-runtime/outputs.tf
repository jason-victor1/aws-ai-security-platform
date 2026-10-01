output "inference_vpc_id" {
  description = "ID of the isolated inference VPC"
  value       = aws_vpc.inference_vpc.id
}

output "inference_subnet_id" {
  description = "ID of the air-gapped inference subnet"
  value       = aws_subnet.isolated_subnet_a.id
}

output "inference_security_group_id" {
  description = "ID of the inference security group"
  value       = aws_security_group.inference_sg.id
}
