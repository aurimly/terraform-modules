output "table_arns" {
  description = "Map of table key => table ARN."
  value       = { for k, t in aws_dynamodb_table.table : k => t.arn }
}

output "table_ids" {
  description = "Map of table key => table name."
  value       = { for k, t in aws_dynamodb_table.table : k => t.id }
}

output "stream_arns" {
  description = "Map of table key => stream ARN; keys are omitted for tables without an enabled stream."
  value       = { for k, t in aws_dynamodb_table.table : k => t.stream_arn if t.stream_enabled }
}
