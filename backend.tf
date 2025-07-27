terraform {
  backend "s3" {
    bucket = "realcloud-tfstate-bucket-001"
    key    = "eks/terraform.tfstate"
    region = "us-east-2"
  }
}
