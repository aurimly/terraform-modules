output "route_aggregations" {
  description = "Map of route aggregation key => { uuid, state, rules_count, connections_count, href }. uuid is the import ID."
  value = { for k, a in equinix_fabric_route_aggregation.route_aggregation : k => {
    uuid              = a.uuid
    state             = a.state
    rules_count       = a.rules_count
    connections_count = a.connections_count
    href              = a.href
  } }
}

output "rules" {
  description = "Map of rule key => { uuid, state, type, prefix, href }, keyed by the same keys as var.rules. uuid is the rule's own id (rules cannot be imported)."
  value = { for k, v in var.rules : k => {
    uuid   = equinix_fabric_route_aggregation_rule.rule["${v.aggregation_key}:${k}"].uuid
    state  = equinix_fabric_route_aggregation_rule.rule["${v.aggregation_key}:${k}"].state
    type   = equinix_fabric_route_aggregation_rule.rule["${v.aggregation_key}:${k}"].type
    prefix = equinix_fabric_route_aggregation_rule.rule["${v.aggregation_key}:${k}"].prefix
    href   = equinix_fabric_route_aggregation_rule.rule["${v.aggregation_key}:${k}"].href
  } }
}

output "connection_attachments" {
  description = "Map of attachment key => { uuid, attachment_status, type }. uuid is the attachment's own id (attachments cannot be imported)."
  value = { for k, a in equinix_fabric_connection_route_aggregation.attachment : k => {
    uuid              = a.uuid
    attachment_status = a.attachment_status
    type              = a.type
  } }
}
