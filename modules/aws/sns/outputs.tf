output "topic_arns" {
  description = "Map of topic key => topic ARN."
  value       = { for k, t in aws_sns_topic.topic : k => t.arn }
}

output "topic_names" {
  description = "Map of topic key => topic name."
  value       = { for k, t in aws_sns_topic.topic : k => t.name }
}

output "subscription_arns" {
  description = "Map of \"topic-key.subscription-key\" => subscription ARN."
  value       = { for k, s in aws_sns_topic_subscription.subscription : k => s.arn }
}
