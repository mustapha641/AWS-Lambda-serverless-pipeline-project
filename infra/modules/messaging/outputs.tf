output "processing_done_topic_arn" {
  value = aws_sns_topic.processing_done.arn
}

output "ops_alerts_topic_arn" {
  value = aws_sns_topic.ops_alerts.arn
}

output "dlq_arn" {
  value = aws_sqs_queue.processor_dlq.arn
}

output "dlq_url" {
  value = aws_sqs_queue.processor_dlq.id
}
