resource "aws_lambda_function" "this" {
  function_name = var.lambda_function_name
  role          = var.lambda_role_arn
  package_type  = var.package_type
  image_uri     = var.image_uri

  environment {
    variables = var.env_variables
  }
}
