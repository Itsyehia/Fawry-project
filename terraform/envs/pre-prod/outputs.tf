output "vpc_id" {
  value = module.network.vpc_id
}

output "subnet_ids" {
  value = module.network.subnet_ids
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository."
  value       = module.ecr.repository_url
}

output "ec2_public_ips" {
  description = "Public IP addresses of the EC2 instances."
  value       = module.compute.public_ips
}

output "ec2_private_ips" {
  description = "Private IP addresses of the EC2 instances."
  value       = module.compute.private_ips
}
