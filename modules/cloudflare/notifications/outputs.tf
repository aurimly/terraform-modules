output "policy_ids" {
  description = "Map of policy key => policy ID (UUID; also part of the import ID together with the account ID)."
  value       = { for k, p in cloudflare_notification_policy.policies : k => p.id }
}

output "webhook_ids" {
  description = "Map of webhook key => webhook destination ID (UUID; referenced by policies consumer-side and part of the import ID)."
  value       = { for k, w in cloudflare_notification_policy_webhooks.webhooks : k => w.id }
}

output "webhook_types" {
  description = "Map of webhook key => inferred webhook type (datadog, discord, feishu, gchat, generic, opsgenie, slack, splunk). The type is computed by the API from the URL — it is not an input."
  value       = { for k, w in cloudflare_notification_policy_webhooks.webhooks : k => w.type }
}
