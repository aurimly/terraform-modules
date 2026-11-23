terraform {
  required_providers {
    equinix = {
      source  = "equinix/equinix"
      version = ">= 5.0.0"
    }
  }
}

resource "equinix_fabric_service_token" "service_token" {
  for_each = var.service_tokens

  name        = each.value.name
  type        = each.value.type
  description = each.value.description

  expiration_date_time = each.value.expiration_date_time

  dynamic "notifications" {
    for_each = each.value.notifications

    content {
      type          = notifications.value.type
      emails        = notifications.value.emails
      send_interval = notifications.value.send_interval
    }
  }

  dynamic "project" {
    for_each = each.value.project != null ? [each.value.project] : []

    content {
      project_id = project.value.project_id
    }
  }

  service_token_connection {
    type                    = each.value.connection.type
    bandwidth_limit         = each.value.connection.bandwidth_limit
    supported_bandwidths    = each.value.connection.supported_bandwidths
    allow_custom_bandwidth  = each.value.connection.allow_custom_bandwidth
    allow_remote_connection = each.value.connection.allow_remote_connection

    dynamic "a_side" {
      for_each = each.value.connection.a_side != null ? [each.value.connection.a_side] : []

      content {
        dynamic "access_point_selectors" {
          for_each = a_side.value.access_point_selectors

          content {
            type = access_point_selectors.value.type

            dynamic "port" {
              for_each = access_point_selectors.value.port != null ? [access_point_selectors.value.port] : []

              content {
                uuid = port.value.uuid
                type = port.value.type
              }
            }

            dynamic "virtual_device" {
              for_each = access_point_selectors.value.virtual_device != null ? [access_point_selectors.value.virtual_device] : []

              content {
                uuid = virtual_device.value.uuid
                type = virtual_device.value.type
              }
            }

            dynamic "network" {
              for_each = access_point_selectors.value.network != null ? [access_point_selectors.value.network] : []

              content {
                uuid = network.value.uuid
              }
            }

            dynamic "interface" {
              for_each = access_point_selectors.value.interface != null ? [access_point_selectors.value.interface] : []

              content {
                type = interface.value.type
              }
            }

            dynamic "link_protocol" {
              for_each = access_point_selectors.value.link_protocol != null ? [access_point_selectors.value.link_protocol] : []

              content {
                type       = link_protocol.value.type
                vlan_tag   = link_protocol.value.vlan_tag
                vlan_s_tag = link_protocol.value.vlan_s_tag
                vlan_c_tag = link_protocol.value.vlan_c_tag
              }
            }
          }
        }
      }
    }

    dynamic "z_side" {
      for_each = each.value.connection.z_side != null ? [each.value.connection.z_side] : []

      content {
        dynamic "access_point_selectors" {
          for_each = z_side.value.access_point_selectors

          content {
            type = access_point_selectors.value.type

            dynamic "port" {
              for_each = access_point_selectors.value.port != null ? [access_point_selectors.value.port] : []

              content {
                uuid = port.value.uuid
                type = port.value.type
              }
            }

            dynamic "virtual_device" {
              for_each = access_point_selectors.value.virtual_device != null ? [access_point_selectors.value.virtual_device] : []

              content {
                uuid = virtual_device.value.uuid
                type = virtual_device.value.type
              }
            }

            dynamic "network" {
              for_each = access_point_selectors.value.network != null ? [access_point_selectors.value.network] : []

              content {
                uuid = network.value.uuid
              }
            }

            dynamic "interface" {
              for_each = access_point_selectors.value.interface != null ? [access_point_selectors.value.interface] : []

              content {
                type = interface.value.type
              }
            }

            dynamic "link_protocol" {
              for_each = access_point_selectors.value.link_protocol != null ? [access_point_selectors.value.link_protocol] : []

              content {
                type       = link_protocol.value.type
                vlan_tag   = link_protocol.value.vlan_tag
                vlan_s_tag = link_protocol.value.vlan_s_tag
                vlan_c_tag = link_protocol.value.vlan_c_tag
              }
            }
          }
        }
      }
    }
  }
}
