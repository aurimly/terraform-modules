output "endpoint_ids" {
  description = "Map of endpoint key => endpoint id (projects/{project}/locations/{location}/endpoints/{name})."
  value       = { for k, s in google_vertex_ai_endpoint.endpoint : k => s.id }
}

output "endpoint_names" {
  description = "Map of endpoint key => endpoint name (the numeric endpoint id)."
  value       = { for k, s in google_vertex_ai_endpoint.endpoint : k => s.name }
}

output "endpoint_dedicated_endpoint_dns" {
  description = "Map of endpoint key => dedicated endpoint DNS. Populated only when dedicated_endpoint_enabled is true."
  value       = { for k, s in google_vertex_ai_endpoint.endpoint : k => s.dedicated_endpoint_dns }
}

output "endpoint_deployed_models" {
  description = "Map of endpoint key => deployed_models list (output-only; read deployed-model ids here for traffic_split wiring)."
  value       = { for k, s in google_vertex_ai_endpoint.endpoint : k => s.deployed_models }
}

output "model_garden_deployed_model_ids" {
  description = "Map of model garden deployment key => deployed_model_id assigned by Vertex AI at deploy time."
  value       = { for k, s in google_vertex_ai_endpoint_with_model_garden_deployment.model_garden : k => s.deployed_model_id }
}

output "model_garden_endpoint_ids" {
  description = "Map of model garden deployment key => endpoint id segment of the created endpoint."
  value       = { for k, s in google_vertex_ai_endpoint_with_model_garden_deployment.model_garden : k => s.endpoint }
}
