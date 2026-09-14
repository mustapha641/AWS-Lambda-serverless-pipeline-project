variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "alert_email" {
  type        = string
  description = "Email address that receives ops alerts (DLQ / alarm notifications)."
}

variable "dlq_retention_seconds" {
  type    = number
  default = 1209600 # 14 days
}
