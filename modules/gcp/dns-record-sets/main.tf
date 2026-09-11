resource "google_dns_record_set" "record_set" {
  for_each = var.record_sets

  name         = each.value.name
  type         = each.value.type
  ttl          = each.value.ttl
  managed_zone = var.managed_zone_name
  project      = var.project_id
  rrdatas      = each.value.rrdatas

  dynamic "routing_policy" {
    for_each = each.value.routing_policy != null ? [each.value.routing_policy] : []

    content {
      enable_geo_fencing = routing_policy.value.enable_geo_fencing

      dynamic "wrr" {
        for_each = routing_policy.value.wrr != null ? routing_policy.value.wrr : []

        content {
          weight  = wrr.value.weight
          rrdatas = wrr.value.rrdatas

          dynamic "health_checked_targets" {
            for_each = wrr.value.health_checked_targets != null ? [wrr.value.health_checked_targets] : []

            content {
              external_endpoints = health_checked_targets.value.external_endpoints

              dynamic "internal_load_balancers" {
                for_each = health_checked_targets.value.internal_load_balancers

                content {
                  ip_address         = internal_load_balancers.value.ip_address
                  port               = internal_load_balancers.value.port
                  ip_protocol        = internal_load_balancers.value.ip_protocol
                  load_balancer_type = internal_load_balancers.value.load_balancer_type
                  network_url        = internal_load_balancers.value.network_url
                  project            = internal_load_balancers.value.project
                  region             = internal_load_balancers.value.region
                }
              }
            }
          }
        }
      }

      dynamic "geo" {
        for_each = routing_policy.value.geo != null ? routing_policy.value.geo : []

        content {
          location = geo.value.location
          rrdatas  = geo.value.rrdatas

          dynamic "health_checked_targets" {
            for_each = geo.value.health_checked_targets != null ? [geo.value.health_checked_targets] : []

            content {
              external_endpoints = health_checked_targets.value.external_endpoints

              dynamic "internal_load_balancers" {
                for_each = health_checked_targets.value.internal_load_balancers

                content {
                  ip_address         = internal_load_balancers.value.ip_address
                  port               = internal_load_balancers.value.port
                  ip_protocol        = internal_load_balancers.value.ip_protocol
                  load_balancer_type = internal_load_balancers.value.load_balancer_type
                  network_url        = internal_load_balancers.value.network_url
                  project            = internal_load_balancers.value.project
                  region             = internal_load_balancers.value.region
                }
              }
            }
          }
        }
      }

      dynamic "primary_backup" {
        for_each = routing_policy.value.primary_backup != null ? [routing_policy.value.primary_backup] : []

        content {
          trickle_ratio                  = primary_backup.value.trickle_ratio
          enable_geo_fencing_for_backups = primary_backup.value.enable_geo_fencing_for_backups

          primary {
            external_endpoints = primary_backup.value.primary.external_endpoints

            dynamic "internal_load_balancers" {
              for_each = primary_backup.value.primary.internal_load_balancers

              content {
                ip_address         = internal_load_balancers.value.ip_address
                port               = internal_load_balancers.value.port
                ip_protocol        = internal_load_balancers.value.ip_protocol
                load_balancer_type = internal_load_balancers.value.load_balancer_type
                network_url        = internal_load_balancers.value.network_url
                project            = internal_load_balancers.value.project
                region             = internal_load_balancers.value.region
              }
            }
          }

          dynamic "backup_geo" {
            for_each = primary_backup.value.backup_geo

            content {
              location = backup_geo.value.location
              rrdatas  = backup_geo.value.rrdatas

              dynamic "health_checked_targets" {
                for_each = backup_geo.value.health_checked_targets != null ? [backup_geo.value.health_checked_targets] : []

                content {
                  external_endpoints = health_checked_targets.value.external_endpoints

                  dynamic "internal_load_balancers" {
                    for_each = health_checked_targets.value.internal_load_balancers

                    content {
                      ip_address         = internal_load_balancers.value.ip_address
                      port               = internal_load_balancers.value.port
                      ip_protocol        = internal_load_balancers.value.ip_protocol
                      load_balancer_type = internal_load_balancers.value.load_balancer_type
                      network_url        = internal_load_balancers.value.network_url
                      project            = internal_load_balancers.value.project
                      region             = internal_load_balancers.value.region
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
