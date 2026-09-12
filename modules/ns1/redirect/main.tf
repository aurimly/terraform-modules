terraform {
  required_providers {
    ns1 = {
      source  = "ns1-terraform/ns1"
      version = ">= 2.0.0"
    }
  }
}

resource "ns1_redirect" "redirect" {
  for_each = var.redirects

  domain           = each.value.domain
  path             = each.value.path
  target           = each.value.target
  forwarding_type  = each.value.forwarding_type
  forwarding_mode  = each.value.forwarding_mode
  https_forced     = each.value.https_forced
  query_forwarding = each.value.query_forwarding
  tags             = each.value.tags
  certificate_id   = each.value.certificate_id
}
