output "sink_names" {
  description = "Map of sink key => sink name."
  value       = { for k, s in google_logging_project_sink.sink : k => s.name }
}

output "sink_writer_identities" {
  description = "Map of sink key => writer identity to grant destination access to (a serviceAccount:... email when unique_writer_identity = true, otherwise the sink's project service account). May be an empty string until GCP provisions the identity; don't assume a value on first apply."
  value       = { for k, s in google_logging_project_sink.sink : k => s.writer_identity }
}

output "sink_filters" {
  description = "Map of sink key => effective sink filter."
  value       = { for k, s in google_logging_project_sink.sink : k => s.filter }
}
