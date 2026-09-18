output "index_endpoint_ids" {
  description = "Map of index endpoint key => index endpoint id (projects/{project}/locations/{region}/indexEndpoints/{name}). Wire this into deployed_indexes[*].index_endpoint."
  value       = { for k, e in google_vertex_ai_index_endpoint.index_endpoint : k => e.id }
}

output "index_endpoint_names" {
  description = "Map of index endpoint key => resource name of the index endpoint (Google-assigned)."
  value       = { for k, e in google_vertex_ai_index_endpoint.index_endpoint : k => e.name }
}

output "index_endpoint_public_endpoint_domain_names" {
  description = "Map of index endpoint key => public endpoint domain name. Populated only when public_endpoint_enabled is true."
  value       = { for k, e in google_vertex_ai_index_endpoint.index_endpoint : k => e.public_endpoint_domain_name }
}

output "deployed_index_ids" {
  description = "Map of deployed index key => deployed_index_id as assigned in the configuration."
  value       = { for k, d in google_vertex_ai_index_endpoint_deployed_index.deployed_index : k => d.deployed_index_id }
}

output "deployed_index_names" {
  description = "Map of deployed index key => resource name of the deployed index (Google-assigned)."
  value       = { for k, d in google_vertex_ai_index_endpoint_deployed_index.deployed_index : k => d.name }
}

output "deployed_index_private_endpoints" {
  description = "Map of deployed index key => private endpoints list ({match_grpc_address, service_attachment, psc_automated_endpoints}); populated when the index endpoint uses network peering or PSC."
  value = {
    for k, d in google_vertex_ai_index_endpoint_deployed_index.deployed_index : k => flatten([
      for pe in try(d.private_endpoints, []) : [
        {
          match_grpc_address = pe.match_grpc_address
          service_attachment = pe.service_attachment
          psc_automated_endpoints = flatten([
            for pae in try(pe.psc_automated_endpoints, []) : [
              {
                match_address = pae.match_address
                project_id    = pae.project_id
                network       = pae.network
              }
            ]
          ])
        }
      ]
    ])
  }
}

output "deployed_index_sync_times" {
  description = "Map of deployed index key => index_sync_time (RFC3339 UTC \"Zulu\" format). Compare against the vertex-ai-index module's index_update_times for the source index to check whether a deployed index has caught up with a batch update."
  value       = { for k, d in google_vertex_ai_index_endpoint_deployed_index.deployed_index : k => d.index_sync_time }
}
