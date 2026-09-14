# ---------- image-processor role ----------

data "aws_iam_policy_document" "processor_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "processor_role" {
  name               = "${var.project}-processor-role-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.processor_assume.json
}

data "aws_iam_policy_document" "processor_permissions" {
  statement {
    sid       = "ReadRawBucket"
    actions   = ["s3:GetObject"]
    resources = ["${var.raw_bucket_arn}/*"]
  }

  statement {
    sid       = "WriteProcessedBucket"
    actions   = ["s3:PutObject"]
    resources = ["${var.processed_bucket_arn}/*"]
  }

  statement {
    sid       = "WriteMetadataTable"
    actions   = ["dynamodb:PutItem"]
    resources = [var.metadata_table_arn]
  }

  statement {
    sid       = "PublishStatus"
    actions   = ["sns:Publish"]
    resources = [var.processing_done_topic_arn]
  }

  statement {
    sid = "WriteLogs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/*"]
  }

  statement {
    sid = "XRayTracing"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "processor_permissions" {
  name   = "${var.project}-processor-permissions-${var.env}"
  role   = aws_iam_role.processor_role.id
  policy = data.aws_iam_policy_document.processor_permissions.json
}

# ---------- notifier role ----------

resource "aws_iam_role" "notifier_role" {
  name               = "${var.project}-notifier-role-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.processor_assume.json
}

data "aws_iam_policy_document" "notifier_permissions" {
  statement {
    sid       = "SendEmail"
    actions   = ["ses:SendEmail", "ses:SendRawEmail"]
    resources = ["*"] # SES identities are verified separately; scope further once a domain identity ARN exists
  }

  statement {
    sid = "WriteLogs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/*"]
  }
}

resource "aws_iam_role_policy" "notifier_permissions" {
  name   = "${var.project}-notifier-permissions-${var.env}"
  role   = aws_iam_role.notifier_role.id
  policy = data.aws_iam_policy_document.notifier_permissions.json
}

# Allow SQS to be drained by Lambda's event-source machinery isn't needed here
# (the processor DLQ is inspected manually / via CloudWatch alarm, not consumed by a function),
# so no extra role picks up sqs:ReceiveMessage. Add one only if you wire up a redrive Lambda later.
