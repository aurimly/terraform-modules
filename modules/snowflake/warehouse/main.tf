terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">= 2.0.0"
    }
  }
}

resource "snowflake_warehouse" "warehouse" {
  for_each = var.warehouses

  name                                = each.value.name
  warehouse_type                      = each.value.warehouse_type
  warehouse_size                      = each.value.warehouse_size
  min_cluster_count                   = each.value.min_cluster_count
  max_cluster_count                   = each.value.max_cluster_count
  scaling_policy                      = each.value.scaling_policy
  auto_suspend                        = each.value.auto_suspend
  auto_resume                         = each.value.auto_resume != null ? tostring(each.value.auto_resume) : null
  initially_suspended                 = each.value.initially_suspended
  comment                             = each.value.comment
  enable_query_acceleration           = each.value.enable_query_acceleration != null ? tostring(each.value.enable_query_acceleration) : null
  query_acceleration_max_scale_factor = each.value.query_acceleration_max_scale_factor
  resource_constraint                 = each.value.resource_constraint
  generation                          = each.value.generation
  resource_monitor                    = each.value.resource_monitor
  max_concurrency_level               = each.value.max_concurrency_level
  statement_timeout_in_seconds        = each.value.statement_timeout_in_seconds
  statement_queued_timeout_in_seconds = each.value.statement_queued_timeout_in_seconds
}
