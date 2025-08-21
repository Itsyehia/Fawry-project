terraform {
  backend "s3" {
    bucket         = "poc-prod-vpc-logs-709efebc"
    key            = "pre-prod/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
  }
}
