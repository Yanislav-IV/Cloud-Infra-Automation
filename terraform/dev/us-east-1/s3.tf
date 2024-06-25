locals {
  bucket_name          = "${local.project_name}-events-bucket"
  file_expiration_days = 7
}

module "events_bucket" {
  source               = "../../modules/aws-s3-bucket"
  bucket_name          = local.bucket_name
  trusted_account_id   = local.trusted_account_id
  file_expiration_days = local.file_expiration_days
}
