terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.0.0"
    }
  }
}

locals {
  tunnel_routes = flatten([
    for tunnel_key, tunnel in var.tunnels : [
      for route_key, route in tunnel.routes : {
        key        = "${tunnel_key}/${route_key}"
        tunnel_key = tunnel_key
        network    = route.network
        comment    = route.comment
        vnet_id    = route.virtual_network_id
      }
    ]
  ])
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  for_each = var.tunnels

  account_id    = var.account_id
  name          = each.value.name
  config_src    = each.value.config_src
  tunnel_secret = each.value.tunnel_secret

  lifecycle {
    precondition {
      condition     = each.value.config_src == "cloudflare" || each.value.tunnel_secret != null
      error_message = "tunnel \"${each.key}\" must set tunnel_secret so connectors can authenticate, unless it is remotely managed (config_src = \"cloudflare\")."
    }
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared_route" "route" {
  for_each = { for r in local.tunnel_routes : r.key => r }

  account_id         = var.account_id
  tunnel_id          = cloudflare_zero_trust_tunnel_cloudflared.tunnel[each.value.tunnel_key].id
  network            = each.value.network
  comment            = each.value.comment
  virtual_network_id = each.value.vnet_id
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "config" {
  for_each = { for k, t in var.tunnels : k => t if t.config != null }

  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel[each.key].id
  config     = each.value.config
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "token" {
  for_each   = var.expose_tokens ? cloudflare_zero_trust_tunnel_cloudflared.tunnel : {}
  account_id = var.account_id
  tunnel_id  = each.value.id
}
