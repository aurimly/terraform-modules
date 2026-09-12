terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_observability_instance" "instance" {
  for_each = var.instances

  project_id                             = each.value.project_id
  name                                   = each.value.name
  plan_name                              = each.value.plan_name
  acl                                    = each.value.acl
  alert_config                           = each.value.alert_config
  grafana_admin_enabled                  = each.value.grafana_admin_enabled
  logs_retention_days                    = each.value.logs_retention_days
  traces_retention_days                  = each.value.traces_retention_days
  metrics_retention_days                 = each.value.metrics_retention_days
  metrics_retention_days_5m_downsampling = each.value.metrics_retention_days_5m_downsampling
  metrics_retention_days_1h_downsampling = each.value.metrics_retention_days_1h_downsampling
  parameters                             = each.value.parameters
}
