variable "repository_name" {
  description = "Name of the ECR repository."
  type        = string
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository."
  type        = bool
  default     = true
}

variable "image_tag_immutability" {
  description = "The tag immutability setting for the repository. If true, tags are immutable."
  type        = bool
  default     = true
}
