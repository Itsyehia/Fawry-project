terraform {
  backend "s3" {
    bucket = "poc-prod-vpc-logs-599192675916-preprod"
    key            = "pre-prod/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
  }
}
