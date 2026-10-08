terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

resource "cloudflare_origin_ca_certificate" "certificate" {
  for_each = var.certificates

  csr                = each.value.csr
  hostnames          = each.value.hostnames
  request_type       = each.value.request_type
  requested_validity = each.value.requested_validity
}
