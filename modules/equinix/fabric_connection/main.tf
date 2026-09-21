terraform {
  required_providers {
    equinix = {
      source  = "equinix/equinix"
      version = ">= 5.0.0"
    }
  }
}

resource "equinix_fabric_connection" "connection" {
  for_each = var.connections

  name        = each.value.name
  type        = each.value.type
  bandwidth   = each.value.bandwidth
  description = each.value.description
  geo_scope   = each.value.geo_scope

  dynamic "notifications" {
    for_each = each.value.notifications

    content {
      type          = notifications.value.type
      emails        = notifications.value.emails
      send_interval = notifications.value.send_interval
    }
  }

  additional_info = each.value.additional_info

  dynamic "order" {
    for_each = each.value.order != null ? [each.value.order] : []

    content {
      purchase_order_number = order.value.purchase_order_number
      order_number          = order.value.order_number
      order_id              = order.value.order_id
      billing_tier          = order.value.billing_tier
      term_length           = order.value.term_length
    }
  }

  dynamic "project" {
    for_each = each.value.project != null ? [each.value.project] : []

    content {
      project_id = project.value.project_id
    }
  }

  dynamic "redundancy" {
    for_each = each.value.redundancy != null ? [each.value.redundancy] : []

    content {
      priority = redundancy.value.priority
      group    = redundancy.value.group
    }
  }

  a_side {
    dynamic "access_point" {
      for_each = each.value.a_side.access_point != null ? [each.value.a_side.access_point] : []

      content {
        type               = access_point.value.type
        authentication_key = access_point.value.authentication_key
        seller_region      = access_point.value.seller_region
        peering_type       = access_point.value.peering_type
        role               = access_point.value.role

        dynamic "port" {
          for_each = access_point.value.port != null ? [access_point.value.port] : []

          content {
            uuid = port.value.uuid
          }
        }

        dynamic "router" {
          for_each = access_point.value.router != null ? [access_point.value.router] : []

          content {
            uuid = router.value.uuid
          }
        }

        dynamic "network" {
          for_each = access_point.value.network != null ? [access_point.value.network] : []

          content {
            uuid = network.value.uuid
          }
        }

        dynamic "profile" {
          for_each = access_point.value.profile != null ? [access_point.value.profile] : []

          content {
            type = profile.value.type
            uuid = profile.value.uuid
          }
        }

        dynamic "virtual_device" {
          for_each = access_point.value.virtual_device != null ? [access_point.value.virtual_device] : []

          content {
            uuid = virtual_device.value.uuid
            type = virtual_device.value.type
            name = virtual_device.value.name
          }
        }

        dynamic "interface" {
          for_each = access_point.value.interface != null ? [access_point.value.interface] : []

          content {
            id   = interface.value.id
            type = interface.value.type
            uuid = interface.value.uuid
          }
        }

        dynamic "link_protocol" {
          for_each = access_point.value.link_protocol != null ? [access_point.value.link_protocol] : []

          content {
            type       = link_protocol.value.type
            vlan_tag   = link_protocol.value.vlan_tag
            vlan_s_tag = link_protocol.value.vlan_s_tag
            vlan_c_tag = link_protocol.value.vlan_c_tag
          }
        }

        dynamic "location" {
          for_each = access_point.value.location != null ? [access_point.value.location] : []

          content {
            metro_code = location.value.metro_code
            ibx        = location.value.ibx
            metro_name = location.value.metro_name
            region     = location.value.region
          }
        }
      }
    }

    dynamic "service_token" {
      for_each = each.value.a_side.service_token != null ? [each.value.a_side.service_token] : []

      content {
        uuid = service_token.value.uuid
        type = service_token.value.type
      }
    }

    dynamic "additional_info" {
      for_each = each.value.a_side.additional_info != null ? each.value.a_side.additional_info : []

      content {
        key   = additional_info.value.key
        value = additional_info.value.value
      }
    }
  }

  z_side {
    dynamic "access_point" {
      for_each = each.value.z_side.access_point != null ? [each.value.z_side.access_point] : []

      content {
        type               = access_point.value.type
        authentication_key = access_point.value.authentication_key
        seller_region      = access_point.value.seller_region
        peering_type       = access_point.value.peering_type
        role               = access_point.value.role

        dynamic "port" {
          for_each = access_point.value.port != null ? [access_point.value.port] : []

          content {
            uuid = port.value.uuid
          }
        }

        dynamic "router" {
          for_each = access_point.value.router != null ? [access_point.value.router] : []

          content {
            uuid = router.value.uuid
          }
        }

        dynamic "network" {
          for_each = access_point.value.network != null ? [access_point.value.network] : []

          content {
            uuid = network.value.uuid
          }
        }

        dynamic "profile" {
          for_each = access_point.value.profile != null ? [access_point.value.profile] : []

          content {
            type = profile.value.type
            uuid = profile.value.uuid
          }
        }

        dynamic "virtual_device" {
          for_each = access_point.value.virtual_device != null ? [access_point.value.virtual_device] : []

          content {
            uuid = virtual_device.value.uuid
            type = virtual_device.value.type
            name = virtual_device.value.name
          }
        }

        dynamic "interface" {
          for_each = access_point.value.interface != null ? [access_point.value.interface] : []

          content {
            id   = interface.value.id
            type = interface.value.type
            uuid = interface.value.uuid
          }
        }

        dynamic "link_protocol" {
          for_each = access_point.value.link_protocol != null ? [access_point.value.link_protocol] : []

          content {
            type       = link_protocol.value.type
            vlan_tag   = link_protocol.value.vlan_tag
            vlan_s_tag = link_protocol.value.vlan_s_tag
            vlan_c_tag = link_protocol.value.vlan_c_tag
          }
        }

        dynamic "location" {
          for_each = access_point.value.location != null ? [access_point.value.location] : []

          content {
            metro_code = location.value.metro_code
            ibx        = location.value.ibx
            metro_name = location.value.metro_name
            region     = location.value.region
          }
        }
      }
    }

    dynamic "service_token" {
      for_each = each.value.z_side.service_token != null ? [each.value.z_side.service_token] : []

      content {
        uuid = service_token.value.uuid
        type = service_token.value.type
      }
    }

    dynamic "additional_info" {
      for_each = each.value.z_side.additional_info != null ? each.value.z_side.additional_info : []

      content {
        key   = additional_info.value.key
        value = additional_info.value.value
      }
    }
  }
}
