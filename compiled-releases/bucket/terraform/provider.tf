terraform {
  backend "s3" {
  }
}

provider "aws" {
  use_fips_endpoint = true
  default_tags {
    tags = {
      deployment = "bosh-releases"
      environment = "common"
      provisioner = "terraform"
    }
  }
}
