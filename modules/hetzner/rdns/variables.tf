variable "rdns_entries" {
  description = "Map of Hetzner Cloud reverse DNS (rDNS) entries keyed by an arbitrary identifier. Each entry sets the PTR record of one IP address belonging to exactly one of server, primary IP, floating IP or load balancer."
  type = map(object({
    ip_address       = string
    dns_ptr          = string
    server_id        = optional(number)
    primary_ip_id    = optional(number)
    floating_ip_id   = optional(number)
    load_balancer_id = optional(number)
  }))

  validation {
    condition = alltrue([
      for entry in var.rdns_entries :
      length([for id in [entry.server_id, entry.primary_ip_id, entry.floating_ip_id, entry.load_balancer_id] : id if id != null]) == 1
    ])
    error_message = "exactly one of server_id, primary_ip_id, floating_ip_id or load_balancer_id must be set per entry."
  }

  validation {
    condition = alltrue([
      for entry in var.rdns_entries :
      alltrue([for id in [entry.server_id, entry.primary_ip_id, entry.floating_ip_id, entry.load_balancer_id] : id == null || id > 0])
    ])
    error_message = "target IDs must be positive resource IDs (0 is not a valid value)."
  }

  validation {
    condition     = alltrue([for entry in var.rdns_entries : can(cidrhost("${entry.ip_address}/32", 0)) || can(cidrhost("${entry.ip_address}/128", 0))])
    error_message = "ip_address must be a valid IPv4 or IPv6 address."
  }

  validation {
    condition = length(distinct([
      for entry in var.rdns_entries : format(
        "%s-%d-%s",
        entry.server_id != null ? "s" : entry.primary_ip_id != null ? "p" : entry.floating_ip_id != null ? "f" : "l",
        coalesce(entry.server_id, entry.primary_ip_id, entry.floating_ip_id, entry.load_balancer_id),
        entry.ip_address,
      )
    ])) == length(var.rdns_entries)
    error_message = "the API accepts multiple PTR entries for the same resource and IP (last write wins, the others drift); the module rejects duplicate (resource kind, resource ID, ip_address) triples so the entries converge."
  }
}
