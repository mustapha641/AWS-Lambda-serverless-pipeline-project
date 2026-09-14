# Fan-out topic: processor publishes here when an image finishes successfully.
resource "aws_sns_topic" "processing_done" {
  name = "${var.project}-processing-done-${var.env}"
}

# Ops topic: gets a message whenever the DLQ alarm fires.
resource "aws_sns_topic" "ops_alerts" {
  name = "${var.project}-ops-alerts-${var.env}"
}

resource "aws_sns_topic_subscription" "ops_email" {
  topic_arn = aws_sns_topic.ops_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Dead-letter queue for the processor Lambda's failed async invocations.
resource "aws_sqs_queue" "processor_dlq" {
  name                      = "${var.project}-processor-dlq-${var.env}"
  message_retention_seconds = var.dlq_retention_seconds
  sqs_managed_sse_enabled   = true
}

resource "aws_cloudwatch_metric_alarm" "dlq_has_messages" {
  alarm_name          = "${var.project}-dlq-not-empty-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Fires when a message lands in the processor DLQ - means an image silently failed."
  dimensions = {
    QueueName = aws_sqs_queue.processor_dlq.name
  }
  alarm_actions = [aws_sns_topic.ops_alerts.arn]
}
