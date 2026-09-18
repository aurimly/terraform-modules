output "index_ids" {
  description = "Map of index key => index id (projects/{project}/locations/{region}/indexes/{name}). Wire this into the vertex-ai-index-endpoint module's deployed_indexes[*].index."
  value       = { for k, i in google_vertex_ai_index.index : k => i.id }
}

output "index_names" {
  description = "Map of index key => resource name of the index (Google-assigned)."
  value       = { for k, i in google_vertex_ai_index.index : k => i.name }
}

output "index_deployed_indexes" {
  description = "Map of index key => deployed_indexes list (output-only pointers to deployed indexes created from this index: {deployed_index_id, index_endpoint})."
  value       = { for k, i in google_vertex_ai_index.index : k => i.deployed_indexes }
}

output "index_stats" {
  description = "Map of index key => index stats ({shards_count, vectors_count}); populated once the index contains data."
  value = {
    for k, i in google_vertex_ai_index.index : k => flatten([
      for s in try(i.index_stats, []) : [
        {
          shards_count  = s.shards_count
          vectors_count = s.vectors_count
        }
      ]
    ])
  }
}

output "index_update_times" {
  description = "Map of index key => last update timestamp (RFC3339 UTC \"Zulu\" format). Compare against the vertex-ai-index-endpoint module's deployed_index_sync_times to check whether a deployed index has caught up with a batch update."
  value       = { for k, i in google_vertex_ai_index.index : k => i.update_time }
}
