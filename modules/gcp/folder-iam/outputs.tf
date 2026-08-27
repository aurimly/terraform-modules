output "members" {
  description = "Map of \"<entry key>/<role>\" (with the condition title appended when conditional, \"<entry key>/<role>/<condition title>\") => object with folder, role, member and etag, one entry per granted role. Empty unless mode = \"member\"."
  value = { for k, m in google_folder_iam_member.member : k => {
    folder = m.folder
    role   = m.role
    member = m.member
    etag   = m.etag
  } }
}

output "bindings" {
  description = "Map of binding key => object with folder, role, members and etag. Empty unless mode = \"binding\"."
  value = { for k, b in google_folder_iam_binding.binding : k => {
    folder  = b.folder
    role    = b.role
    members = b.members
    etag    = b.etag
  } }
}

output "policy" {
  description = "Object with folder and etag of the folder IAM policy, or null unless mode = \"policy\"."
  value = var.mode == "policy" ? {
    folder = google_folder_iam_policy.policy[0].folder
    etag   = google_folder_iam_policy.policy[0].etag
  } : null
}

output "audit_configs" {
  description = "Map of audit config key => object with folder, service and etag. Empty when audit_config_enabled is false."
  value = { for k, a in google_folder_iam_audit_config.audit_config : k => {
    folder  = a.folder
    service = a.service
    etag    = a.etag
  } }
}
