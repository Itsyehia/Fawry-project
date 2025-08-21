variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "subnet_cidrs" {
  description = "List of CIDRs for public subnets"
  type        = list(string)
}

variable "env" {
  description = "Environment name (e.g. pre-prod, prod)"
  type        = string
}
