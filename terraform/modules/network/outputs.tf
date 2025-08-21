output "vpc_id" {
  value = aws_vpc.this.id
}

output "subnet_ids" {
  value = aws_subnet.public[*].id
}

output "k3s_security_group_id" {
  description = "The ID of the K3s security group."
  value       = aws_security_group.k3s.id
}
