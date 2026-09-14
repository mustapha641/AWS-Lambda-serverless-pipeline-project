output "processor_function_name" {
  value = aws_lambda_function.image_processor.function_name
}

output "notifier_function_name" {
  value = aws_lambda_function.notifier.function_name
}
