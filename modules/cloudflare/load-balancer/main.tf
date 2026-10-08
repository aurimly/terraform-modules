terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

resource "cloudflare_load_balancer_monitor" "monitor" {
  for_each = var.monitors

  account_id       = var.account_id
  type             = each.value.type
  method           = each.value.method
  path             = each.value.path
  port             = each.value.port
  expected_codes   = each.value.expected_codes
  expected_body    = each.value.expected_body
  header           = each.value.header
  interval         = each.value.interval
  retries          = each.value.retries
  timeout          = each.value.timeout
  consecutive_up   = each.value.consecutive_up
  consecutive_down = each.value.consecutive_down
  allow_insecure   = each.value.allow_insecure
  follow_redirects = each.value.follow_redirects
  probe_zone       = each.value.probe_zone
  description      = each.value.description
}

resource "cloudflare_load_balancer_pool" "pool" {
  for_each = var.pools

  account_id          = var.account_id
  name                = each.value.name
  origins             = each.value.origins
  monitor             = each.value.monitor != null ? cloudflare_load_balancer_monitor.monitor[each.value.monitor].id : null
  monitor_group       = each.value.monitor_group
  minimum_origins     = each.value.minimum_origins
  check_regions       = each.value.check_regions
  health_sources      = each.value.health_sources
  enabled             = each.value.enabled
  description         = each.value.description
  notification_email  = each.value.notification_email
  notification_filter = each.value.notification_filter
  origin_steering     = each.value.origin_steering
  load_shedding       = each.value.load_shedding
  latitude            = each.value.latitude
  longitude           = each.value.longitude
}

resource "cloudflare_load_balancer" "lb" {
  for_each = var.load_balancers

  zone_id                     = coalesce(each.value.zone_id, var.zone_id)
  name                        = each.value.name
  default_pools               = [for k in each.value.default_pools : cloudflare_load_balancer_pool.pool[k].id]
  fallback_pool               = cloudflare_load_balancer_pool.pool[each.value.fallback_pool].id
  region_pools                = each.value.region_pools != null ? { for region, ks in each.value.region_pools : region => [for k in ks : cloudflare_load_balancer_pool.pool[k].id] } : null
  pop_pools                   = each.value.pop_pools != null ? { for pop, ks in each.value.pop_pools : pop => [for k in ks : cloudflare_load_balancer_pool.pool[k].id] } : null
  country_pools               = each.value.country_pools != null ? { for cc, ks in each.value.country_pools : cc => [for k in ks : cloudflare_load_balancer_pool.pool[k].id] } : null
  proxied                     = each.value.proxied
  ttl                         = each.value.ttl
  steering_policy             = each.value.steering_policy
  session_affinity            = each.value.session_affinity
  session_affinity_attributes = each.value.session_affinity_attributes
  session_affinity_ttl        = each.value.session_affinity_ttl
  adaptive_routing            = each.value.adaptive_routing
  location_strategy           = each.value.location_strategy
  random_steering = each.value.random_steering != null ? {
    default_weight = each.value.random_steering.default_weight
    pool_weights   = each.value.random_steering.pool_weights != null ? { for k, w in each.value.random_steering.pool_weights : cloudflare_load_balancer_pool.pool[k].id => w } : null
  } : null
  description = each.value.description
  enabled     = each.value.enabled
  networks    = each.value.networks

  lifecycle {
    precondition {
      condition     = (each.value.zone_id != null && each.value.zone_id != "") || var.zone_id != ""
      error_message = "load balancer \"${each.key}\" must set zone_id, or the module-level zone_id fallback must be set."
    }
  }
}
