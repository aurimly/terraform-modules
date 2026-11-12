variable "account_id" {
  description = "Cloudflare account ID. Notification resources are account-scoped; all webhooks and policies live in this account."
  type        = string
}

variable "webhooks" {
  description = "Map of webhook destinations keyed by an arbitrary identifier. Each entry creates one cloudflare_notification_policy_webhooks; referenced from policies by key in mechanisms.webhooks."
  type = map(object({
    name   = string
    url    = string
    secret = optional(string)
  }))
  default = {}
}

variable "policies" {
  description = "Map of notification policies keyed by an arbitrary identifier. Each entry creates one cloudflare_notification_policy in the account."
  type = map(object({
    name           = string
    alert_type     = string
    description    = optional(string)
    enabled        = optional(bool, true)
    alert_interval = optional(string)
    filters = optional(object({
      actions                         = optional(list(string))
      affected_asns                   = optional(list(string))
      affected_components             = optional(list(string))
      affected_locations              = optional(list(string))
      airport_code                    = optional(list(string))
      alert_trigger_preferences       = optional(list(string))
      alert_trigger_preferences_value = optional(list(string))
      enabled                         = optional(list(string))
      environment                     = optional(list(string))
      event                           = optional(list(string))
      event_source                    = optional(list(string))
      event_type                      = optional(list(string))
      group_by                        = optional(list(string))
      health_check_id                 = optional(list(string))
      incident_impact                 = optional(list(string))
      input_id                        = optional(list(string))
      insight_class                   = optional(list(string))
      limit                           = optional(list(string))
      logo_tag                        = optional(list(string))
      megabits_per_second             = optional(list(string))
      new_health                      = optional(list(string))
      new_status                      = optional(list(string))
      packets_per_second              = optional(list(string))
      pool_id                         = optional(list(string))
      pop_names                       = optional(list(string))
      product                         = optional(list(string))
      project_id                      = optional(list(string))
      protocol                        = optional(list(string))
      query_tag                       = optional(list(string))
      requests_per_second             = optional(list(string))
      selectors                       = optional(list(string))
      services                        = optional(list(string))
      slo                             = optional(list(string))
      status                          = optional(list(string))
      target_hostname                 = optional(list(string))
      target_ip                       = optional(list(string))
      target_zone_name                = optional(list(string))
      token_id                        = optional(list(string))
      traffic_exclusions              = optional(list(string))
      tunnel_id                       = optional(list(string))
      tunnel_name                     = optional(list(string))
      type                            = optional(list(string))
      where                           = optional(list(string))
      zones                           = optional(list(string))
    }), {})
    mechanisms = object({
      email     = optional(list(string))
      pagerduty = optional(list(string))
      webhooks  = optional(list(string))
    })
  }))
  default = {}

  validation {
    condition = alltrue([for p in var.policies : contains([
      "abuse_report_alert", "access_custom_certificate_expiration_type", "advanced_ddos_attack_l4_alert", "advanced_ddos_attack_l7_alert",
      "advanced_http_alert_error", "bgp_hijack_notification", "billing_usage_alert", "block_notification_block_removed",
      "block_notification_new_block", "block_notification_review_rejected", "bot_traffic_basic_alert", "brand_protection_alert",
      "brand_protection_digest", "clickhouse_alert_fw_anomaly", "clickhouse_alert_fw_ent_anomaly", "cloudforce_one_request_notification",
      "cni_maintenance_notification", "custom_analytics", "custom_bot_detection_alert", "custom_ssl_certificate_event_type",
      "dedicated_ssl_certificate_event_type", "device_connectivity_anomaly_alert", "dos_attack_l4", "dos_attack_l7",
      "expiring_service_token_alert", "failing_logpush_job_disabled_alert", "fbm_auto_advertisement", "fbm_dosd_attack",
      "fbm_volumetric_attack", "health_check_status_notification", "hostname_aop_custom_certificate_expiration_type", "http_alert_edge_error",
      "http_alert_origin_error", "image_notification", "image_resizing_notification", "incident_alert",
      "load_balancing_health_alert", "load_balancing_pool_enablement_alert", "logo_match_alert", "magic_tunnel_health_check_event",
      "magic_wan_tunnel_health", "maintenance_event_notification", "mtls_certificate_store_certificate_expiration_type", "pages_event_alert",
      "radar_notification", "real_origin_monitoring", "scriptmonitor_alert_new_code_change_detections", "scriptmonitor_alert_new_hosts",
      "scriptmonitor_alert_new_malicious_hosts", "scriptmonitor_alert_new_malicious_scripts", "scriptmonitor_alert_new_malicious_url", "scriptmonitor_alert_new_max_length_resource_url",
      "scriptmonitor_alert_new_resources", "secondary_dns_all_primaries_failing", "secondary_dns_primaries_failing", "secondary_dns_warning",
      "secondary_dns_zone_successfully_updated", "secondary_dns_zone_validation_warning", "security_insights_alert", "sentinel_alert",
      "stream_live_notifications", "synthetic_test_latency_alert", "synthetic_test_low_availability_alert", "traffic_anomalies_alert",
      "tunnel_health_event", "tunnel_update_event", "universal_ssl_event_type", "web_analytics_metrics_update",
      "zone_aop_custom_certificate_expiration_type",
    ], lower(p.alert_type))])
    error_message = "alert_type must be one of the alert types the provider accepts (case-insensitive, matching the provider). New Cloudflare alert types require a module release that extends the list."
  }

  validation {
    condition = alltrue(flatten([for p in var.policies : [for i in(p.filters.incident_impact != null ? p.filters.incident_impact : []) :
      contains(["INCIDENT_IMPACT_NONE", "INCIDENT_IMPACT_MINOR", "INCIDENT_IMPACT_MAJOR", "INCIDENT_IMPACT_CRITICAL"], upper(i))
    ]]))
    error_message = "filters.incident_impact entries must be NONE, MINOR, MAJOR or CRITICAL (case-insensitive, matching the API validators)."
  }
}
