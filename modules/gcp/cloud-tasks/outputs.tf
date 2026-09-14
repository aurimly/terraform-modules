output "queue_ids" {
  description = "Map of queue key => queue id."
  value       = { for k, q in google_cloud_tasks_queue.queue : k => q.id }
}

output "queue_names" {
  description = "Map of queue key => queue name."
  value       = { for k, q in google_cloud_tasks_queue.queue : k => q.name }
}

output "queue_states" {
  description = "Map of queue key => queue state."
  value       = { for k, q in google_cloud_tasks_queue.queue : k => q.state }
}

output "iam_binding_roles" {
  description = "Map of IAM binding composite key (queue key/binding key) => role."
  value       = { for k, b in google_cloud_tasks_queue_iam_binding.binding : k => b.role }
}
