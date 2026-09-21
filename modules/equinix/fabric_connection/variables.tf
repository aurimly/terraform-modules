variable "connections" {
  description = "Map of Equinix Fabric connections keyed by an arbitrary unique identifier. Each entry creates one equinix_fabric_connection. A side either sets access_point or service_token; SP access points need profile and authentication_key, CLOUD_ROUTER access points need router, VD access points need virtual_device and interface."
  type = map(object({
    name        = string
    type        = string # EVPL_VC, EPL_VC, IPWAN_VC, IP_VC, ACCESS_EPL_VC, EVPLAN_VC, EPLAN_VC, EIA_VC, IA_VC, EC_VC
    bandwidth   = number # Mbps
    description = optional(string)
    geo_scope   = optional(string)

    notifications = list(object({
      type          = string # ALL, CONNECTION_APPROVAL, SALES_REP_NOTIFICATIONS, NOTIFICATIONS
      emails        = list(string)
      send_interval = optional(string)
    }))

    additional_info = optional(list(object({
      key   = string
      value = string
    })), [])

    order = optional(object({
      purchase_order_number = optional(string)
      order_number          = optional(string)
      order_id              = optional(string)
      billing_tier          = optional(string)
      term_length           = optional(number) # 1, 12, 24, 36
    }))

    project = optional(object({
      project_id = optional(string)
    }))

    redundancy = optional(object({
      priority = string # PRIMARY, SECONDARY (Azure redundant connections)
      group    = optional(string)
    }))

    a_side = object({
      access_point = optional(object({
        type               = optional(string) # COLO, VD, VG, SP, IGW, SUBNET, CLOUD_ROUTER, NETWORK, METAL_NETWORK
        authentication_key = optional(string)
        seller_region      = optional(string)
        peering_type       = optional(string) # PRIVATE, MICROSOFT, PUBLIC, MANUAL
        role               = optional(string)
        port = optional(object({
          uuid = string
        }))
        router = optional(object({
          uuid = string
        }))
        network = optional(object({
          uuid = string
        }))
        profile = optional(object({
          type = string # L2_PROFILE, L3_PROFILE, ECIA_PROFILE, ECMC_PROFILE, IA_PROFILE
          uuid = string
        }))
        virtual_device = optional(object({
          uuid = string
          type = optional(string) # e.g. EDGE
          name = optional(string)
        }))
        interface = optional(object({
          id   = optional(number)
          type = optional(string) # NETWORK, CLOUD
          uuid = optional(string)
        }))
        link_protocol = optional(object({
          type       = optional(string) # UNTAGGED, DOT1Q, QINQ, EVPN_VXLAN
          vlan_tag   = optional(number) # DOT1Q
          vlan_s_tag = optional(number) # QINQ
          vlan_c_tag = optional(number) # QINQ
        }))
        location = optional(object({
          metro_code = optional(string)
          ibx        = optional(string)
          metro_name = optional(string)
          region     = optional(string)
        }))
      }))
      service_token = optional(object({
        uuid = string
        type = optional(string) # VC_TOKEN
      }))
      additional_info = optional(list(object({
        key   = string
        value = string
      })), [])
    })

    z_side = object({
      access_point = optional(object({
        type               = optional(string) # COLO, VD, VG, SP, IGW, SUBNET, CLOUD_ROUTER, NETWORK, METAL_NETWORK
        authentication_key = optional(string)
        seller_region      = optional(string)
        peering_type       = optional(string) # PRIVATE, MICROSOFT, PUBLIC, MANUAL
        role               = optional(string)
        port = optional(object({
          uuid = string
        }))
        router = optional(object({
          uuid = string
        }))
        network = optional(object({
          uuid = string
        }))
        profile = optional(object({
          type = string # L2_PROFILE, L3_PROFILE, ECIA_PROFILE, ECMC_PROFILE, IA_PROFILE
          uuid = string
        }))
        virtual_device = optional(object({
          uuid = string
          type = optional(string) # e.g. EDGE
          name = optional(string)
        }))
        interface = optional(object({
          id   = optional(number)
          type = optional(string) # NETWORK, CLOUD
          uuid = optional(string)
        }))
        link_protocol = optional(object({
          type       = optional(string) # UNTAGGED, DOT1Q, QINQ, EVPN_VXLAN
          vlan_tag   = optional(number) # DOT1Q
          vlan_s_tag = optional(number) # QINQ
          vlan_c_tag = optional(number) # QINQ
        }))
        location = optional(object({
          metro_code = optional(string)
          ibx        = optional(string)
          metro_name = optional(string)
          region     = optional(string)
        }))
      }))
      service_token = optional(object({
        uuid = string
        type = optional(string) # VC_TOKEN
      }))
      additional_info = optional(list(object({
        key   = string
        value = string
      })), [])
    })
  }))

  validation {
    condition     = alltrue([for c in var.connections : can(regex("^[a-zA-Z0-9_-]{1,24}$", c.name))])
    error_message = "name must be 1 to 24 characters, letters, digits, hyphens or underscores only."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.bandwidth > 0])
    error_message = "bandwidth must be greater than 0."
  }

  validation {
    condition     = alltrue([for c in var.connections : length(c.notifications) > 0 && alltrue([for n in c.notifications : length(n.emails) > 0])])
    error_message = "notifications must contain at least one entry and every notifications[].emails must contain at least one email address."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.order == null || c.order.term_length == null || contains([1, 12, 24, 36], c.order.term_length)])
    error_message = "order.term_length must be one of 1, 12, 24 or 36 (months)."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.redundancy == null || contains(["PRIMARY", "SECONDARY"], c.redundancy.priority)])
    error_message = "redundancy.priority must be PRIMARY or SECONDARY (case-sensitive)."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for n in c.notifications : contains(["ALL", "CONNECTION_APPROVAL", "SALES_REP_NOTIFICATIONS", "NOTIFICATIONS"], n.type)])])
    error_message = "notifications[].type must be one of ALL, CONNECTION_APPROVAL, SALES_REP_NOTIFICATIONS or NOTIFICATIONS (case-sensitive)."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for n in c.notifications : alltrue([for e in n.emails : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", e))])])])
    error_message = "notifications[].emails entries must look like email addresses."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for side in [c.a_side, c.z_side] : side.access_point == null || side.access_point.type == null || contains(["COLO", "VD", "VG", "SP", "IGW", "SUBNET", "CLOUD_ROUTER", "NETWORK", "METAL_NETWORK"], side.access_point.type)])])
    error_message = "access_point.type must be one of COLO, VD, VG, SP, IGW, SUBNET, CLOUD_ROUTER, NETWORK or METAL_NETWORK (case-sensitive)."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for side in [c.a_side, c.z_side] : side.access_point == null || side.access_point.peering_type == null || contains(["PRIVATE", "MICROSOFT", "PUBLIC", "MANUAL"], side.access_point.peering_type)])])
    error_message = "access_point.peering_type must be one of PRIVATE, MICROSOFT, PUBLIC or MANUAL (case-sensitive)."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for side in [c.a_side, c.z_side] : side.access_point == null || side.access_point.profile == null || contains(["L2_PROFILE", "L3_PROFILE", "ECIA_PROFILE", "ECMC_PROFILE", "IA_PROFILE"], side.access_point.profile.type)])])
    error_message = "access_point.profile.type must be one of L2_PROFILE, L3_PROFILE, ECIA_PROFILE, ECMC_PROFILE or IA_PROFILE (case-sensitive)."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for side in [c.a_side, c.z_side] : side.access_point == null || side.access_point.link_protocol == null || side.access_point.link_protocol.type == null || contains(["UNTAGGED", "DOT1Q", "QINQ", "EVPN_VXLAN"], side.access_point.link_protocol.type)])])
    error_message = "access_point.link_protocol.type must be one of UNTAGGED, DOT1Q, QINQ or EVPN_VXLAN (case-sensitive)."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for side in [c.a_side, c.z_side] : side.service_token == null || side.service_token.type == null || side.service_token.type == "VC_TOKEN"])])
    error_message = "service_token.type must be VC_TOKEN (case-sensitive)."
  }
}
