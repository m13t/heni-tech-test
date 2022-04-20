terraform {
  backend "s3" {
    bucket = "heni-test-tf-state"
    key    = "demo.tfstate"
    region = "eu-west-2"
  }
}
