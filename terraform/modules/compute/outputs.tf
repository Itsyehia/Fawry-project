output "key_pair_name" {
  description = "The name of the SSH key pair."
  value       = aws_key_pair.this.key_name
}

output "private_key_path" {
  description = "The local path to the private key file."
  value       = local_file.private_key_pem.filename
}

output "public_ips" {
  description = "Public IP addresses of the EC2 instances."
  value       = aws_instance.this[*].public_ip
}

output "private_ips" {
  description = "Private IP addresses of the EC2 instances."
  value       = aws_instance.this[*].private_ip
} 
output "private_key_pem" {
  value     = tls_private_key.this.private_key_pem
  sensitive = true
}
