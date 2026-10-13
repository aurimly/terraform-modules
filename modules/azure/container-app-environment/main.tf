resource "azurerm_container_app_environment" "environment" {
  for_each = var.container_app_environments

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  logs_destination                            = each.value.logs_destination
  log_analytics_workspace_id                  = each.value.log_analytics_workspace_id
  dapr_application_insights_connection_string = each.value.dapr_application_insights_connection_string

  infrastructure_subnet_id           = each.value.infrastructure_subnet_id
  infrastructure_resource_group_name = each.value.infrastructure_resource_group_name
  internal_load_balancer_enabled     = each.value.internal_load_balancer_enabled
  zone_redundancy_enabled            = each.value.zone_redundancy_enabled
  public_network_access              = each.value.public_network_access
  mutual_tls_enabled                 = each.value.mutual_tls_enabled

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "workload_profile" {
    for_each = each.value.workload_profile
    content {
      name                  = workload_profile.value.name
      workload_profile_type = workload_profile.value.workload_profile_type
      maximum_count         = workload_profile.value.maximum_count
      minimum_count         = workload_profile.value.minimum_count
    }
  }

  tags = each.value.tags
}
