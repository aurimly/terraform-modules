output "job_ids" {
  description = "Map of job key => job id."
  value       = { for k, j in google_dataflow_job.job : k => j.job_id }
}

output "job_states" {
  description = "Map of job key => current job state (JobState enum)."
  value       = { for k, j in google_dataflow_job.job : k => j.state }
}
