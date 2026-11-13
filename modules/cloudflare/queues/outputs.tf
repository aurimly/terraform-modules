output "queue_ids" {
  description = "Map of queue key => queue ID (used by consumers, producers and bindings)."
  value       = { for key, queue in cloudflare_queue.queue : key => queue.id }
}

output "queue_names" {
  description = "Map of queue key => queue name."
  value       = { for key, queue in cloudflare_queue.queue : key => queue.queue_name }
}

output "consumer_ids" {
  description = "Map of \"<queue-key>.<consumer-key>\" => consumer ID."
  value       = { for key, consumer in cloudflare_queue_consumer.consumer : key => consumer.consumer_id }
}

output "consumer_queue_names" {
  description = "Map of \"<queue-key>.<consumer-key>\" => the queue name the consumer is attached to."
  value       = { for key, consumer in cloudflare_queue_consumer.consumer : key => consumer.queue_name }
}
