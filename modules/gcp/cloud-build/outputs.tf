output "trigger_names" {
  description = "Map of trigger key => trigger name."
  value       = { for k, t in google_cloudbuild_trigger.trigger : k => t.name }
}

output "trigger_ids" {
  description = "Map of trigger key => fully-qualified trigger ID (projects/{project}/locations/{location}/triggers/{trigger_id})."
  value       = { for k, t in google_cloudbuild_trigger.trigger : k => t.id }
}

output "trigger_numeric_ids" {
  description = "Map of trigger key => API-generated unique trigger ID."
  value       = { for k, t in google_cloudbuild_trigger.trigger : k => t.trigger_id }
}

output "trigger_self_links" {
  description = "Map of trigger key => fully-qualified trigger identity (projects/{project}/locations/{location}/triggers/{name})."
  value       = { for k, t in google_cloudbuild_trigger.trigger : k => "projects/${t.project}/locations/${t.location}/triggers/${t.name}" }
}

output "pubsub_subscriptions" {
  description = "Map of trigger key => Pub/Sub subscription created for pubsub_config triggers (null otherwise)."
  value       = { for k, t in google_cloudbuild_trigger.trigger : k => try(t.pubsub_config[0].subscription, null) }
}
