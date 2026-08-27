output "members" {
  description = "Map of \"<entry key>/<role>\" (with the condition title appended when conditional, \"<entry key>/<role>/<condition title>\") => object with project, role, member and etag, one entry per granted role. Empty unless mode = \"member\"."
  value = { for k, m in google_project_iam_member.member : k => {
    project = m.project
    role    = m.role
    member  = m.member
    etag    = m.etag
  } }
}

output "bindings" {
  description = "Map of binding key => object with project, role, members and etag. Empty unless mode = \"binding\"."
  value = { for k, b in google_project_iam_binding.binding : k => {
    project = b.project
    role    = b.role
    members = b.members
    etag    = b.etag
  } }
}

output "policy" {
  description = "Object with project and etag of the project IAM policy, or null unless mode = \"policy\"."
  value = var.mode == "policy" ? {
    project = google_project_iam_policy.policy[0].project
    etag    = google_project_iam_policy.policy[0].etag
  } : null
}

output "audit_configs" {
  description = "Map of audit config key => object with project, service and etag. Empty when audit_config_enabled is false."
  value = { for k, a in google_project_iam_audit_config.audit_config : k => {
    project = a.project
    service = a.service
    etag    = a.etag
  } }
}
