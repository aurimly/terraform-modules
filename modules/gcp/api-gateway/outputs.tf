output "api_names" {
  description = "Map of api key => resource name (projects/{project}/locations/global/apis/{api_id})."
  value       = { for k, api in google_api_gateway_api.api : k => api.name }
}

output "api_managed_services" {
  description = "Map of api key => managed service name (the generated one when the input omitted managed_service)."
  value       = { for k, api in google_api_gateway_api.api : k => api.managed_service }
}

output "api_config_names" {
  description = "Map of config key => resource name (projects/{project}/locations/global/apis/{api}/configs/{api_config_id})."
  value       = { for k, config in google_api_gateway_api_config.api_config : k => config.name }
}

output "api_config_service_config_ids" {
  description = "Map of config key => service config id (the merged service configuration the API generated)."
  value       = { for k, config in google_api_gateway_api_config.api_config : k => config.service_config_id }
}

output "gateway_names" {
  description = "Map of gateway key => resource name (projects/{project}/locations/{region}/gateways/{gateway_id})."
  value       = { for k, gateway in google_api_gateway_gateway.gateway : k => gateway.name }
}

output "gateway_default_hostnames" {
  description = "Map of gateway key => default hostname ({gateway_id}-{hash}.{region_code}.gateway.dev) — the URL clients call."
  value       = { for k, gateway in google_api_gateway_gateway.gateway : k => gateway.default_hostname }
}

output "gateway_effective_labels" {
  description = "Map of gateway key => all labels present on the gateway in GCP (including labels set outside this module)."
  value       = { for k, gateway in google_api_gateway_gateway.gateway : k => gateway.effective_labels }
}
