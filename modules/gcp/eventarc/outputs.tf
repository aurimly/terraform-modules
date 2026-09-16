output "trigger_names" {
  description = "Map of trigger key => trigger name."
  value       = { for k, t in google_eventarc_trigger.trigger : k => t.name }
}

output "trigger_ids" {
  description = "Map of trigger key => fully-qualified trigger ID (projects/{project}/locations/{location}/triggers/{name})."
  value       = { for k, t in google_eventarc_trigger.trigger : k => t.id }
}

output "trigger_uids" {
  description = "Map of trigger key => API-assigned unique trigger UUID."
  value       = { for k, t in google_eventarc_trigger.trigger : k => t.uid }
}

output "transport_subscriptions" {
  description = "Map of trigger key => Pub/Sub subscription created by the transport (null when the trigger uses a channel or the API did not report one)."
  value       = { for k, t in google_eventarc_trigger.trigger : k => try(t.transport[0].pubsub[0].subscription, null) }
}
