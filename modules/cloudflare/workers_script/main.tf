terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

resource "cloudflare_worker" "worker" {
  for_each = var.workers

  account_id = var.account_id
  name       = each.value.name
  logpush    = each.value.logpush
  tags       = each.value.tags
  subdomain  = each.value.subdomain

  tail_consumers = toset([for name in each.value.tail_consumers : { name = name }])
  observability  = each.value.observability
}
