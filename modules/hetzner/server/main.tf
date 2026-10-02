terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.50.0"
    }
  }
}

resource "hcloud_server" "server" {
  for_each = var.servers

  name                       = each.value.name
  server_type                = each.value.server_type
  image                      = each.value.image
  location                   = each.value.location
  user_data                  = each.value.user_data
  ssh_keys                   = each.value.ssh_keys
  keep_disk                  = each.value.keep_disk
  backups                    = each.value.backups
  labels                     = each.value.labels
  firewall_ids               = each.value.firewall_ids
  ignore_remote_firewall_ids = each.value.ignore_remote_firewall_ids
  placement_group_id         = each.value.placement_group_id
  delete_protection          = each.value.delete_protection
  rebuild_protection         = each.value.rebuild_protection
  shutdown_before_deletion   = each.value.shutdown_before_deletion
  iso                        = each.value.iso
  rescue                     = each.value.rescue

  dynamic "public_net" {
    for_each = each.value.public_net != null ? [each.value.public_net] : []

    content {
      ipv4_enabled = public_net.value.ipv4_enabled
      ipv6_enabled = public_net.value.ipv6_enabled
      ipv4         = public_net.value.ipv4
      ipv6         = public_net.value.ipv6
    }
  }

  dynamic "network" {
    for_each = each.value.network

    content {
      network_id = network.value.network_id
      subnet_id  = network.value.subnet_id
      ip         = network.value.ip
      alias_ips  = network.value.alias_ips
    }
  }
}
