output "instances" {
  description = "Map of instance key => object with `instance_id`, `plan_id`, `dashboard_url`, `grafana_url`, `grafana_public_read_access`, `alerting_url`, `metrics_url`, `metrics_push_url`, `targets_url`, `logs_url`, `logs_push_url`, `jaeger_traces_url`, `jaeger_ui_url`, `otlp_grpc_traces_url`, `otlp_http_logs_url`, `otlp_http_traces_url`, `otlp_traces_url`, `zipkin_spans_url`, `is_updatable` and `id` (\"{project_id},{instance_id}\", the import ID)."
  value = { for k, i in stackit_observability_instance.instance : k => {
    instance_id                = i.instance_id
    plan_id                    = i.plan_id
    dashboard_url              = i.dashboard_url
    grafana_url                = i.grafana_url
    grafana_public_read_access = i.grafana_public_read_access
    alerting_url               = i.alerting_url
    metrics_url                = i.metrics_url
    metrics_push_url           = i.metrics_push_url
    targets_url                = i.targets_url
    logs_url                   = i.logs_url
    logs_push_url              = i.logs_push_url
    jaeger_traces_url          = i.jaeger_traces_url
    jaeger_ui_url              = i.jaeger_ui_url
    otlp_grpc_traces_url       = i.otlp_grpc_traces_url
    otlp_http_logs_url         = i.otlp_http_logs_url
    otlp_http_traces_url       = i.otlp_http_traces_url
    otlp_traces_url            = i.otlp_traces_url
    zipkin_spans_url           = i.zipkin_spans_url
    is_updatable               = i.is_updatable
    id                         = i.id
  } }
}
