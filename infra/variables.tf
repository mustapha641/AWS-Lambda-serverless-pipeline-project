variable "project" {
  type        = string
  description = "Short project name used as a prefix on every resource."
  default     = "serverless-image-pipeline"
}

variable "env" {
  type        = string
  description = "Deployment environment: dev or prod."
}

variable "region" {
  type        = string
  description = "AWS region to deploy into."
  default     = "us-east-1"
}

variable "account_id" {
  type        = string
  description = "AWS account ID - used to scope IAM log-group resources precisely."
}

variable "alert_email" {
  type        = string
  description = "Email address subscribed to the ops-alerts SNS topic."
}
