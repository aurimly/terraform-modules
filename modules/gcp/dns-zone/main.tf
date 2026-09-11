resource "google_dns_managed_zone" "zone" {
  for_each = var.zones

  name          = each.value.name
  dns_name      = each.value.dns_name
  project       = each.value.project_id
  description   = each.value.description
  visibility    = each.value.visibility
  force_destroy = each.value.force_destroy
  labels        = each.value.labels

  dynamic "dnssec_config" {
    for_each = each.value.dnssec_config != null ? [each.value.dnssec_config] : []

    content {
      state         = dnssec_config.value.state
      non_existence = dnssec_config.value.non_existence

      dynamic "default_key_specs" {
        for_each = dnssec_config.value.default_key_specs

        content {
          algorithm  = default_key_specs.value.algorithm
          key_length = default_key_specs.value.key_length
          key_type   = default_key_specs.value.key_type
        }
      }
    }
  }

  dynamic "private_visibility_config" {
    for_each = each.value.private_visibility_config != null ? [each.value.private_visibility_config] : []

    content {
      dynamic "networks" {
        for_each = private_visibility_config.value.networks

        content {
          network_url = networks.value.network_url
        }
      }

      dynamic "gke_clusters" {
        for_each = private_visibility_config.value.gke_clusters

        content {
          gke_cluster_name = gke_clusters.value.gke_cluster_name
        }
      }
    }
  }

  dynamic "forwarding_config" {
    for_each = each.value.forwarding_config != null ? [each.value.forwarding_config] : []

    content {
      dynamic "target_name_servers" {
        for_each = forwarding_config.value.target_name_servers

        content {
          ipv4_address    = target_name_servers.value.ipv4_address
          ipv6_address    = target_name_servers.value.ipv6_address
          forwarding_path = target_name_servers.value.forwarding_path
        }
      }
    }
  }

  dynamic "peering_config" {
    for_each = each.value.peering_config != null ? [each.value.peering_config] : []

    content {
      target_network {
        network_url = peering_config.value.target_network.network_url
      }
    }
  }

  dynamic "cloud_logging_config" {
    for_each = each.value.cloud_logging_config != null ? [each.value.cloud_logging_config] : []

    content {
      enable_logging = cloud_logging_config.value.enable_logging
    }
  }
}
