terraform {
  backend "s3" {
    bucket = "terraform-reaclcoud-eks-state"
    key    = "eks/terraform.tfstate"
    region = "us-east-1"
  }
}
