terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

locals {
  mechanisms = {
    for k, p in var.policies : k => {
      email     = p.mechanisms.email != null ? [for id in p.mechanisms.email : { id = id }] : null
      pagerduty = p.mechanisms.pagerduty != null ? [for id in p.mechanisms.pagerduty : { id = id }] : null
      webhooks  = p.mechanisms.webhooks != null ? [for k2 in p.mechanisms.webhooks : { id = try(cloudflare_notification_policy_webhooks.webhooks[k2].id, "invalid-webhook-key-${k2}") }] : null
    }
  }
}

resource "cloudflare_notification_policy_webhooks" "webhooks" {
  for_each = var.webhooks

  account_id = var.account_id
  name       = each.value.name
  url        = each.value.url
  secret     = each.value.secret
}

resource "cloudflare_notification_policy" "policies" {
  for_each = var.policies

  account_id     = var.account_id
  name           = each.value.name
  description    = each.value.description
  enabled        = each.value.enabled
  alert_type     = each.value.alert_type
  alert_interval = each.value.alert_interval
  filters        = each.value.filters
  mechanisms     = local.mechanisms[each.key]

  lifecycle {
    precondition {
      condition = alltrue([
        for p in var.policies :
        alltrue([
          for k in(p.mechanisms.webhooks != null ? p.mechanisms.webhooks : []) :
          contains(keys(var.webhooks), k)
        ])
      ])
      error_message = "mechanisms.webhooks entries must be keys of the webhooks map (module-managed webhook destinations)."
    }
  }
}
