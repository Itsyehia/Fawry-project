terraform {
  backend "s3" {
    bucket = "poc-prod-vpc-logs-${ACCOUNT_ID}-preprod"
    key            = "pre-prod/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
  }
}
