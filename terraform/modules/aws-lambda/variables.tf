variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "lambda_role_arn" {
  description = "The ARN of the IAM role for the Lambda function"
  type        = string
}

variable "env_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
}

variable "package_type" {
  description = "The deployment package type for the Lambda function (Zip or Image)"
  type        = string
  default     = "Image"

  validation {
    condition     = contains(["Zip", "Image"], var.package_type)
    error_message = "Invalid package type. Must be 'Zip' or 'Image'."
  }
}

variable "image_uri" {
  description = "The URI of the Docker image"
  type        = string
}
