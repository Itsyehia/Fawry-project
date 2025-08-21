variable "instance_count" {
  description = "Number of EC2 instances to launch."
  type        = number
  default     = 1
}

variable "env" {
  description = "Environment name (e.g., pre-prod, prod) for resource naming."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}
