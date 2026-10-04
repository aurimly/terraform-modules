terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.50.0"
    }
  }
}

resource "hcloud_managed_certificate" "managed" {
  for_each = { for k, cert in var.certificates : k => cert if cert.private_key == null }

  name         = each.value.name
  domain_names = each.value.domain_names
  labels       = each.value.labels

  lifecycle {
    create_before_destroy = true
  }
}

resource "hcloud_uploaded_certificate" "uploaded" {
  for_each = { for k, cert in var.certificates : k => cert if cert.private_key != null }

  name        = each.value.name
  private_key = each.value.private_key
  certificate = each.value.certificate
  labels      = each.value.labels

  lifecycle {
    create_before_destroy = true
  }
}
