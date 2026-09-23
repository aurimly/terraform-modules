output "key_ids" {
  description = "Map of key key => key ID (UUID-like; multi-region keys carry the mrk- prefix)."
  value       = { for k, k2 in aws_kms_key.key : k => k2.key_id }
}

output "key_arns" {
  description = "Map of key key => key ARN."
  value       = { for k, k2 in aws_kms_key.key : k => k2.arn }
}

output "alias_arns" {
  description = "Map of \"key-key.alias-key\" => alias ARN."
  value       = { for k, a in aws_kms_alias.alias : k => a.arn }
}

output "alias_names" {
  description = "Map of \"key-key.alias-key\" => alias name (alias/name — also the aws_kms_alias import ID)."
  value       = { for k, a in aws_kms_alias.alias : k => a.name }
}
