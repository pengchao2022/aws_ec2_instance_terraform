terraform {
  backend "s3" {
    bucket         = "pengchao2022-terraform-state"
    key            = "ec2-simple/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}