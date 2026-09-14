output "processor_role_arn" {
  value = aws_iam_role.processor_role.arn
}

output "notifier_role_arn" {
  value = aws_iam_role.notifier_role.arn
}
