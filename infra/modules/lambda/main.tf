data "archive_file" "processor_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../src/processor"
  output_path = "${path.module}/build/processor.zip"
}

data "archive_file" "notifier_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../src/notifier"
  output_path = "${path.module}/build/notifier.zip"
}

# Built separately (see layers/pillow/build.sh) because Pillow ships C
# extensions that must be compiled for Amazon Linux, not your laptop's OS.
resource "aws_lambda_layer_version" "pillow_layer" {
  layer_name          = "${var.project}-pillow-${var.env}"
  filename            = "${path.root}/../layers/pillow/pillow-layer.zip"
  compatible_runtimes = ["python3.12"]
  source_code_hash    = filebase64sha256("${path.root}/../layers/pillow/pillow-layer.zip")
}

resource "aws_lambda_function" "image_processor" {
  function_name    = "${var.project}-image-processor-${var.env}"
  filename         = data.archive_file.processor_zip.output_path
  source_code_hash = data.archive_file.processor_zip.output_base64sha256
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  role             = var.processor_role_arn
  memory_size      = 512
  timeout          = 30
  reserved_concurrent_executions = var.reserved_concurrency
  layers           = [aws_lambda_layer_version.pillow_layer.arn]

  environment {
    variables = {
      PROCESSED_BUCKET = var.processed_bucket_name
      METADATA_TABLE   = var.metadata_table_name
      SNS_TOPIC_ARN    = var.processing_done_topic_arn
      LOG_LEVEL        = var.log_level
    }
  }

  dead_letter_config {
    target_arn = var.dlq_arn
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_function" "notifier" {
  function_name    = "${var.project}-notifier-${var.env}"
  filename         = data.archive_file.notifier_zip.output_path
  source_code_hash = data.archive_file.notifier_zip.output_base64sha256
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  role             = var.notifier_role_arn
  memory_size      = 128
  timeout          = 10

  environment {
    variables = {
      LOG_LEVEL = var.log_level
    }
  }
}

# ---------- S3 -> processor trigger ----------

resource "aws_s3_bucket_notification" "raw_upload_trigger" {
  bucket = var.raw_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".jpg"
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".jpeg"
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".png"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.raw_bucket_arn
}

# ---------- SNS -> notifier trigger ----------

resource "aws_sns_topic_subscription" "notifier_subscription" {
  topic_arn = var.processing_done_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notifier.arn
}

resource "aws_lambda_permission" "allow_sns_invoke" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.processing_done_topic_arn
}

# ---------- CloudWatch alarms on the processor function itself ----------

resource "aws_cloudwatch_metric_alarm" "processor_errors" {
  alarm_name          = "${var.project}-processor-errors-${var.env}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "One or more invocation errors on image-processor in a 5 minute window."
  dimensions = {
    FunctionName = aws_lambda_function.image_processor.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "processor_throttles" {
  alarm_name          = "${var.project}-processor-throttles-${var.env}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Reserved concurrency is being hit - check if it needs raising."
  dimensions = {
    FunctionName = aws_lambda_function.image_processor.function_name
  }
}
