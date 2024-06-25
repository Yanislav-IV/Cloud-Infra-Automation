# Define an S3 bucket
# This bucket will be used to store files and other objects.
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = {
    Name = var.bucket_name
  }
}

# Configure lifecycle rules to remove files older than a specified number of days
# This ensures that old files are automatically deleted after a set period.
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "RemoveOldFilesAfter${var.file_expiration_days}Days"
    status = "Enabled"

    expiration {
      days = var.file_expiration_days
    }
  }
}

# Enable versioning for the S3 bucket
# This allows for multiple versions of an object to be stored in the bucket.
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for the S3 bucket
# This ensures that all objects stored in the bucket are encrypted.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.encryption_algorithm
    }
  }
}

# Enforce bucket owner full control
# This ensures that the bucket owner has full control over all objects.
resource "aws_s3_bucket_ownership_controls" "bucket_owner_enforced" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Block public access to the S3 bucket
# This prevents public access to the bucket and its objects unless a trusted account ID is provided.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.trusted_account_id == null ? true : false
  block_public_policy     = var.trusted_account_id == null ? true : false
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Define a policy document for cross-account read access
# This policy allows read access to the bucket for a specified trusted account ID if provided.
data "aws_iam_policy_document" "cross_account_read_access" {
  count = var.trusted_account_id != null ? 1 : 0

  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.trusted_account_id}:root"]
    }
    actions   = ["s3:GetObject"]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.this.id}",
      "arn:aws:s3:::${aws_s3_bucket.this.id}/*"
    ]
  }
}

# Apply the cross-account read access policy to the S3 bucket
# This attaches the policy document to the bucket if a trusted account ID is provided.
resource "aws_s3_bucket_policy" "cross_account_read_access" {
  count = var.trusted_account_id != null ? 1 : 0

  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.cross_account_read_access[0].json
}
