variable "routers" {
  description = "Map of Cloud Routers to create, keyed by an arbitrary identifier. Omit to reference existing routers by name in the tunnels map. Every entry enables BGP on the router; BGP on the router is required for dynamic routing over the tunnels."
  type = map(object({
    name       = string
    network    = string
    region     = string
    project_id = optional(string)
    bgp = optional(object({
      asn                = number
      advertise_mode     = optional(string, "DEFAULT")
      advertised_groups  = optional(list(string))
      keepalive_interval = optional(number)
      advertised_ip_ranges = optional(list(object({
        range       = string
        description = optional(string)
      })))
    }), { asn : 64512 })
  }))
  default = {}

  validation {
    condition     = alltrue([for r in var.routers : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", r.name))])
    error_message = "name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen (RFC1035)."
  }

  validation {
    condition     = alltrue([for r in var.routers : can(regex("^[a-z]+-[a-z]+[0-9]+$", r.region))])
    error_message = "region must look like a GCP region name (e.g. us-central1, europe-west4); it is a shape check, not a list of valid regions."
  }

  validation {
    condition     = alltrue([for r in var.routers : contains(["DEFAULT", "CUSTOM"], r.bgp.advertise_mode)])
    error_message = "bgp.advertise_mode must be one of DEFAULT or CUSTOM (case-sensitive)."
  }

  validation {
    condition     = alltrue([for r in var.routers : r.bgp.advertise_mode == "CUSTOM" || (r.bgp.advertised_groups == null && r.bgp.advertised_ip_ranges == null)])
    error_message = "bgp.advertised_groups and bgp.advertised_ip_ranges can only be set when bgp.advertise_mode is CUSTOM."
  }

  validation {
    condition     = alltrue([for r in var.routers : r.bgp.advertised_groups == null || alltrue([for g in r.bgp.advertised_groups : g == "ALL_SUBNETS"])])
    error_message = "bgp.advertised_groups currently only supports the value ALL_SUBNETS."
  }

  validation {
    condition     = alltrue([for r in var.routers : r.bgp.asn >= 64512 && r.bgp.asn <= 65534 || r.bgp.asn >= 4200000000 && r.bgp.asn <= 4294967294])
    error_message = "bgp.asn must be a private autonomous system number: 64512-65534 (2-byte) or 4200000000-4294967294 (4-byte) per RFC6996."
  }

  validation {
    condition     = alltrue([for r in var.routers : r.bgp.keepalive_interval == null || (r.bgp.keepalive_interval >= 20 && r.bgp.keepalive_interval <= 60)])
    error_message = "bgp.keepalive_interval must be between 20 and 60 seconds (provider default 20)."
  }

  validation {
    condition     = alltrue([for r in var.routers : r.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", r.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }
}

variable "gateways" {
  description = "Map of HA VPN gateways keyed by an arbitrary identifier. Each entry creates one google_compute_ha_vpn_gateway with two interfaces."
  type = map(object({
    name       = string
    network    = string
    region     = string
    project_id = optional(string)
    stack_type = optional(string, "IPV4_ONLY")
    labels     = optional(map(string))
  }))

  validation {
    condition     = alltrue([for g in var.gateways : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", g.name))])
    error_message = "name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen (RFC1035)."
  }

  validation {
    condition     = alltrue([for g in var.gateways : can(regex("^[a-z]+-[a-z]+[0-9]+$", g.region))])
    error_message = "region must look like a GCP region name (e.g. us-central1, europe-west4); it is a shape check, not a list of valid regions."
  }

  validation {
    condition     = alltrue([for g in var.gateways : contains(["IPV4_ONLY", "IPV4_IPV6", "IPV6_ONLY"], g.stack_type)])
    error_message = "stack_type must be one of IPV4_ONLY, IPV4_IPV6 or IPV6_ONLY (case-sensitive)."
  }

  validation {
    condition     = alltrue([for g in var.gateways : g.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", g.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }
}

variable "external_gateways" {
  description = "Map of peer (external) VPN gateways keyed by an arbitrary identifier. Each entry creates one google_compute_external_vpn_gateway representing the remote side (e.g. an AWS Site-to-Site VPN connection's tunnel outside IP addresses). Omit when peer_gateways are referenced by self link in tunnels."
  type = map(object({
    name            = string
    redundancy_type = string
    project_id      = optional(string)
    description     = optional(string)
    interfaces = optional(list(object({
      id         = number
      ip_address = string
    })), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for g in var.external_gateways : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", g.name))])
    error_message = "name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen (RFC1035)."
  }

  validation {
    condition     = alltrue([for g in var.external_gateways : contains(["SINGLE_IP_INTERNALLY_REDUNDANT", "TWO_IPS_REDUNDANCY", "FOUR_IPS_REDUNDANCY"], g.redundancy_type)])
    error_message = "redundancy_type must be one of SINGLE_IP_INTERNALLY_REDUNDANT, TWO_IPS_REDUNDANCY or FOUR_IPS_REDUNDANCY (case-sensitive)."
  }

  validation {
    condition = alltrue([for g in var.external_gateways :
      jsonencode(sort([for i in g.interfaces : tostring(i.id)])) == jsonencode({ "SINGLE_IP_INTERNALLY_REDUNDANT" = ["0"], "TWO_IPS_REDUNDANCY" = ["0", "1"], "FOUR_IPS_REDUNDANCY" = ["0", "1", "2", "3"] }[g.redundancy_type])
    ])
    error_message = "interface ids must match the redundancy type: SINGLE_IP_INTERNALLY_REDUNDANT allows only 0; TWO_IPS_REDUNDANCY allows 0 and 1; FOUR_IPS_REDUNDANCY allows 0, 1, 2 and 3."
  }

  validation {
    condition     = alltrue([for g in var.external_gateways : g.redundancy_type == "SINGLE_IP_INTERNALLY_REDUNDANT" || length(g.interfaces) > 1])
    error_message = "an AWS HA VPN peer presents two outside addresses, so enter TWO_IPS_REDUNDANCY with two interfaces (interface id 0 and 1) unless the peer really is a single-IP device."
  }

  validation {
    condition     = alltrue([for g in var.external_gateways : alltrue([for i in g.interfaces : can(cidrhost("${i.ip_address}/32", 0))])])
    error_message = "interfaces.ip_address must be a plain IPv4 address (no prefix)."
  }

  validation {
    condition     = alltrue([for g in var.external_gateways : g.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", g.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }
}

variable "tunnels" {
  description = "Map of VPN tunnels keyed by an arbitrary identifier. Each entry creates one google_compute_vpn_tunnel on an HA VPN gateway. Tunnels are regardless keyed individually so each can carry its own secret and selectors: provide one entry per gateway interface, pointing both entries at the same gateway with distinct vpn_gateway_interface values (0 and 1)."
  type = map(object({
    name                            = string
    region                          = string
    gateway                         = string
    router                          = string
    peer_external_gateway           = optional(string)
    peer_external_gateway_interface = optional(number)
    peer_ip                         = optional(string)
    project_id                      = optional(string)
    description                     = optional(string)
    labels                          = optional(map(string))
    shared_secret                   = optional(string)
    shared_secret_wo                = optional(string)
    shared_secret_wo_version        = optional(number)
    ike_version                     = optional(number, 2)
    local_traffic_selector          = optional(list(string))
    remote_traffic_selector         = optional(list(string))
  }))

  validation {
    condition     = alltrue([for t in var.tunnels : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", t.name))])
    error_message = "name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen (RFC1035)."
  }

  validation {
    condition     = alltrue([for t in var.tunnels : can(regex("^[a-z]+-[a-z]+[0-9]+$", t.region))])
    error_message = "region must look like a GCP region name (e.g. us-central1, europe-west4); it is a shape check, not a list of valid regions."
  }

  validation {
    condition     = alltrue([for t in var.tunnels : (t.peer_external_gateway == null) != (t.peer_ip == null)])
    error_message = "exactly one peer source must be set: either peer_external_gateway (a key of external_gateways or an external VPN gateway self link) or peer_ip (the peer gateway's outside address). Set peer_external_gateway and its interface; AWS publishes two outside addresses, one per tunnel."
  }

  validation {
    condition     = alltrue([for t in var.tunnels : t.peer_external_gateway == null || t.peer_external_gateway_interface != null])
    error_message = "peer_external_gateway_interface is required when peer_external_gateway is set: the interface id (0 for TWO_IPS_REDUNDANCY) of the peer gateway this tunnel terminates on. AWS tunnel 1 outside address is interface 0, tunnel 2 is interface 1 when using TWO_IPS_REDUNDANCY."
  }

  validation {
    condition     = alltrue([for t in var.tunnels : contains([1, 2], t.ike_version)])
    error_message = "ike_version must be 1 or 2 (provider default 2; BGP over the tunnel requires IKEv2 pairings consistent with the AWS tunnel spec)."
  }

  validation {
    condition     = alltrue([for t in var.tunnels : (t.shared_secret == null) != (t.shared_secret_wo == null)])
    error_message = "exactly one of shared_secret or shared_secret_wo must be set: the same IKE pre-shared key the peer side uses for this tunnel."
  }

  validation {
    condition     = alltrue([for t in var.tunnels : t.shared_secret_wo == null || t.shared_secret_wo_version != null])
    error_message = "shared_secret_wo_version is required when shared_secret_wo is set; increment it to rotate the write-only secret."
  }

  validation {
    condition     = alltrue([for t in var.tunnels : t.shared_secret_wo_version == null || t.shared_secret_wo != null])
    error_message = "shared_secret_wo_version can only be set when shared_secret_wo is set."
  }

  validation {
    condition     = alltrue([for t in var.tunnels : t.shared_secret == null || can(regex("^\\S{8,64}$", t.shared_secret))])
    error_message = "shared_secret must be 8 to 64 characters with no whitespace; use the exact same PSK value on the AWS tunnel1/tunnel2 entries."
  }

  validation {
    condition     = alltrue([for t in var.tunnels : t.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", t.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }
}

variable "bgp_sessions" {
  description = "Map of BGP sessions to establish over the tunnels, keyed by an arbitrary identifier. Each entry creates a google_compute_router_interface linked to the tunnel (auto-assigned link-local from ip_range when given, otherwise GCP-assigned) and a google_compute_router_peer. Omit for policy-based/static setups."
  type = map(object({
    name                      = string
    tunnel                    = string
    peer_asn                  = number
    ip_range                  = optional(string)
    peer_ip_address           = optional(string)
    advertised_route_priority = optional(number)
    md5_authentication_key = optional(object({
      name = string
      key  = string
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for s in var.bgp_sessions : can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", s.name))])
    error_message = "name must be 1 to 63 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen (RFC1035)."
  }

  validation {
    condition     = alltrue([for s in var.bgp_sessions : s.ip_range == null || (can(cidrnetmask(s.ip_range)) && split("/", s.ip_range)[1] == "30")])
    error_message = "ip_range must be a /30 from the 169.254.0.0/16 link-local range (e.g. 169.254.0.1/30) and must match the AWS tunnel's inside CIDR."
  }

  validation {
    condition     = alltrue([for s in var.bgp_sessions : s.peer_ip_address == null || can(cidrhost("${s.peer_ip_address}/32", 0))])
    error_message = "peer_ip_address must be a plain IPv4 address: the AWS tunnel's vgw_inside_address (the AWS-side host of the inside /30)."
  }

  validation {
    condition     = alltrue([for s in var.bgp_sessions : s.ip_range == null || s.peer_ip_address == null || s.peer_ip_address == cidrhost(s.ip_range, 1) || s.peer_ip_address == cidrhost(s.ip_range, 2)])
    error_message = "peer_ip_address must be one of the two hosts of ip_range (the /30 covers exactly the GCP router interface and the AWS tunnel endpoint); it must differ from the GCP side's own address."
  }

  validation {
    condition     = alltrue([for s in var.bgp_sessions : s.peer_asn >= 1 && s.peer_asn <= 4294967294])
    error_message = "peer_asn must be between 1 and 4294967294; use the AWS side ASN (amazon_side_asn of the VGW/TGW, default 64512)."
  }

  validation {
    condition = alltrue([for s in var.bgp_sessions :
      s.advertised_route_priority == null || (s.advertised_route_priority >= 0 && s.advertised_route_priority <= 65535)
    ])
    error_message = "advertised_route_priority must be between 0 and 65535 (provider default 100)."
  }

  validation {
    condition     = alltrue([for s in var.bgp_sessions : s.md5_authentication_key == null || (can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", s.md5_authentication_key.name)) && can(regex("^\\S{1,80}$", s.md5_authentication_key.key)))])
    error_message = "md5_authentication_key.name must be RFC1035; key must be 1 to 80 printable characters with no whitespace; both must match the AWS tunnel's PSK."
  }
}
