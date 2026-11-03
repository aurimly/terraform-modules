output "user_names" {
  description = "Map of user key => user name."
  value       = { for k, u in aws_iam_user.user : k => u.name }
}

output "user_arns" {
  description = "Map of user key => user ARN."
  value       = { for k, u in aws_iam_user.user : k => u.arn }
}

output "user_unique_ids" {
  description = "Map of user key => user unique ID (AIDA...)."
  value       = { for k, u in aws_iam_user.user : k => u.unique_id }
}

output "access_key_ids" {
  description = "Map of user key => access key ID, null for users without an access_key. Covers all user keys."
  value       = { for k, v in var.users : k => v.access_key != null ? aws_iam_access_key.key[k].id : null }
}

output "access_key_secrets" {
  description = "Map of user key => secret access key, null for users without an access_key or with a pgp_key. Covers all user keys; stored in the Terraform state file."
  sensitive   = true
  value       = { for k, v in var.users : k => v.access_key != null && v.access_key.pgp_key == null ? aws_iam_access_key.key[k].secret : null }
}

output "access_key_encrypted_secrets" {
  description = "Map of user key => PGP-encrypted secret (base64), null for users without an access_key or pgp_key. Covers all user keys."
  value       = { for k, v in var.users : k => v.access_key != null && v.access_key.pgp_key != null ? aws_iam_access_key.key[k].encrypted_secret : null }
}
