terraform {
  required_providers {
    equinix = {
      source  = "equinix/equinix"
      version = ">= 5.0.0"
    }
  }
}

resource "equinix_fabric_route_aggregation" "route_aggregation" {
  for_each = var.route_aggregations

  name        = each.value.name
  type        = each.value.type
  description = each.value.description

  project = {
    project_id = each.value.project.project_id
  }
}

# Rules are keyed by "aggregation_key:rule_key": the rule resource's
# route_aggregation_id has no RequiresReplace upstream, so without the
# composite key a parent change would patch the prefix on the old
# aggregation and the rule would silently never move. With it, a parent
# change is an honest destroy + create.
resource "equinix_fabric_route_aggregation_rule" "rule" {
  for_each = { for k, v in var.rules : "${v.aggregation_key}:${k}" => v }

  route_aggregation_id = equinix_fabric_route_aggregation.route_aggregation[each.value.aggregation_key].uuid
  name                 = each.value.name
  prefix               = each.value.prefix
  description          = each.value.description
}

resource "equinix_fabric_connection_route_aggregation" "attachment" {
  for_each = var.connection_attachments

  route_aggregation_id = equinix_fabric_route_aggregation.route_aggregation[each.value.aggregation_key].uuid
  connection_id        = each.value.connection_id
}
