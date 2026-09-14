output "job_ids" {
  description = "Map of job key => job id."
  value       = { for k, j in google_cloud_scheduler_job.job : k => j.id }
}

output "job_names" {
  description = "Map of job key => job name."
  value       = { for k, j in google_cloud_scheduler_job.job : k => j.name }
}

output "job_states" {
  description = "Map of job key => job state."
  value       = { for k, j in google_cloud_scheduler_job.job : k => j.state }
}
