variable "service_tokens" {
  description = "Map of Equinix Fabric service tokens keyed by an arbitrary unique identifier. Each entry creates one equinix_fabric_service_token. The module requires exactly one of connection.a_side or connection.z_side — the issuing side of the token."
  type = map(object({
    type        = string # VC_TOKEN, EPL_TOKEN
    name        = optional(string)
    description = optional(string)
    # RFC3339 timestamp, e.g. 2026-06-18T06:43:49.981Z
    expiration_date_time = string

    notifications = list(object({
      type          = string # ALL, CONNECTION_APPROVAL, SALES_REP_NOTIFICATIONS, NOTIFICATIONS
      emails        = list(string)
      send_interval = optional(string)
    }))

    project = optional(object({
      project_id = optional(string)
    }))

    connection = object({
      type = string # EVPL_VC, EVPLAN_VC, EPLAN_VC, IPWAN_VC
      # Mbps, upstream accepts 1-100000
      bandwidth_limit         = optional(number)
      supported_bandwidths    = optional(list(number))
      allow_custom_bandwidth  = optional(bool)
      allow_remote_connection = optional(bool)

      a_side = optional(object({
        access_point_selectors = list(object({
          type = string # COLO, VD, NETWORK
          port = optional(object({
            uuid = string
            type = optional(string)
          }))
          virtual_device = optional(object({
            uuid = string
            type = optional(string)
          }))
          network = optional(object({
            uuid = string
          }))
          interface = optional(object({
            type = string
          }))
          link_protocol = optional(object({
            type       = optional(string) # UNTAGGED, DOT1Q, QINQ, EVPN_VXLAN
            vlan_tag   = optional(number) # DOT1Q
            vlan_s_tag = optional(number) # QINQ
            vlan_c_tag = optional(number) # QINQ
          }))
        }))
      }))
      z_side = optional(object({
        access_point_selectors = list(object({
          type = string # COLO, VD, NETWORK
          port = optional(object({
            uuid = string
            type = optional(string)
          }))
          virtual_device = optional(object({
            uuid = string
            type = optional(string)
          }))
          network = optional(object({
            uuid = string
          }))
          interface = optional(object({
            type = string
          }))
          link_protocol = optional(object({
            type       = optional(string) # UNTAGGED, DOT1Q, QINQ, EVPN_VXLAN
            vlan_tag   = optional(number) # DOT1Q
            vlan_s_tag = optional(number) # QINQ
            vlan_c_tag = optional(number) # QINQ
          }))
        }))
      }))
    })
  }))

  validation {
    condition     = alltrue([for t in var.service_tokens : contains(["VC_TOKEN", "EPL_TOKEN"], t.type)])
    error_message = "type must be VC_TOKEN or EPL_TOKEN (case-sensitive)."
  }

  validation {
    condition     = alltrue([for t in var.service_tokens : can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d+)?(Z|[+-]\\d{2}:\\d{2})$", t.expiration_date_time))])
    error_message = "expiration_date_time must be an RFC3339 timestamp (e.g. 2026-06-18T06:43:49.981Z)."
  }

  validation {
    condition     = alltrue([for t in var.service_tokens : length(t.notifications) > 0 && alltrue([for n in t.notifications : length(n.emails) > 0])])
    error_message = "notifications must contain at least one entry and every notifications[].emails must contain at least one email address."
  }

  validation {
    condition     = alltrue([for t in var.service_tokens : alltrue([for n in t.notifications : contains(["ALL", "CONNECTION_APPROVAL", "SALES_REP_NOTIFICATIONS", "NOTIFICATIONS"], n.type)])])
    error_message = "notifications[].type must be one of ALL, CONNECTION_APPROVAL, SALES_REP_NOTIFICATIONS or NOTIFICATIONS (case-sensitive)."
  }

  validation {
    condition     = alltrue([for t in var.service_tokens : alltrue([for n in t.notifications : alltrue([for e in n.emails : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", e))])])])
    error_message = "notifications[].emails entries must look like email addresses."
  }

  validation {
    condition     = alltrue([for t in var.service_tokens : contains(["EVPL_VC", "EVPLAN_VC", "EPLAN_VC", "IPWAN_VC"], t.connection.type)])
    error_message = "connection.type must be one of EVPL_VC, EVPLAN_VC, EPLAN_VC or IPWAN_VC (case-sensitive)."
  }

  validation {
    condition     = alltrue([for t in var.service_tokens : t.connection.bandwidth_limit == null || (t.connection.bandwidth_limit >= 1 && t.connection.bandwidth_limit <= 100000)])
    error_message = "connection.bandwidth_limit must be between 1 and 100000 Mbps."
  }

  validation {
    condition     = alltrue([for t in var.service_tokens : (t.connection.a_side != null) != (t.connection.z_side != null)])
    error_message = "exactly one of connection.a_side or connection.z_side must be set — the token is issued on that side."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.service_tokens : [
        for side in [t.connection.a_side, t.connection.z_side] : side == null ? [] : [
          for s in side.access_point_selectors : contains(["COLO", "VD", "NETWORK"], s.type)
        ]
      ]
    ]))
    error_message = "access_point_selectors[].type must be one of COLO, VD or NETWORK (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.service_tokens : [
        for side in [t.connection.a_side, t.connection.z_side] : side == null ? [] : [
          for s in side.access_point_selectors : (
            (s.type == "COLO" && s.port != null) ||
            (s.type == "VD" && s.virtual_device != null) ||
            (s.type == "NETWORK" && s.network != null)
          )
        ]
      ]
    ]))
    error_message = "access_point_selectors[] must carry the endpoint matching its type: COLO needs port, VD needs virtual_device, NETWORK needs network."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.service_tokens : [
        for side in [t.connection.a_side, t.connection.z_side] : side == null ? [] : [
          for s in side.access_point_selectors : s.link_protocol == null || s.link_protocol.type == null || contains(["UNTAGGED", "DOT1Q", "QINQ", "EVPN_VXLAN"], s.link_protocol.type)
        ]
      ]
    ]))
    error_message = "access_point_selectors[].link_protocol.type must be one of UNTAGGED, DOT1Q, QINQ or EVPN_VXLAN (case-sensitive)."
  }

  validation {
    condition = alltrue(flatten([
      for t in var.service_tokens : [
        for side in [t.connection.a_side, t.connection.z_side] : side == null ? [] : [
          for s in side.access_point_selectors : s.link_protocol == null || s.link_protocol.type == null || (
            (s.link_protocol.type == "DOT1Q" && s.link_protocol.vlan_tag != null) ||
            (s.link_protocol.type == "QINQ" && s.link_protocol.vlan_s_tag != null && s.link_protocol.vlan_c_tag != null) ||
            contains(["UNTAGGED", "EVPN_VXLAN"], s.link_protocol.type)
          )
        ]
      ]
    ]))
    error_message = "link_protocol.type DOT1Q requires vlan_tag; QINQ requires vlan_s_tag and vlan_c_tag."
  }
}
