output "job_names" {
  description = "Map of job key => job name."
  value       = { for k, j in google_cloud_run_v2_job.job : k => j.name }
}

output "job_ids" {
  description = "Map of job key => job id."
  value       = { for k, j in google_cloud_run_v2_job.job : k => j.id }
}

output "iam_binding_roles" {
  description = "Map of IAM binding composite key (job key/binding key) => role."
  value       = { for k, b in google_cloud_run_v2_job_iam_binding.binding : k => b.role }
}
