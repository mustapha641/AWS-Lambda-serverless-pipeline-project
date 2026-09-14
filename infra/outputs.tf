output "raw_bucket_name" {
  value = module.s3.raw_bucket_id
}

output "processed_bucket_name" {
  value = module.s3.processed_bucket_name
}

output "metadata_table_name" {
  value = module.dynamodb.table_name
}

output "processor_function_name" {
  value = module.lambda.processor_function_name
}

output "notifier_function_name" {
  value = module.lambda.notifier_function_name
}

output "ops_alerts_topic_arn" {
  value = module.messaging.ops_alerts_topic_arn
}
