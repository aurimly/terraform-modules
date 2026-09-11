output "pool_names" {
  description = "Map of pool key => pool resource name (projects/{project_number}/locations/global/workloadIdentityPools/{pool_id})."
  value       = { for k, p in google_iam_workload_identity_pool.pool : k => p.name }
}

output "pool_ids" {
  description = "Map of pool key => pool ID."
  value       = { for k, p in google_iam_workload_identity_pool.pool : k => p.workload_identity_pool_id }
}

output "provider_names" {
  description = "Map of provider composite key (pool key/provider key) => provider resource name (projects/{project_number}/locations/global/workloadIdentityPools/{pool_id}/providers/{provider_id})."
  value       = { for k, p in google_iam_workload_identity_pool_provider.provider : k => p.name }
}

output "provider_ids" {
  description = "Map of provider composite key (pool key/provider key) => provider ID."
  value       = { for k, p in google_iam_workload_identity_pool_provider.provider : k => p.workload_identity_pool_provider_id }
}

output "token_creator_members" {
  description = "Map of token-creator composite key (pool key/provider key/creator key) => IAM member (the WIF principal URI)."
  value       = { for k, m in google_service_account_iam_member.token_creator : k => m.member }
}
