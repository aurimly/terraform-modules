output "function_ids" {
  description = "Map of function key => full resource path (projects/<project>/locations/<location>/functions/<name>)."
  value       = { for k, f in google_cloudfunctions2_function.function : k => f.id }
}

output "function_urls" {
  description = "Map of function key => deployed HTTPS URL (HTTP-triggered functions only)."
  value       = { for k, f in google_cloudfunctions2_function.function : k => f.url }
}

output "function_states" {
  description = "Map of function key => current state (ACTIVE, FAILED, DEPLOYING, DELETING or UNKNOWN)."
  value       = { for k, f in google_cloudfunctions2_function.function : k => f.state }
}

output "function_runtime_services" {
  description = "Map of function key => the backing Cloud Run service name (null when service_config is omitted)."
  value = {
    for k, f in google_cloudfunctions2_function.function : k => try(f.service_config[0].service, null)
  }
}
