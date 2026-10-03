output "load_balancers" {
  description = "Map of load balancer key => object with `id` (string of the numeric load balancer ID, also the import ID), `name`, `load_balancer_type`, `location`, `network_zone`, `ipv4`, `ipv6`, `algorithm`, `labels`, `delete_protection`, `network_id` and `network_ip`."
  value = { for k, lb in hcloud_load_balancer.load_balancer : k => {
    id                 = tostring(lb.id)
    name               = lb.name
    load_balancer_type = lb.load_balancer_type
    location           = lb.location
    network_zone       = lb.network_zone
    ipv4               = lb.ipv4
    ipv6               = lb.ipv6
    algorithm          = lb.algorithm[0].type
    labels             = lb.labels
    delete_protection  = lb.delete_protection
    network_id         = lb.network_id
    network_ip         = lb.network_ip
  } }
}

output "service_ids" {
  description = "Map of `<load balancer key>__<service key>` => string of the service ID `<load balancer ID>__<listen port>` — also the import ID. Keys inherit the module's no-`__` restriction, so the composite key is unambiguous."
  value       = { for k, svc in hcloud_load_balancer_service.service : k => svc.id }
}

output "target_ids" {
  description = "Map of `<load balancer key>__<target key>` => the target's internal provider ID (generated — e.g. `lb-srv-tgt-<server id>-<load balancer id>`). Import uses the compound form `<load balancer ID>__<type>__<identifier>` instead (see README); this output is for state/tooling reference."
  value       = { for k, tgt in hcloud_load_balancer_target.target : k => tgt.id }
}
