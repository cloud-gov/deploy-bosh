variable "cg_bucket_name" {}

data "aws_partition" "current" {}

module "bosh-resources" {
  source = "github.com/cloud-gov/cg-provision//terraform/modules/s3_bucket/encrypted_bucket_v2"
  bucket        = var.cg_bucket_name
  aws_partition = data.aws_partition.current.id
}
