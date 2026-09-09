output "keyring_ids" {
  description = "Map of keyring key => fully-qualified key ring id (projects/.../locations/.../keyRings/...)."
  value       = { for k, kr in google_kms_key_ring.keyring : k => kr.id }
}

output "crypto_key_ids" {
  description = "Map of composite key (keyring key/key key) => fully-qualified crypto key id (projects/.../keyRings/.../cryptoKeys/...)."
  value       = { for k, ck in google_kms_crypto_key.key : k => ck.id }
}

output "crypto_key_names" {
  description = "Map of composite key (keyring key/key key) => crypto key name."
  value       = { for k, ck in google_kms_crypto_key.key : k => ck.name }
}

output "keyring_binding_roles" {
  description = "Map of key ring IAM binding composite key (keyring key/binding key) => role."
  value       = { for k, b in google_kms_key_ring_iam_binding.binding : k => b.role }
}

output "crypto_key_binding_roles" {
  description = "Map of crypto key IAM binding composite key (keyring key/key key/binding key) => role."
  value       = { for k, b in google_kms_crypto_key_iam_binding.binding : k => b.role }
}
