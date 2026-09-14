variable "project" {
  type        = string
  description = "Project name, used as a resource name prefix."
}

variable "env" {
  type        = string
  description = "Deployment environment (dev, prod)."
}

variable "raw_bucket_expiry_days" {
  type        = number
  description = "Days after which raw uploads are expired (they are a staging area, not storage)."
  default     = 7
}
