terraform {
  backend "s3" {
    bucket         = "poc-prod-vpc-logs-123456789012-preprod" # replace with your AWS account ID
    key            = "pre-prod/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
  }
}
