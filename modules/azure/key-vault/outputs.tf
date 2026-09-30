output "key_vault_ids" {
  description = "Map of vault key => full ARM resource ID (\"/subscriptions/<id>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<name>\")."
  value       = { for key, vault in azurerm_key_vault.key_vault : key => vault.id }
}

output "key_vault_uris" {
  description = "Map of vault key => vault URI (\"https://<name>.vault.azure.net/\") — the data-plane endpoint SDKs and CLIs take."
  value       = { for key, vault in azurerm_key_vault.key_vault : key => vault.vault_uri }
}

output "key_ids" {
  description = "Map of \"<vault_key>.<key_key>\" => versioned data-plane key URI (the provider's id attribute, \"https://<vault>.vault.azure.net/keys/<name>/<version>\"). Pin-sensitive consumers: a versioned URI stops matching after key rotation events — see the versionless outputs."
  value       = { for key, key_resource in azurerm_key_vault_key.key : key => key_resource.id }
}

output "key_versionless_ids" {
  description = "Map of \"<vault_key>.<key_key>\" => versionless data-plane key URI (the provider's versionless_id attribute, \"https://<vault>.vault.azure.net/keys/<name>\") — always points at the current key version."
  value       = { for key, key_resource in azurerm_key_vault_key.key : key => key_resource.versionless_id }
}

output "key_resource_versionless_ids" {
  description = "Map of \"<vault_key>.<key_key>\" => versionless ARM resource ID (the provider's resource_versionless_id attribute) — for ARM consumers (encryption settings, role assignments) that must follow key rotation."
  value       = { for key, key_resource in azurerm_key_vault_key.key : key => key_resource.resource_versionless_id }
}

output "secret_ids" {
  description = "Map of \"<vault_key>.<secret_key>\" => versioned data-plane secret URI (the provider's id attribute). Never carries the secret value itself."
  value       = { for key, secret in azurerm_key_vault_secret.secret : key => secret.id }
}

output "secret_versionless_ids" {
  description = "Map of \"<vault_key>.<secret_key>\" => versionless data-plane secret URI (the provider's versionless_id attribute) — always points at the current secret version."
  value       = { for key, secret in azurerm_key_vault_secret.secret : key => secret.versionless_id }
}

output "certificate_ids" {
  description = "Map of \"<vault_key>.<certificate_key>\" => versioned data-plane certificate URI (the provider's id attribute)."
  value       = { for key, certificate in azurerm_key_vault_certificate.certificate : key => certificate.id }
}

output "certificate_secret_ids" {
  description = "Map of \"<vault_key>.<certificate_key>\" => versioned data-plane URI of the secret carrying the certificate's PKCS#12 bundle (the provider's secret_id attribute) — the bundle consumers fetch."
  value       = { for key, certificate in azurerm_key_vault_certificate.certificate : key => certificate.secret_id }
}

output "certificate_secret_versionless_ids" {
  description = "Map of \"<vault_key>.<certificate_key>\" => versionless data-plane URI of the certificate's backing secret (the provider's versionless_secret_id attribute) — always points at the current certificate version's bundle."
  value       = { for key, certificate in azurerm_key_vault_certificate.certificate : key => certificate.versionless_secret_id }
}
