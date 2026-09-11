output "topic_names" {
  description = "Map of topic key => topic name."
  value       = { for k, t in google_pubsub_topic.topic : k => t.name }
}

output "topic_ids" {
  description = "Map of topic key => fully-qualified topic ID (projects/{project}/topics/{name}). Use this value for cross-resource references such as dead-letter topics or notification topics."
  value       = { for k, t in google_pubsub_topic.topic : k => t.id }
}

output "subscription_names" {
  description = "Map of subscription composite key (topic key/subscription key) => subscription name."
  value       = { for k, s in google_pubsub_subscription.subscription : k => s.name }
}

output "subscription_ids" {
  description = "Map of subscription composite key (topic key/subscription key) => fully-qualified subscription ID (projects/{project}/subscriptions/{name})."
  value       = { for k, s in google_pubsub_subscription.subscription : k => s.id }
}

output "topic_iam_binding_roles" {
  description = "Map of topic IAM binding composite key (topic key/binding key) => role."
  value       = { for k, b in google_pubsub_topic_iam_binding.topic_binding : k => b.role }
}

output "subscription_iam_binding_roles" {
  description = "Map of subscription IAM binding composite key (topic key/subscription key/binding key) => role."
  value       = { for k, b in google_pubsub_subscription_iam_binding.subscription_binding : k => b.role }
}
