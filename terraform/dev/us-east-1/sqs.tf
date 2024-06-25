locals {
  s3_events_queue_name               = "${local.project_name}-s3-events"
  batch_size                         = 5
  maximum_batching_window_in_seconds = 30
  visibility_timeout_seconds         = 10
  maxReceiveCount                    = 5
}

# Define a Dead Letter Queue (DLQ) for S3 events
# This queue will store messages that could not be processed successfully.
resource "aws_sqs_queue" "s3_events_dlq" {
  name = "${local.s3_events_queue_name}-dlq"
}

# Define the main SQS queue for S3 events
# This queue will receive notifications from the S3 bucket when new objects are created.
resource "aws_sqs_queue" "s3_events_queue" {
  name                       = local.s3_events_queue_name
  visibility_timeout_seconds = local.visibility_timeout_seconds

  # Configure the redrive policy to send messages to the DLQ after a maximum number of receive attempts
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.s3_events_dlq.arn
    maxReceiveCount     = local.maxReceiveCount
  })
}

# Map the SQS queue to the Lambda function
# This configuration tells Lambda to poll the SQS queue and process messages in batches.
resource "aws_lambda_event_source_mapping" "sqs_event_source" {
  event_source_arn                   = aws_sqs_queue.s3_events_queue.arn
  function_name                      = module.s3_events_lambda.lambda_function_name
  batch_size                         = local.batch_size
  maximum_batching_window_in_seconds = local.maximum_batching_window_in_seconds
}

resource "aws_sqs_queue_policy" "s3_events_queue_policy" {
  queue_url = aws_sqs_queue.s3_events_queue.id
  policy    = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "SQS:SendMessage",
        Resource  = aws_sqs_queue.s3_events_queue.arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn" : module.events_bucket.bucket_arn
          }
        }
      }
    ]
  })
}

# Configure S3 bucket to send notifications to the SQS queue
# When a new object is created in the bucket, a message is sent to the SQS queue.
resource "aws_s3_bucket_notification" "s3_bucket_notification" {
  bucket = module.events_bucket.bucket_id

  queue {
    queue_arn     = aws_sqs_queue.s3_events_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = local.source_dir
  }
}
