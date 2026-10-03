terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.50.0"
    }
  }
}

locals {
  services = merge([
    for lk, lb in var.load_balancers : {
      for sk, svc in lb.services : "${lk}__${sk}" => {
        lb_id  = hcloud_load_balancer.load_balancer[lk].id
        config = svc
      }
    }
  ]...)

  targets = merge([
    for lk, lb in var.load_balancers : {
      for tk, tgt in lb.targets : "${lk}__${tk}" => {
        lb_id  = hcloud_load_balancer.load_balancer[lk].id
        config = tgt
      }
    }
  ]...)

  networks = merge([
    for lk, lb in var.load_balancers : {
      for nk, net in lb.networks : "${lk}__${nk}" => {
        lb_id  = hcloud_load_balancer.load_balancer[lk].id
        config = net
      }
    }
  ]...)
}

resource "hcloud_load_balancer" "load_balancer" {
  for_each = var.load_balancers

  name               = each.value.name
  load_balancer_type = each.value.load_balancer_type
  location           = each.value.location
  network_zone       = each.value.network_zone
  labels             = each.value.labels
  delete_protection  = each.value.delete_protection

  dynamic "algorithm" {
    for_each = each.value.algorithm != null ? [each.value.algorithm] : []

    content {
      type = algorithm.value
    }
  }
}

resource "hcloud_load_balancer_service" "service" {
  for_each = local.services

  load_balancer_id = each.value.lb_id
  protocol         = each.value.config.protocol
  listen_port      = each.value.config.listen_port
  destination_port = each.value.config.destination_port
  proxyprotocol    = each.value.config.proxyprotocol

  dynamic "http" {
    for_each = each.value.config.http != null ? [each.value.config.http] : []

    content {
      sticky_sessions = http.value.sticky_sessions
      cookie_name     = http.value.cookie_name
      cookie_lifetime = http.value.cookie_lifetime
      certificates    = http.value.certificates
      redirect_http   = http.value.redirect_http
      timeout_idle    = http.value.timeout_idle
    }
  }

  dynamic "health_check" {
    for_each = each.value.config.health_check != null ? [each.value.config.health_check] : []

    content {
      protocol = health_check.value.protocol
      port     = health_check.value.port
      interval = health_check.value.interval
      timeout  = health_check.value.timeout
      retries  = health_check.value.retries

      dynamic "http" {
        for_each = health_check.value.http != null ? [health_check.value.http] : []

        content {
          domain       = http.value.domain
          path         = http.value.path
          response     = http.value.response
          tls          = http.value.tls
          status_codes = http.value.status_codes
        }
      }
    }
  }
}

resource "hcloud_load_balancer_target" "target" {
  for_each = local.targets

  load_balancer_id = each.value.lb_id
  type             = each.value.config.type
  server_id        = each.value.config.server_id
  label_selector   = each.value.config.label_selector
  ip               = each.value.config.ip
  use_private_ip   = each.value.config.use_private_ip
}

resource "hcloud_load_balancer_network" "network" {
  for_each = local.networks

  load_balancer_id        = each.value.lb_id
  network_id              = each.value.config.network_id
  subnet_id               = each.value.config.subnet_id
  ip                      = each.value.config.ip
  enable_public_interface = each.value.config.enable_public_interface
}
