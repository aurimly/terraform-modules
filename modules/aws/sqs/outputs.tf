output "queue_ids" {
  description = "Map of queue key => queue URL."
  value       = { for k, q in aws_sqs_queue.queue : k => q.id }
}

output "queue_arns" {
  description = "Map of queue key => queue ARN."
  value       = { for k, q in aws_sqs_queue.queue : k => q.arn }
}

output "queue_names" {
  description = "Map of queue key => queue name."
  value       = { for k, q in aws_sqs_queue.queue : k => q.name }
}
