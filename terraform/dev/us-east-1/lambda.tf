locals {
  image_uri     = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com/${local.function_name}-lambda:${local.tag}"
  function_name = "${local.project_name}-s3-events"
  tag           = "0.1.0"

  source_dir = "source/"
  target_dir = "target/"

  env_variables = {
    SOURCE_DIR = local.source_dir
    TARGET_DIR = local.target_dir
  }
}

module "s3_events_lambda" {
  source               = "../../modules/aws-lambda"
  lambda_function_name = local.function_name
  lambda_role_arn      = aws_iam_role.lambda_role.arn
  env_variables        = local.env_variables
  image_uri            = local.image_uri
}
