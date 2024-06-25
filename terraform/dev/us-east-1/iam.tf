# Define an IAM group for the project
resource "aws_iam_group" "project_group" {
  name = "${local.project_name}-group"
}

# Define an IAM user for the project
resource "aws_iam_user" "project_user" {
  name = "${local.project_name}-user"
}

# Attach the user to the group
resource "aws_iam_user_group_membership" "user_group_membership" {
  user   = aws_iam_user.project_user.name
  groups = [aws_iam_group.project_group.name]
}

# IAM policy document for S3 access permissions
data "aws_iam_policy_document" "s3_access_policy" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${module.events_bucket.bucket_id}",
      "arn:aws:s3:::${module.events_bucket.bucket_id}/*"
    ]
  }
}

# IAM policy to allow S3 access
resource "aws_iam_policy" "s3_access_policy" {
  name        = "${local.project_name}-s3-access"
  description = "Policy to allow push/delete to S3 bucket"
  policy      = data.aws_iam_policy_document.s3_access_policy.json
}

# Attach the S3 access policy to the IAM group
resource "aws_iam_group_policy_attachment" "group_policy_attachment" {
  group      = aws_iam_group.project_group.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name               = "${local.function_name}-lambda_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the S3 access policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
  role       = aws_iam_role.lambda_role.id
  policy_arn = aws_iam_policy.s3_access_policy.arn
}


###################### TASK 4 ######################

# IAM policy document for logging permissions
data "aws_iam_policy_document" "logging_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }
}

# IAM policy for logging permissions
resource "aws_iam_policy" "logging_policy" {
  name        = "${local.project_name}_logging"
  description = "Policy for logging permissions"
  policy      = data.aws_iam_policy_document.logging_policy.json
}

# Attach the logging policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_logging_policy_attachment" {
  role       = aws_iam_role.lambda_role.id
  policy_arn = aws_iam_policy.logging_policy.arn
}

# IAM policy document for Lambda to read from SQS
data "aws_iam_policy_document" "lambda_sqs_policy" {
  statement {
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [aws_sqs_queue.s3_events_queue.arn]
  }
}

# IAM policy for Lambda to read from SQS
resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "${local.project_name}-lambda-sqs-policy"
  description = "Policy for Lambda to read from SQS"
  policy      = data.aws_iam_policy_document.lambda_sqs_policy.json
}

# Attach the SQS read policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_sqs_policy_attachment" {
  role       = aws_iam_role.lambda_role.id
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}
