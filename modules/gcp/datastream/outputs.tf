output "private_connection_ids" {
  description = "Map of private connection key => resource id."
  value       = { for k, c in google_datastream_private_connection.private_connections : k => c.id }
}

output "private_connection_states" {
  description = "Map of private connection key => state."
  value       = { for k, c in google_datastream_private_connection.private_connections : k => c.state }
}

output "connection_profile_ids" {
  description = "Map of connection profile key => resource id (projects/{project}/locations/{location}/connectionProfiles/{id})."
  value       = { for k, p in google_datastream_connection_profile.connection_profiles : k => p.id }
}

output "stream_ids" {
  description = "Map of stream key => resource id."
  value       = { for k, s in google_datastream_stream.streams : k => s.id }
}

output "stream_states" {
  description = "Map of stream key => current stream state."
  value       = { for k, s in google_datastream_stream.streams : k => s.state }
}
