variable "vpn_gateways" {
  description = "Map of Virtual Private Gateways to create and attach to a VPC, keyed by an arbitrary identifier. Omit when connections attach to an existing VGW by id or a Transit Gateway. One VGW serves all connections referencing it."
  type = map(object({
    name              = string
    vpc_id            = string
    amazon_side_asn   = optional(number, 64512)
    availability_zone = optional(string)
    tags              = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for g in var.vpn_gateways : length(g.name) <= 255])
    error_message = "name is the Name tag value; it must be at most 255 characters."
  }

  validation {
    condition     = alltrue([for g in var.vpn_gateways : g.amazon_side_asn >= 64512 && g.amazon_side_asn <= 65534 || g.amazon_side_asn >= 4200000000 && g.amazon_side_asn <= 4294967294])
    error_message = "amazon_side_asn must be a private autonomous system number: 64512-65534 (2-byte) or 4200000000-4294967294 (4-byte) per RFC6996; default 64512."
  }

  validation {
    condition     = alltrue([for g in var.vpn_gateways : can(regex("^vpc-[0-9a-f]{8,17}$", g.vpc_id))])
    error_message = "vpc_id must be a VPC ID (vpc-...), typically dependency.vpc.outputs.vpc_ids[\"main\"] with the aws/vpc module."
  }

  validation {
    condition     = alltrue([for g in var.vpn_gateways : g.availability_zone == null || can(regex("^[a-z]{2,3}-[a-z]+-[0-9][a-z]$", g.availability_zone))])
    error_message = "availability_zone must look like an AZ name (e.g. us-east-1a); it is a shape check, not a list of valid AZs."
  }
}

variable "customer_gateways" {
  description = "Map of Customer Gateways keyed by an arbitrary identifier. Each entry represents the remote side of a connection (for GCP, the HA VPN gateway: one customer gateway per HA VPN gateway, ip_address = an interface address, but see the README — AWS accepts one outside address per customer gateway; for two-tunnel HA use the GCP-side tunnel entries pointing at both)."
  type = map(object({
    name            = string
    bgp_asn         = number
    ip_address      = string
    device_name     = optional(string)
    certificate_arn = optional(string)
    tags            = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for g in var.customer_gateways : length(g.name) <= 255])
    error_message = "name is the Name tag value; it must be at most 255 characters."
  }

  validation {
    condition     = alltrue([for g in var.customer_gateways : g.bgp_asn >= 1 && g.bgp_asn <= 4294967295])
    error_message = "bgp_asn must be between 1 and 4294967295; this is the remote gateway's ASN (GCP Cloud Router BGP ASN; default 64512)."
  }

  validation {
    condition     = alltrue([for g in var.customer_gateways : can(cidrhost("${g.ip_address}/32", 0))])
    error_message = "ip_address must be a plain IPv4 address: the remote gateway's outside address (for GCP HA VPN, one of the two vpn_gateway_addresses output addresses)."
  }
}

variable "connections" {
  description = "Map of Site-to-Site VPN connections keyed by an arbitrary identifier. Each entry creates one aws_vpn_connection between a customer gateway and an attachment (VGW or Transit Gateway), with per-tunnel options. Tunnels 1 and 2 map to the two links on the peer side."
  type = map(object({
    customer_gateway         = string
    transit_gateway_id       = optional(string)
    vpn_gateway              = optional(string)
    static_routes_only       = optional(bool, false)
    static_routes            = optional(list(string), [])
    enable_acceleration      = optional(bool)
    tunnel_inside_ip_version = optional(string, "ipv4")
    local_ipv4_network_cidr  = optional(string, "0.0.0.0/0")
    remote_ipv4_network_cidr = optional(string, "0.0.0.0/0")
    tunnel1 = optional(object({
      inside_cidr                  = optional(string)
      pre_shared_key               = optional(string)
      ike_versions                 = optional(list(string))
      dpd_timeout_action           = optional(string, "clear")
      dpd_timeout_seconds          = optional(number, 30)
      phase1_dh_group_numbers      = optional(list(number))
      phase1_encryption_algorithms = optional(list(string))
      phase1_integrity_algorithms  = optional(list(string))
      phase1_lifetime_seconds      = optional(number, 28800)
      phase2_dh_group_numbers      = optional(list(number))
      phase2_encryption_algorithms = optional(list(string))
      phase2_integrity_algorithms  = optional(list(string))
      phase2_lifetime_seconds      = optional(number, 3600)
      rekey_fuzz_percentage        = optional(number, 100)
      rekey_margin_time_seconds    = optional(number, 540)
      replay_window_size           = optional(number, 1024)
      startup_action               = optional(string, "add")
    }))
    tunnel2 = optional(object({
      inside_cidr                  = optional(string)
      pre_shared_key               = optional(string)
      ike_versions                 = optional(list(string))
      dpd_timeout_action           = optional(string, "clear")
      dpd_timeout_seconds          = optional(number, 30)
      phase1_dh_group_numbers      = optional(list(number))
      phase1_encryption_algorithms = optional(list(string))
      phase1_integrity_algorithms  = optional(list(string))
      phase1_lifetime_seconds      = optional(number, 28800)
      phase2_dh_group_numbers      = optional(list(number))
      phase2_encryption_algorithms = optional(list(string))
      phase2_integrity_algorithms  = optional(list(string))
      phase2_lifetime_seconds      = optional(number, 3600)
      rekey_fuzz_percentage        = optional(number, 100)
      rekey_margin_time_seconds    = optional(number, 540)
      replay_window_size           = optional(number, 1024)
      startup_action               = optional(string, "add")
    }))
    tags = optional(map(string), {})
  }))

  validation {
    condition     = alltrue([for c in var.connections : (c.transit_gateway_id == null) != (c.vpn_gateway == null)])
    error_message = "exactly one attachment must be set: transit_gateway_id (tgw-attach-...) or vpn_gateway (a vpn_gateways map key, or an existing VGW id vgw-...)."
  }

  validation {
    condition     = alltrue([for c in var.connections : can(regex("^cgw-[0-9a-f]{8,17}$", c.customer_gateway)) || can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", c.customer_gateway))])
    error_message = "customer_gateway must be a customer_gateways map key (RFC1035-shaped) or an existing customer gateway ID (cgw-...)."
  }

  validation {
    condition     = alltrue([for c in var.connections : contains(["ipv4", "ipv6"], c.tunnel_inside_ip_version)])
    error_message = "tunnel_inside_ip_version must be ipv4 or ipv6 (case-sensitive); ipv6 only supports Transit Gateway attachments."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.tunnel_inside_ip_version == "ipv4" || c.transit_gateway_id != null])
    error_message = "tunnel_inside_ip_version ipv6 is only supported for Transit Gateway attachments."
  }

  validation {
    condition = alltrue(flatten([
      for c in var.connections : [
        for ck in [c.tunnel1, c.tunnel2] : ck == null || ck.dpd_timeout_seconds == null || ck.dpd_timeout_seconds >= 30
      ]
    ]))
    error_message = "dpd_timeout_seconds must be 30 or higher (provider default 30); for GCP interoperability consider restart as dpd_timeout_action so AWS re-initiates IKE on a dead peer."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.tunnel1 == null || c.tunnel1.inside_cidr == null || (can(cidrnetmask(c.tunnel1.inside_cidr)) && split("/", c.tunnel1.inside_cidr)[1] == "30" && can(cidrhost(c.tunnel1.inside_cidr, 0)) && cidrsubnet("169.254.0.0/16", 0, 0) != null)])
    error_message = "tunnel1.inside_cidr must be a /30 from the 169.254.0.0/16 link-local range (e.g. 169.254.0.0/30); the two tunnels' inside CIDRs must differ. With BGP (static_routes_only = false) these are the BGP endpoints AWS assigns."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.tunnel2 == null || c.tunnel2.inside_cidr == null || (can(cidrnetmask(c.tunnel2.inside_cidr)) && split("/", c.tunnel2.inside_cidr)[1] == "30")])
    error_message = "tunnel2.inside_cidr must be a /30 from the 169.254.0.0/16 link-local range (e.g. 169.254.1.0/30)."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.tunnel1 == null || c.tunnel1.pre_shared_key == null || can(regex("^[A-Za-z0-9._]{8,64}$", c.tunnel1.pre_shared_key)) && substr(c.tunnel1.pre_shared_key, 0, 1) != "0"])
    error_message = "tunnel1.pre_shared_key must be 8 to 64 alphanumeric, . or _ characters, not start with 0; must match the GCP side's shared_secret for that tunnel."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.tunnel2 == null || c.tunnel2.pre_shared_key == null || (can(regex("^[A-Za-z0-9._]{8,64}$", c.tunnel2.pre_shared_key)) && substr(c.tunnel2.pre_shared_key, 0, 1) != "0")])
    error_message = "tunnel2.pre_shared_key must be 8 to 64 alphanumeric, . or _ characters, not start with 0; must match the GCP side's shared_secret for that tunnel."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.tunnel1 == null || c.tunnel1.ike_versions == null || alltrue([for v in c.tunnel1.ike_versions : contains(["ikev1", "ikev2"], v)])])
    error_message = "tunnel1.ike_versions values must be ikev1 or ikev2 (case-sensitive); GCP supports both, IKEv2 is the modern default."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.tunnel2 == null || c.tunnel2.ike_versions == null || alltrue([for v in c.tunnel2.ike_versions : contains(["ikev1", "ikev2"], v)])])
    error_message = "tunnel2.ike_versions values must be ikev1 or ikev2 (case-sensitive); GCP supports both, IKEv2 is the modern default."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.tunnel1 == null || c.tunnel1.phase1_lifetime_seconds == null || (c.tunnel1.phase1_lifetime_seconds >= 900 && c.tunnel1.phase1_lifetime_seconds <= 28800)])
    error_message = "tunnel1.phase1_lifetime_seconds must be between 900 and 28800 (provider default 28800); GCP's rekey must land inside this window."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.tunnel2 == null || c.tunnel2.phase1_lifetime_seconds == null || (c.tunnel2.phase1_lifetime_seconds >= 900 && c.tunnel2.phase1_lifetime_seconds <= 28800)])
    error_message = "tunnel2.phase1_lifetime_seconds must be between 900 and 28800 (provider default 28800)."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.tunnel1 == null || c.tunnel1.phase2_lifetime_seconds == null || (c.tunnel1.phase2_lifetime_seconds >= 900 && c.tunnel1.phase2_lifetime_seconds <= 3600)])
    error_message = "tunnel1.phase2_lifetime_seconds must be between 900 and 3600 (provider default 3600)."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.tunnel2 == null || c.tunnel2.phase2_lifetime_seconds == null || (c.tunnel2.phase2_lifetime_seconds >= 900 && c.tunnel2.phase2_lifetime_seconds <= 3600)])
    error_message = "tunnel2.phase2_lifetime_seconds must be between 900 and 3600 (provider default 3600)."
  }

  validation {
    condition = alltrue(flatten([
      for c in var.connections : [
        for tk in ["tunnel1", "tunnel2"] : c[tk] == null || c[tk].inside_cidr == null || can(cidrnetmask(c[tk].inside_cidr))
      ]
    ]))
    error_message = "inside_cidr must be a valid IPv4 CIDR."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.local_ipv4_network_cidr == "0.0.0.0/0" || can(cidrnetmask(c.local_ipv4_network_cidr))])
    error_message = "local_ipv4_network_cidr must be a valid IPv4 CIDR (default 0.0.0.0/0 = all); set to the GCP subnets' aggregate to match traffic selectors exactly."
  }

  validation {
    condition     = alltrue([for c in var.connections : c.remote_ipv4_network_cidr == "0.0.0.0/0" || can(cidrnetmask(c.remote_ipv4_network_cidr))])
    error_message = "remote_ipv4_network_cidr must be a valid IPv4 CIDR (default 0.0.0.0/0 = all); set to the AWS side CIDR to match traffic selectors exactly."
  }

  validation {
    condition     = alltrue(flatten([for c in var.connections : [for r in c.static_routes : can(cidrnetmask(r))]]))
    error_message = "static_routes entries must be valid IPv4 CIDRs with host bits unset; they are added to the VGW/VPN connection when static_routes_only is true."
  }

  validation {
    condition     = alltrue([for c in var.connections : !c.static_routes_only || length(c.static_routes) > 0 || true])
    error_message = "static_routes_only = true with no static_routes entries yields no routes; add static_routes so the peer can reach the VPC."
  }
}
