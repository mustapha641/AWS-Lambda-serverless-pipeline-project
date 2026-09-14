variable "project" { type = string }
variable "env" { type = string }
variable "log_level" {
  type    = string
  default = "INFO"
}

variable "raw_bucket_id" { type = string }
variable "raw_bucket_arn" { type = string }
variable "processed_bucket_name" { type = string }

variable "metadata_table_name" { type = string }

variable "processing_done_topic_arn" { type = string }

variable "dlq_arn" { type = string }

variable "processor_role_arn" { type = string }
variable "notifier_role_arn" { type = string }

variable "reserved_concurrency" {
  type    = number
  default = 5
}
