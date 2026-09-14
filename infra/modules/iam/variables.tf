variable "project" { type = string }
variable "env" { type = string }
variable "region" { type = string }
variable "account_id" { type = string }

variable "raw_bucket_arn" { type = string }
variable "processed_bucket_arn" { type = string }
variable "metadata_table_arn" { type = string }
variable "processing_done_topic_arn" { type = string }
