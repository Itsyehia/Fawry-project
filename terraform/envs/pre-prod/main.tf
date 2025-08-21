terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

module "network" {
  source      = "../../modules/network"
  env         = "pre-prod"
  vpc_cidr    = "10.0.0.0/16"
  subnet_cidrs = ["10.0.1.0/24"]
}

module "compute" {
  source        = "../../modules/compute"
  env           = "pre-prod"
  instance_count = 2
  vpc_id        = module.network.vpc_id
  subnet_ids    = module.network.subnet_ids
  k3s_security_group_id = module.network.k3s_security_group_id
}

module "ecr" {
  source            = "../../modules/ecr"
  repository_name   = "pre-prod-webapp"
  image_tag_mutability = "IMMUTABLE"
  scan_on_push      = true
  tags = {
    Environment = "pre-prod"
    Project     = "webapp"
  }
}
