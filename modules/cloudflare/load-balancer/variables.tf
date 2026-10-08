variable "account_id" {
  description = "Cloudflare account ID that owns the monitors and pools."
  type        = string
}

variable "zone_id" {
  description = "Fallback zone ID used when a load balancer omits its own. Must be set if any load balancer omits zone_id."
  type        = string
  default     = ""
}

variable "monitors" {
  description = "Map of health monitors keyed by an arbitrary unique identifier."
  type = map(object({
    type             = optional(string)
    method           = optional(string)
    path             = optional(string)
    port             = optional(number)
    expected_codes   = optional(string)
    expected_body    = optional(string)
    header           = optional(map(list(string)))
    interval         = optional(number)
    retries          = optional(number)
    timeout          = optional(number)
    consecutive_up   = optional(number)
    consecutive_down = optional(number)
    allow_insecure   = optional(bool)
    follow_redirects = optional(bool)
    probe_zone       = optional(string)
    description      = optional(string)
  }))
}

variable "pools" {
  description = "Map of origin pools keyed by an arbitrary unique identifier. Origins is an ordered list (failover within the pool is by position); monitor is a key into the monitors map."
  type = map(object({
    name = string
    origins = list(object({
      address            = optional(string)
      name               = optional(string)
      port               = optional(number)
      weight             = optional(number)
      enabled            = optional(bool)
      flatten_cname      = optional(bool)
      header             = optional(object({ host = optional(list(string)) }))
      virtual_network_id = optional(string)
    }))
    monitor            = optional(string)
    monitor_group      = optional(string)
    minimum_origins    = optional(number)
    check_regions      = optional(list(string))
    health_sources     = optional(list(string))
    enabled            = optional(bool)
    description        = optional(string)
    notification_email = optional(string)
    notification_filter = optional(object({
      origin = optional(object({ disable = optional(bool), healthy = optional(bool) }))
      pool   = optional(object({ disable = optional(bool), healthy = optional(bool) }))
    }))
    origin_steering = optional(object({
      policy = optional(string)
    }))
    load_shedding = optional(object({
      default_percent = optional(number)
      default_policy  = optional(string)
      session_percent = optional(number)
      session_policy  = optional(string)
    }))
    latitude  = optional(number)
    longitude = optional(number)
  }))

  validation {
    condition = alltrue([
      for p in var.pools : p.monitor == null || contains(keys(var.monitors), p.monitor)
    ])
    error_message = "Every pools[].monitor must be a key in monitors."
  }
}

variable "load_balancers" {
  description = "Map of load balancers keyed by an arbitrary unique identifier. default_pools (ordered — failover priority), fallback_pool, region/pop/country maps, and random_steering.pool_weights carry pool keys."
  type = map(object({
    name             = string
    default_pools    = list(string)
    fallback_pool    = string
    zone_id          = optional(string)
    proxied          = optional(bool)
    ttl              = optional(number)
    steering_policy  = optional(string)
    session_affinity = optional(string)
    session_affinity_attributes = optional(object({
      drain_duration         = optional(number)
      headers                = optional(list(string))
      require_all_headers    = optional(bool)
      samesite               = optional(string)
      secure                 = optional(string)
      zero_downtime_failover = optional(string)
    }))
    session_affinity_ttl = optional(number)
    region_pools         = optional(map(list(string)))
    pop_pools            = optional(map(list(string)))
    country_pools        = optional(map(list(string)))
    adaptive_routing = optional(object({
      failover_across_pools = optional(bool)
    }))
    location_strategy = optional(object({
      mode       = optional(string)
      prefer_ecs = optional(string)
    }))
    random_steering = optional(object({
      default_weight = optional(number)
      pool_weights   = optional(map(number))
    }))
    description = optional(string)
    enabled     = optional(bool)
    networks    = optional(list(string))
  }))

  validation {
    condition = alltrue([
      for lb in var.load_balancers : alltrue([
        for k in lb.default_pools : contains(keys(var.pools), k)
      ]) && contains(keys(var.pools), lb.fallback_pool)
    ])
    error_message = "Every load_balancers[].default_pools element and fallback_pool must be a key in pools."
  }

  validation {
    condition = alltrue(flatten([
      for lb in var.load_balancers : [
        alltrue([
          for k in flatten([for _, ks in lb.region_pools != null ? lb.region_pools : {} : ks]) : contains(keys(var.pools), k)
        ]),
        alltrue([
          for k in flatten([for _, ks in lb.pop_pools != null ? lb.pop_pools : {} : ks]) : contains(keys(var.pools), k)
        ]),
        alltrue([
          for k in flatten([for _, ks in lb.country_pools != null ? lb.country_pools : {} : ks]) : contains(keys(var.pools), k)
        ]),
        alltrue([
          for k, w in lb.random_steering != null && lb.random_steering.pool_weights != null ? lb.random_steering.pool_weights : {} : contains(keys(var.pools), k)
        ]),
      ]
    ]))
    error_message = "Every pool key in load_balancers[].region_pools, pop_pools, country_pools, and random_steering.pool_weights must be a key in pools."
  }
}
