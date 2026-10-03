variable "load_balancers" {
  description = "Map of Hetzner Cloud load balancers keyed by an arbitrary identifier. Each entry creates one load balancer with its services, targets and optional private-network attachments. Map keys at every level must not contain `__` (the module composes internal resource keys from them, and it is the provider's import ID separator)."
  type = map(object({
    name               = string
    load_balancer_type = string
    location           = optional(string)
    network_zone       = optional(string)
    algorithm          = optional(string)
    labels             = optional(map(string), {})
    delete_protection  = optional(bool)
    networks = optional(map(object({
      network_id              = optional(number)
      subnet_id               = optional(string)
      ip                      = optional(string)
      enable_public_interface = optional(bool)
    })), {})
    services = optional(map(object({
      protocol         = string
      listen_port      = optional(number)
      destination_port = optional(number)
      proxyprotocol    = optional(bool)
      http = optional(object({
        sticky_sessions = optional(bool)
        cookie_name     = optional(string)
        cookie_lifetime = optional(number)
        certificates    = optional(list(number), [])
        redirect_http   = optional(bool)
        timeout_idle    = optional(number)
      }))
      health_check = optional(object({
        protocol = string
        port     = number
        interval = number
        timeout  = number
        retries  = number
        http = optional(object({
          domain       = optional(string)
          path         = optional(string)
          response     = optional(string)
          tls          = optional(bool)
          status_codes = optional(list(string), [])
        }))
      }))
    })), {})
    targets = optional(map(object({
      type           = string
      server_id      = optional(number)
      label_selector = optional(string)
      ip             = optional(string)
      use_private_ip = optional(bool)
    })), {})
  }))

  validation {
    condition     = alltrue([for k in concat(keys(var.load_balancers), flatten([for lb in var.load_balancers : concat(keys(lb.services), keys(lb.targets), keys(lb.networks))])) : !can(regex("__", k))])
    error_message = "map keys must not contain the substring `__` (the module composes internal resource keys from them, and it is the provider's import ID separator)."
  }

  validation {
    condition     = length(distinct([for lb in var.load_balancers : lb.name])) == length(var.load_balancers)
    error_message = "name must be unique per project; the map contains duplicate names."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : (lb.location != null) != (lb.network_zone != null)])
    error_message = "exactly one of location or network_zone must be set per load balancer."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : length(lb.name) >= 1 && length(lb.name) <= 128 && can(regex("^\\S(.*\\S)?$", lb.name))])
    error_message = "name must be 1 to 128 characters with no leading or trailing whitespace."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : lb.algorithm == null || contains(["round_robin", "least_connections"], lb.algorithm)])
    error_message = "algorithm must be one of round_robin or least_connections, when set."
  }

  validation {
    condition = alltrue([for lb in var.load_balancers : alltrue([
      for l in keys(lb.labels) : can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,253}[a-zA-Z0-9])?/[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", l)) || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", l)) && length(l) <= 63
    ])])
    error_message = "labels keys must be valid: start and end with a letter or digit, may contain dots, underscores and hyphens; optionally a '<prefix>/' prefix (prefix up to 254 characters)."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : alltrue([for v in lb.labels : v == "" || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", v))])])
    error_message = "labels values must be at most 63 characters, start and end with a letter or digit, and may contain dots, underscores and hyphens in-between; values may be empty."
  }

  validation {
    condition     = alltrue(flatten([for lb in var.load_balancers : [for n in lb.networks : (n.network_id != null) != (n.subnet_id != null)]]))
    error_message = "networks: exactly one of network_id or subnet_id must be set per entry."
  }

  validation {
    condition     = alltrue(flatten([for lb in var.load_balancers : [for n in lb.networks : n.network_id == null || n.network_id > 0]]))
    error_message = "networks: network_id must be a positive network ID."
  }

  validation {
    condition     = alltrue(flatten([for lb in var.load_balancers : [for n in lb.networks : n.subnet_id == null || (can(regex("^[0-9]+-.+$", n.subnet_id)) && can(cidrnetmask(split("-", n.subnet_id)[1])))]]))
    error_message = "networks: subnet_id must have the format \"<network_id>-<subnet ip range>\", e.g. \"4711-10.0.1.0/24\"."
  }

  validation {
    condition     = alltrue(flatten([for lb in var.load_balancers : [for nk, n in lb.networks : n.ip == null || can(cidrhost("${n.ip}/32", 0)) || can(cidrhost("${n.ip}/128", 0))]]))
    error_message = "networks: ip must be a valid IPv4 or IPv6 address, when set."
  }

  validation {
    condition = alltrue([for lb in var.load_balancers :
      length(distinct([for nk, n in lb.networks : n.network_id != null ? tostring(n.network_id) : try(split("-", n.subnet_id)[0], "unset")])) == length(lb.networks)
    ])
    error_message = "networks: a load balancer may only be attached to each network once."
  }

  validation {
    condition     = alltrue([for lb in var.load_balancers : length(distinct([for n in lb.networks : coalesce(n.enable_public_interface, true)])) <= 1])
    error_message = "networks: enable_public_interface is a load balancer-level property; entries that set it must agree on the value."
  }

  validation {
    condition     = alltrue(flatten([for lb in var.load_balancers : [for s in lb.services : contains(["http", "https", "tcp"], s.protocol)]]))
    error_message = "services: protocol must be one of http, https or tcp."
  }

  validation {
    condition     = alltrue(flatten([for lb in var.load_balancers : [for s in lb.services : s.protocol != "tcp" || (s.listen_port != null && s.destination_port != null)]]))
    error_message = "services: listen_port and destination_port are required when protocol is tcp."
  }

  validation {
    condition = alltrue(flatten([
      for lb in var.load_balancers : [
        for s in lb.services : concat(
          [for p in [s.listen_port] : p >= 1 && p <= 65535 if p != null],
          [for p in [s.destination_port] : p >= 1 && p <= 65535 if p != null],
          [for p in try([s.health_check.port], []) : p >= 1 && p <= 65535],
        )
      ]
    ]))
    error_message = "ports must be between 1 and 65535 (listen_port, destination_port and health_check.port)."
  }

  validation {
    condition     = alltrue(flatten([for lb in var.load_balancers : [for s in lb.services : s.http == null || s.protocol == "http" || s.protocol == "https"]]))
    error_message = "services: the http block is only valid when protocol is http or https."
  }

  validation {
    condition     = alltrue(flatten([for lb in var.load_balancers : [for s in lb.services : s.protocol != "https" || length(try(s.http.certificates, [])) > 0]]))
    error_message = "services: protocol https requires at least one certificate ID in http.certificates."
  }

  validation {
    condition     = alltrue(flatten([for lb in var.load_balancers : [for s in lb.services : s.http == null || s.http.redirect_http == null || !s.http.redirect_http || s.protocol == "https"]]))
    error_message = "services: redirect_http is only valid for an https service (the API redirects requests from HTTP port 80 to it)."
  }

  validation {
    condition     = alltrue(flatten([for lb in var.load_balancers : [for s in lb.services : s.http == null || s.http.timeout_idle == null || (s.http.timeout_idle >= 30 && s.http.timeout_idle <= 300)]]))
    error_message = "services: http.timeout_idle must be between 30 and 300 seconds, when set."
  }

  validation {
    condition     = alltrue(flatten([for lb in var.load_balancers : [for s in lb.services : s.http == null || s.http.cookie_lifetime == null || (s.http.cookie_lifetime >= 30 && s.http.cookie_lifetime <= 86400)]]))
    error_message = "services: http.cookie_lifetime must be between 30 and 86400 seconds (API schema), when set."
  }

  validation {
    condition     = alltrue(flatten([for lb in var.load_balancers : [for s in lb.services : s.health_check == null || contains(["http", "https", "tcp"], s.health_check.protocol)]]))
    error_message = "services: health_check.protocol must be one of http, https or tcp."
  }

  validation {
    condition     = alltrue(flatten([for lb in var.load_balancers : [for s in lb.services : s.health_check == null || s.health_check.protocol == "tcp" || s.health_check.http != null]]))
    error_message = "services: health_check.http is required when health_check.protocol is http or https (mirrors the API contract; the provider would leave it unset and fail at apply)."
  }

  validation {
    condition     = alltrue(flatten([for lb in var.load_balancers : [for s in lb.services : s.health_check == null || (s.health_check.interval >= 3 && s.health_check.interval <= 60)]]))
    error_message = "services: health_check.interval must be between 3 and 60 seconds (API schema)."
  }

  validation {
    condition     = alltrue(flatten([for lb in var.load_balancers : [for s in lb.services : s.health_check == null || (s.health_check.timeout >= 1 && s.health_check.timeout <= 60)]]))
    error_message = "services: health_check.timeout must be between 1 and 60 seconds (API schema)."
  }

  validation {
    condition     = alltrue(flatten([for lb in var.load_balancers : [for s in lb.services : s.health_check == null || (s.health_check.retries >= 1 && s.health_check.retries <= 5)]]))
    error_message = "services: health_check.retries must be between 1 and 5 (API schema)."
  }

  validation {
    condition = alltrue([for lb in var.load_balancers :
      length(distinct([for s in lb.services : s.listen_port != null ? s.listen_port : (s.protocol == "https" ? 443 : 80)])) == length(lb.services)
    ])
    error_message = "services: listen_port must be unique per load balancer (defaults of 80 for http and 443 for https count)."
  }

  validation {
    condition = alltrue(flatten([for lb in var.load_balancers : [for t in lb.targets :
      (t.type == "server" && t.server_id != null && t.label_selector == null && t.ip == null) ||
      (t.type == "label_selector" && t.label_selector != null && t.server_id == null && t.ip == null) ||
      (t.type == "ip" && t.ip != null && t.server_id == null && t.label_selector == null)
    ]]))
    error_message = "targets: type must match the attribute set — exactly one of server_id, label_selector or ip must be set and agree with type (server, label_selector or ip)."
  }

  validation {
    condition     = alltrue(flatten([for lb in var.load_balancers : [for t in lb.targets : t.server_id == null || t.server_id > 0]]))
    error_message = "targets: server_id must be a positive server ID."
  }

  validation {
    condition     = alltrue(flatten([for lb in var.load_balancers : [for t in lb.targets : t.use_private_ip == null || t.type != "ip"]]))
    error_message = "targets: use_private_ip is only valid for server and label_selector targets (it conflicts with type ip)."
  }

  validation {
    condition = alltrue([for lb in var.load_balancers :
      length(distinct([for t in lb.targets : "${t.type}__${t.server_id != null ? t.server_id : t.label_selector != null ? t.label_selector : try(t.ip, "unset")}"])) == length(lb.targets)
    ])
    error_message = "targets: the same target (type plus server_id, label_selector or ip) may only be defined once per load balancer."
  }

  validation {
    condition     = alltrue(flatten([for lb in var.load_balancers : [for s in lb.services : alltrue([for c in try(s.http.certificates, []) : c > 0])]]))
    error_message = "services: http.certificates entries must each be a positive certificate ID."
  }
}
