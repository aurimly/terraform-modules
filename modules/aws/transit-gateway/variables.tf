variable "gateways" {
  description = "Map of AWS Transit Gateways keyed by an arbitrary identifier. Each entry creates one aws_ec2_transit_gateway. Option strings are lowercase enable/disable (AWS API casing). Multicast support is settable only at creation; encryption support is settable only to enable (switching back to disable requires passing disable explicitly)."
  type = map(object({
    name                               = string
    description                        = optional(string)
    amazon_side_asn                    = optional(number)
    auto_accept_shared_attachments     = optional(string)
    default_route_table_association    = optional(string)
    default_route_table_propagation    = optional(string)
    dns_support                        = optional(string)
    vpn_ecmp_support                   = optional(string)
    multicast_support                  = optional(string)
    security_group_referencing_support = optional(string)
    encryption_support                 = optional(string)
    transit_gateway_cidr_blocks        = optional(set(string))
    tags                               = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.gateways) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\"."
  }

  validation {
    condition     = alltrue([for g in var.gateways : g.amazon_side_asn == null || g.amazon_side_asn >= 64512 && g.amazon_side_asn <= 65534 || g.amazon_side_asn >= 4200000000 && g.amazon_side_asn <= 4294967294])
    error_message = "amazon_side_asn must be a private autonomous system number: 64512-65534 (2-byte) or 4200000000-4294967294 (4-byte) per RFC6996; default 64512."
  }

  validation {
    condition = alltrue([
      for g in var.gateways : alltrue([
        for a in [g.auto_accept_shared_attachments, g.default_route_table_association, g.default_route_table_propagation, g.dns_support, g.vpn_ecmp_support] : a == null || contains(["enable", "disable"], a)
      ])
    ])
    error_message = "auto_accept_shared_attachments, default_route_table_association, default_route_table_propagation, dns_support and vpn_ecmp_support take lowercase enable or disable (AWS API casing; defaults: association/propagation/dns/vpn_ecmp enable, auto_accept disable)."
  }

  validation {
    condition     = alltrue([for g in var.gateways : g.multicast_support == null || contains(["enable", "disable"], g.multicast_support)])
    error_message = "multicast_support takes lowercase enable or disable; it is settable only at creation (the modify API does not cover it) — changing it forces a new gateway in practice."
  }

  validation {
    condition     = alltrue([for g in var.gateways : g.security_group_referencing_support == null || contains(["enable", "disable"], g.security_group_referencing_support)])
    error_message = "security_group_referencing_support takes lowercase enable or disable (default disable)."
  }

  validation {
    condition     = alltrue([for g in var.gateways : g.encryption_support == null || contains(["enable", "disable"], g.encryption_support)])
    error_message = "encryption_support takes lowercase enable or disable (default disable); once set to enable, switching back to disable requires passing disable explicitly rather than removing the argument."
  }

  validation {
    condition = alltrue(flatten([
      for g in var.gateways : g.transit_gateway_cidr_blocks == null ? [true] : [
        for b in g.transit_gateway_cidr_blocks : can(cidrnetmask(b)) || can(cidrhost(b, 0))
      ]
    ]))
    error_message = "transit_gateway_cidr_blocks entries must be valid CIDR blocks (/24 or larger for IPv4, /64 or larger for IPv6 at the API)."
  }
}

variable "route_tables" {
  description = "Map of Transit Gateway route tables keyed by an arbitrary identifier. Each entry creates one aws_ec2_transit_gateway_route_table on the referenced gateway (in this module by gateway_key, or a RAM-shared gateway by gateway_id). The route table has no name attribute — name becomes the Name tag."
  type = map(object({
    gateway_key = optional(string)
    gateway_id  = optional(string)
    name        = string
    tags        = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.route_tables) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\"."
  }

  validation {
    condition     = alltrue([for t in var.route_tables : (t.gateway_key != null) != (t.gateway_id != null)])
    error_message = "set exactly one of gateway_key (a gateways map key) or gateway_id (tgw-... for RAM-shared gateways) — not both, never neither."
  }

  validation {
    condition     = alltrue([for t in var.route_tables : t.gateway_id == null || can(regex("^tgw-[0-9a-f]{8,17}$", t.gateway_id))])
    error_message = "gateway_id must be a Transit Gateway ID (tgw-...)."
  }
}

variable "vpc_attachments" {
  description = "Map of Transit Gateway VPC attachments keyed by an arbitrary identifier. Each entry creates one aws_ec2_transit_gateway_vpc_attachment and, with accept = true, its accepter resource (same-account auto-accept or cross-account shared gateways). Subnets must span AZs — one subnet is allowed but single-AZ."
  type = map(object({
    name                                            = string
    gateway_key                                     = optional(string)
    transit_gateway_id                              = optional(string)
    vpc_id                                          = string
    vpc_owner_id                                    = optional(string)
    subnet_ids                                      = set(string)
    dns_support                                     = optional(string)
    ipv6_support                                    = optional(string)
    appliance_mode_support                          = optional(string)
    security_group_referencing_support              = optional(string)
    transit_gateway_default_route_table_association = optional(bool)
    transit_gateway_default_route_table_propagation = optional(bool)
    accept                                          = optional(bool, false)
    tags                                            = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.vpc_attachments) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\"."
  }

  validation {
    condition     = alltrue([for a in var.vpc_attachments : (a.gateway_key != null) != (a.transit_gateway_id != null)])
    error_message = "set exactly one of gateway_key (a gateways map key) or transit_gateway_id (tgw-... for RAM-shared gateways) — not both, never neither."
  }

  validation {
    condition     = alltrue([for a in var.vpc_attachments : a.transit_gateway_id == null || can(regex("^tgw-[0-9a-f]{8,17}$", a.transit_gateway_id))])
    error_message = "transit_gateway_id must be a Transit Gateway ID (tgw-...)."
  }

  validation {
    condition     = alltrue([for a in var.vpc_attachments : can(regex("^vpc-[0-9a-f]{8,17}$", a.vpc_id))])
    error_message = "vpc_id must be a VPC ID (vpc-...), typically dependency.network.outputs.vpc_ids with the aws/vpc module."
  }

  validation {
    condition     = alltrue([for a in var.vpc_attachments : a.vpc_owner_id == null || can(regex("^[0-9]{12}$", a.vpc_owner_id))])
    error_message = "vpc_owner_id must be a 12-digit AWS account ID (cross-account VPC attachments)."
  }

  validation {
    condition     = alltrue([for a in var.vpc_attachments : length(a.subnet_ids) >= 1])
    error_message = "subnet_ids must contain at least one subnet (the API minimum); use at least two across AZs for redundancy."
  }

  validation {
    condition = alltrue([
      for a in var.vpc_attachments : alltrue([
        for s in [a.dns_support, a.ipv6_support, a.appliance_mode_support, a.security_group_referencing_support] : s == null || contains(["enable", "disable"], s)
      ])
    ])
    error_message = "dns_support, ipv6_support, appliance_mode_support and security_group_referencing_support take lowercase enable or disable (AWS API casing; defaults: dns enable, ipv6/appliance_mode/security_group_referencing disable)."
  }
}

variable "peerings" {
  description = "Map of Transit Gateway peering attachments keyed by an arbitrary identifier. Each entry requests one aws_ec2_transit_gateway_peering_attachment from the referenced gateway to a peer gateway (same or another account/region). The peer side accepts via peering_accepters."
  type = map(object({
    name                    = string
    gateway_key             = optional(string)
    transit_gateway_id      = optional(string)
    peer_transit_gateway_id = string
    peer_region             = string
    peer_account_id         = optional(string)
    options = optional(object({
      dynamic_routing = optional(string)
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.peerings) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\"."
  }

  validation {
    condition     = alltrue([for p in var.peerings : (p.gateway_key != null) != (p.transit_gateway_id != null)])
    error_message = "set exactly one of gateway_key (a gateways map key) or transit_gateway_id (tgw-... for RAM-shared gateways) — not both, never neither."
  }

  validation {
    condition     = alltrue([for p in var.peerings : p.transit_gateway_id == null || can(regex("^tgw-[0-9a-f]{8,17}$", p.transit_gateway_id))])
    error_message = "transit_gateway_id must be a Transit Gateway ID (tgw-...)."
  }

  validation {
    condition     = alltrue([for p in var.peerings : can(regex("^tgw-[0-9a-f]{8,17}$", p.peer_transit_gateway_id))])
    error_message = "peer_transit_gateway_id must be a Transit Gateway ID (tgw-...)."
  }

  validation {
    condition     = alltrue([for p in var.peerings : can(regex("^[a-z]{2,3}(-[a-z0-9]+)+-[0-9]+$", p.peer_region))])
    error_message = "peer_region must look like a region name (e.g. us-east-1, eu-central-1); it is a shape check, not a list of valid regions."
  }

  validation {
    condition     = alltrue([for p in var.peerings : p.peer_account_id == null || can(regex("^[0-9]{12}$", p.peer_account_id))])
    error_message = "peer_account_id must be a 12-digit AWS account ID (defaults to the provider account when omitted)."
  }

  validation {
    condition     = alltrue([for p in var.peerings : p.options == null || p.options.dynamic_routing == null || contains(["enable", "disable"], p.options.dynamic_routing)])
    error_message = "options.dynamic_routing takes lowercase enable or disable."
  }
}

variable "peering_accepters" {
  description = "Map of Transit Gateway peering accepters keyed by an arbitrary identifier. Each entry accepts one peering attachment requested by the peer side (cross-account or cross-region); the attachment id is the requester-side pass-through id — no in-module edge is possible because the peering lives in the requester's account/plan."
  type = map(object({
    name                          = optional(string)
    transit_gateway_attachment_id = string
    tags                          = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.peering_accepters) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\"."
  }

  validation {
    condition     = alltrue([for a in var.peering_accepters : can(regex("^tgw-attach-[0-9a-f]{8,17}$", a.transit_gateway_attachment_id))])
    error_message = "transit_gateway_attachment_id must be a peering attachment ID (tgw-attach-...) from the requester's account."
  }
}

variable "routes" {
  description = "Map of static Transit Gateway routes keyed by an arbitrary identifier. Each entry creates one aws_ec2_transit_gateway_route on the referenced route table: a blackhole or a target attachment (a VPC attachment in this module by attachment_key, or any attachment id pass-through — VPN attachments are implicit to their VPN connection and referenced by id)."
  type = map(object({
    route_table_key               = optional(string)
    route_table_id                = optional(string)
    destination_cidr_block        = string
    attachment_key                = optional(string)
    transit_gateway_attachment_id = optional(string)
    blackhole                     = optional(bool, false)
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.routes) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\"."
  }

  validation {
    condition     = alltrue([for r in var.routes : (r.route_table_key != null) != (r.route_table_id != null)])
    error_message = "set exactly one of route_table_key (a route_tables map key) or route_table_id (tgw-rt-...) — not both, never neither."
  }

  validation {
    condition     = alltrue([for r in var.routes : r.route_table_id == null || can(regex("^tgw-rt-[0-9a-f]{8,17}$", r.route_table_id))])
    error_message = "route_table_id must be a Transit Gateway route table ID (tgw-rt-...)."
  }

  validation {
    condition     = alltrue([for r in var.routes : r.blackhole || r.attachment_key != null || r.transit_gateway_attachment_id != null])
    error_message = "a route needs exactly one target: an attachment (attachment_key or transit_gateway_attachment_id) or blackhole = true (a route with neither target is not creatable in practice)."
  }

  validation {
    condition     = alltrue([for r in var.routes : r.blackhole || (r.attachment_key != null) != (r.transit_gateway_attachment_id != null)])
    error_message = "set exactly one of attachment_key (a vpc_attachments map key) or transit_gateway_attachment_id (tgw-attach-... pass-through, e.g. a VPN attachment id) — not both; blackhole routes take neither."
  }

  validation {
    condition     = alltrue([for r in var.routes : !r.blackhole || (r.attachment_key == null && r.transit_gateway_attachment_id == null)])
    error_message = "blackhole = true conflicts with an attachment target — a blackhole route drops traffic and has no next hop."
  }

  validation {
    condition     = alltrue([for r in var.routes : can(cidrnetmask(r.destination_cidr_block)) || can(cidrhost(r.destination_cidr_block, 0))])
    error_message = "destination_cidr_block must be a valid IPv4 or IPv6 CIDR block (routing matches the most specific prefix)."
  }
}

variable "associations" {
  description = "Map of Transit Gateway route table associations keyed by an arbitrary identifier. Each entry associates one route table (route_table_key or route_table_id) with one attachment (attachment_key or transit_gateway_attachment_id). See the default-route-table gotcha in the README Notes before declaring explicit associations."
  type = map(object({
    route_table_key               = optional(string)
    route_table_id                = optional(string)
    attachment_key                = optional(string)
    transit_gateway_attachment_id = optional(string)
    replace_existing_association  = optional(bool)
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.associations) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\"."
  }

  validation {
    condition     = alltrue([for a in var.associations : (a.route_table_key != null) != (a.route_table_id != null)])
    error_message = "set exactly one of route_table_key (a route_tables map key) or route_table_id (tgw-rt-...) — not both, never neither."
  }

  validation {
    condition     = alltrue([for a in var.associations : a.route_table_id == null || can(regex("^tgw-rt-[0-9a-f]{8,17}$", a.route_table_id))])
    error_message = "route_table_id must be a Transit Gateway route table ID (tgw-rt-...)."
  }

  validation {
    condition     = alltrue([for a in var.associations : (a.attachment_key != null) != (a.transit_gateway_attachment_id != null)])
    error_message = "set exactly one of attachment_key (a vpc_attachments map key) or transit_gateway_attachment_id (tgw-attach-... pass-through) — not both, never neither."
  }
}

variable "propagations" {
  description = "Map of Transit Gateway route table propagations keyed by an arbitrary identifier. Each entry makes the referenced route table learn routes from one attachment (route_table_key or route_table_id; attachment_key or transit_gateway_attachment_id)."
  type = map(object({
    route_table_key               = optional(string)
    route_table_id                = optional(string)
    attachment_key                = optional(string)
    transit_gateway_attachment_id = optional(string)
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.propagations) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\"."
  }

  validation {
    condition     = alltrue([for p in var.propagations : (p.route_table_key != null) != (p.route_table_id != null)])
    error_message = "set exactly one of route_table_key (a route_tables map key) or route_table_id (tgw-rt-...) — not both, never neither."
  }

  validation {
    condition     = alltrue([for p in var.propagations : p.route_table_id == null || can(regex("^tgw-rt-[0-9a-f]{8,17}$", p.route_table_id))])
    error_message = "route_table_id must be a Transit Gateway route table ID (tgw-rt-...)."
  }

  validation {
    condition     = alltrue([for p in var.propagations : (p.attachment_key != null) != (p.transit_gateway_attachment_id != null)])
    error_message = "set exactly one of attachment_key (a vpc_attachments map key) or transit_gateway_attachment_id (tgw-attach-... pass-through) — not both, never neither."
  }
}
