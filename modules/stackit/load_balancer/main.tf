terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_loadbalancer" "load_balancer" {
  for_each = var.load_balancers

  name                              = each.value.name
  project_id                        = each.value.project_id
  region                            = each.value.region
  plan_id                           = each.value.plan_id
  external_address                  = each.value.external_address
  disable_security_group_assignment = each.value.disable_security_group_assignment
  options                           = each.value.options

  networks = [{
    network_id = each.value.network.network_id
    role       = each.value.network.role
  }]

  listeners = [for l in each.value.listeners : {
    port         = l.port
    protocol     = l.protocol
    target_pool  = l.target_pool
    display_name = l.display_name
    tcp          = l.tcp
    udp          = l.udp
  }]

  target_pools = [for p in each.value.target_pools : {
    name        = p.name
    target_port = p.target_port
    targets = [for t in p.targets : {
      display_name = t.display_name
      ip           = t.ip
    }]
    active_health_check = p.active_health_check
    session_persistence = p.session_persistence
  }]
}
