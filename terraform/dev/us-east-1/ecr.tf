module "s3_events_lambda_ecr_repo" {
  source                 = "../../modules/aws-ecr"
  repository_name        = "${local.function_name}-lambda"
  scan_on_push           = true
  image_tag_immutability = true
}

module "litecoin_app_ecr_repo" {
  source                 = "../../modules/aws-ecr"
  repository_name        = "${local.project_name}-litecoin"
  scan_on_push           = true
  image_tag_immutability = true
}
