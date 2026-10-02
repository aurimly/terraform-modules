terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.50.0"
    }
  }
}

resource "hcloud_ssh_key" "ssh_key" {
  for_each = var.ssh_keys

  name       = each.value.name
  public_key = each.value.public_key
  labels     = each.value.labels
}
