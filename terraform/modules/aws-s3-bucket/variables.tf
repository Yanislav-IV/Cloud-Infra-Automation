variable "aws_region" {
  description = "The AWS region where resources will be created."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Base name of the S3 bucket."
  type        = string
}

variable "file_expiration_days" {
  description = "Number of days after which files expire."
  type        = number
}

variable "trusted_account_id" {
  description = "The AWS Account ID that will be allowed to read from this bucket."
  type        = string
  default     = null
}

variable "encryption_algorithm" {
  description = "The server-side encryption algorithm to use."
  type        = string
  default     = "AES256"
}
