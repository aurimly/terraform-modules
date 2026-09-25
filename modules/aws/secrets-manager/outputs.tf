output "secret_arns" {
  description = "Map of secret key => secret ARN."
  value       = { for k, s in aws_secretsmanager_secret.secret : k => s.arn }
}

output "secret_names" {
  description = "Map of secret key => resolved secret name."
  value       = { for k, s in aws_secretsmanager_secret.secret : k => s.name }
}

output "secret_version_ids" {
  description = "Map of secret key => version ID for entries that carry a payload (absent for out-of-band entries)."
  value       = { for k, v in aws_secretsmanager_secret_version.version : k => v.version_id }
}
