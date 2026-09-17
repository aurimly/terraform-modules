variable "connections" {
  description = "Map of STACKIT VPN connections keyed by an arbitrary identifier. Each entry creates one IPsec connection on the referenced gateway."
  type = map(object({
    project_id   = string
    gateway_id   = string
    display_name = string
    tunnel1 = object({
      remote_address            = string
      pre_shared_key            = optional(string)
      pre_shared_key_wo         = optional(string)
      pre_shared_key_wo_version = optional(number)
      bgp = optional(object({
        remote_asn = number
      }))
      peering = optional(object({
        local_address  = string
        remote_address = string
      }))
      phase1 = object({
        encryption_algorithms = list(string)
        integrity_algorithms  = list(string)
        dh_groups             = optional(list(string))
        rekey_time            = optional(number)
      })
      phase2 = object({
        encryption_algorithms = list(string)
        integrity_algorithms  = list(string)
        dh_groups             = optional(list(string))
        dpd_action            = optional(string)
        rekey_time            = optional(number)
        start_action          = optional(string)
      })
    })
    tunnel2 = object({
      remote_address            = string
      pre_shared_key            = optional(string)
      pre_shared_key_wo         = optional(string)
      pre_shared_key_wo_version = optional(number)
      bgp = optional(object({
        remote_asn = number
      }))
      peering = optional(object({
        local_address  = string
        remote_address = string
      }))
      phase1 = object({
        encryption_algorithms = list(string)
        integrity_algorithms  = list(string)
        dh_groups             = optional(list(string))
        rekey_time            = optional(number)
      })
      phase2 = object({
        encryption_algorithms = list(string)
        integrity_algorithms  = list(string)
        dh_groups             = optional(list(string))
        dpd_action            = optional(string)
        rekey_time            = optional(number)
        start_action          = optional(string)
      })
    })
    region         = optional(string)
    enabled        = optional(bool)
    labels         = optional(map(string))
    local_subnets  = optional(list(string))
    remote_subnets = optional(list(string))
    static_routes  = optional(list(string))
  }))

  validation {
    condition     = alltrue([for c in var.connections : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", c.project_id))])
    error_message = "project_id must be a UUID."
  }

  validation {
    condition     = alltrue([for c in var.connections : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", c.gateway_id))])
    error_message = "gateway_id must be a UUID."
  }

  validation {
    condition     = alltrue([for c in var.connections : can(regex("^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$", c.display_name))])
    error_message = "display_name must start and end with an alphanumeric character, may contain hyphens, and be 1-63 characters long."
  }

  validation {
    condition = alltrue([for c in var.connections : alltrue(flatten([
      for t in tolist([c.tunnel1, c.tunnel2]) : [
        t.pre_shared_key == null || t.pre_shared_key_wo == null,
        t.pre_shared_key_wo == null || t.pre_shared_key_wo_version != null,
        t.pre_shared_key_wo_version == null || t.pre_shared_key_wo != null,
        t.pre_shared_key_wo_version == null || t.pre_shared_key == null,
        t.pre_shared_key == null || length(t.pre_shared_key) >= 20,
        t.pre_shared_key_wo == null || length(t.pre_shared_key_wo) >= 20,
      ]
    ]))])
    error_message = "pre_shared_key and pre_shared_key_wo are mutually exclusive and both require at least 20 characters; pre_shared_key_wo requires pre_shared_key_wo_version; pre_shared_key_wo_version conflicts with pre_shared_key and requires pre_shared_key_wo."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for t in tolist([c.tunnel1, c.tunnel2]) : can(cidrhost("${t.remote_address}/32", 0)) && can(regex("\\.", t.remote_address))])])
    error_message = "tunnel remote_address must be a valid IPv4 address."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for t in tolist([c.tunnel1, c.tunnel2]) : t.peering == null || alltrue([for a in tolist([t.peering.local_address, t.peering.remote_address]) : can(cidrhost("${a}/32", 0)) && can(regex("\\.", a))])])])
    error_message = "peering.local_address and peering.remote_address must be valid IPv4 addresses."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for t in tolist([c.tunnel1, c.tunnel2]) : t.bgp == null || t.bgp.remote_asn >= 64512 && t.bgp.remote_asn <= 4294967294])])
    error_message = "bgp.remote_asn must be between 64512 and 4294967294 (private ASN range)."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for t in tolist([c.tunnel1, c.tunnel2]) : alltrue([for a in t.phase1.encryption_algorithms : contains(["aes256", "aes128gcm16", "aes256gcm16"], a)])])])
    error_message = "phase1.encryption_algorithms must only contain aes256, aes128gcm16, aes256gcm16."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for t in tolist([c.tunnel1, c.tunnel2]) : alltrue([for a in t.phase1.integrity_algorithms : contains(["sha1", "sha2_256", "sha2_384", "sha2_512"], a)])])])
    error_message = "phase1.integrity_algorithms must only contain sha1, sha2_256, sha2_384, sha2_512."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for t in tolist([c.tunnel1, c.tunnel2]) : t.phase1.dh_groups == null || alltrue([for a in t.phase1.dh_groups : contains(["modp1024", "modp2048", "ecp256", "ecp384", "modp2048s256"], a)])])])
    error_message = "phase1.dh_groups must only contain modp1024, modp2048, ecp256, ecp384, modp2048s256."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for t in tolist([c.tunnel1, c.tunnel2]) : t.phase1.rekey_time == null || t.phase1.rekey_time >= 900 && t.phase1.rekey_time <= 28800])])
    error_message = "phase1.rekey_time must be between 900 and 28800 seconds."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for t in tolist([c.tunnel1, c.tunnel2]) : alltrue([for a in t.phase2.encryption_algorithms : contains(["aes256", "aes128gcm16", "aes256gcm16"], a)])])])
    error_message = "phase2.encryption_algorithms must only contain aes256, aes128gcm16, aes256gcm16."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for t in tolist([c.tunnel1, c.tunnel2]) : alltrue([for a in t.phase2.integrity_algorithms : contains(["sha1", "sha2_256", "sha2_384", "sha2_512"], a)])])])
    error_message = "phase2.integrity_algorithms must only contain sha1, sha2_256, sha2_384, sha2_512."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for t in tolist([c.tunnel1, c.tunnel2]) : t.phase2.dh_groups == null || alltrue([for a in t.phase2.dh_groups : contains(["modp1024", "modp2048", "ecp256", "ecp384", "modp2048s256"], a)])])])
    error_message = "phase2.dh_groups must only contain modp1024, modp2048, ecp256, ecp384, modp2048s256."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for t in tolist([c.tunnel1, c.tunnel2]) : t.phase2.rekey_time == null || t.phase2.rekey_time >= 900 && t.phase2.rekey_time <= 3600])])
    error_message = "phase2.rekey_time must be between 900 and 3600 seconds."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for t in tolist([c.tunnel1, c.tunnel2]) : t.phase2.dpd_action == null || contains(["clear", "restart"], t.phase2.dpd_action)])])
    error_message = "phase2.dpd_action must be one of clear, restart."
  }

  validation {
    condition     = alltrue([for c in var.connections : alltrue([for t in tolist([c.tunnel1, c.tunnel2]) : t.phase2.start_action == null || contains(["none", "start"], t.phase2.start_action)])])
    error_message = "phase2.start_action must be one of none, start."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.local_subnets == null || alltrue([for cidr in c.local_subnets : can(cidrnetmask(cidr)) && can(regex("\\.", cidr))])])
    error_message = "local_subnets entries must be valid IPv4 CIDRs."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.local_subnets == null || (length(c.local_subnets) >= 1 && length(c.local_subnets) <= 100)])
    error_message = "local_subnets must contain between 1 and 100 entries."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.remote_subnets == null || alltrue([for cidr in c.remote_subnets : can(cidrnetmask(cidr)) && can(regex("\\.", cidr))])])
    error_message = "remote_subnets entries must be valid IPv4 CIDRs."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.remote_subnets == null || (length(c.remote_subnets) >= 1 && length(c.remote_subnets) <= 100)])
    error_message = "remote_subnets must contain between 1 and 100 entries."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.static_routes == null || alltrue([for cidr in c.static_routes : can(cidrnetmask(cidr)) && can(regex("\\.", cidr))])])
    error_message = "static_routes entries must be valid IPv4 CIDRs."
  }
}
