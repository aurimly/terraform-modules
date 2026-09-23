output "function_arns" {
  description = "Map of function key => function ARN (unqualified)."
  value       = { for k, f in aws_lambda_function.function : k => f.arn }
}

output "function_names" {
  description = "Map of function key => function name (also the aws_lambda_function import ID)."
  value       = { for k, f in aws_lambda_function.function : k => f.function_name }
}

output "function_invoke_arns" {
  description = "Map of function key => :invoke action ARN (for API Gateway and service integrations)."
  value       = { for k, f in aws_lambda_function.function : k => f.invoke_arn }
}

output "function_qualified_arns" {
  description = "Map of function key => version-qualified ARN; populated when publish = true, empty otherwise."
  value       = { for k, f in aws_lambda_function.function : k => f.qualified_arn }
}
