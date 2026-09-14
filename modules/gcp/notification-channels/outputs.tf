output "channel_names" {
  description = "Map of channel key => full REST resource name (projects/{project}/notificationChannels/{id})."
  value       = { for k, ch in google_monitoring_notification_channel.channel : k => ch.name }
}

output "channel_ids" {
  description = "Map of channel key => channel id."
  value       = { for k, ch in google_monitoring_notification_channel.channel : k => ch.id }
}

output "channel_verification_statuses" {
  description = "Map of channel key => verification status."
  value       = { for k, ch in google_monitoring_notification_channel.channel : k => ch.verification_status }
}
