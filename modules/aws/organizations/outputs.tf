output "organization_id" {
  description = "Organization ID (o-...) — null when the module runs attach-only (organization = null)."
  value       = one([for o in aws_organizations_organization.org : o.id])
}

output "organization_arn" {
  description = "Organization ARN — null when attach-only."
  value       = one([for o in aws_organizations_organization.org : o.arn])
}

output "organization_master_account_id" {
  description = "Management (master) account ID of the organization — null when attach-only."
  value       = one([for o in aws_organizations_organization.org : o.master_account_id])
}

output "root_id" {
  description = "Organization root ID (r-...) — null when attach-only. Use as the parent for consumer-side OUs or as attachment targets."
  value       = local.root_id
}

output "organization_account_names" {
  description = "Map of account ID => account name for all accounts in the organization, including the management account (read-only view; accounts are adopted by reference) — null when attach-only."
  value       = var.organization != null ? { for a in aws_organizations_organization.org[0].accounts : a.id => a.name } : null
}

output "ou_ids" {
  description = "Map of OU key => OU ID (ou-...)."
  value       = local.ou_ids
}

output "ou_arns" {
  description = "Map of OU key => OU ARN."
  value       = local.ou_arns
}

output "policy_ids" {
  description = "Map of policy key => policy ID (p-...) — also the aws_organizations_policy import ID."
  value       = { for k, p in aws_organizations_policy.policy : k => p.id }
}

output "policy_arns" {
  description = "Map of policy key => policy ARN."
  value       = { for k, p in aws_organizations_policy.policy : k => p.arn }
}

output "attachment_policy_ids" {
  description = "Map of \"attachment-key.target-key\" => attached policy ID. Import ID format is \"<target_id>:<policy_id>\" (note the reversed order)."
  value       = { for k, a in aws_organizations_policy_attachment.attachment : k => a.policy_id }
}

output "attachment_target_ids" {
  description = "Map of \"attachment-key.target-key\" => target ID (r-..., ou-... or account ID). Import ID format is \"<target_id>:<policy_id>\"."
  value       = local.attachment_target_ids
}

output "delegated_administrator_arns" {
  description = "Map of delegated-administrator key => delegation ARN (also the import key alongside account_id/service_principal)."
  value       = { for k, d in aws_organizations_delegated_administrator.delegated : k => d.arn }
}
