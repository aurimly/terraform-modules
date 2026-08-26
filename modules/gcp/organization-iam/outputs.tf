output "members" {
  description = "Map of \"<entry key>/<role>\" (with the condition title appended when conditional, \"<entry key>/<role>/<condition title>\") => object with org_id, role, member and etag, one entry per granted role. Empty unless mode = \"member\"."
  value = { for k, m in google_organization_iam_member.member : k => {
    org_id = m.org_id
    role   = m.role
    member = m.member
    etag   = m.etag
  } }
}

output "bindings" {
  description = "Map of binding key => object with org_id, role, members and etag. Empty unless mode = \"binding\"."
  value = { for k, b in google_organization_iam_binding.binding : k => {
    org_id  = b.org_id
    role    = b.role
    members = b.members
    etag    = b.etag
  } }
}

output "policy" {
  description = "Object with org_id and etag of the organization IAM policy, or null unless mode = \"policy\"."
  value = var.mode == "policy" ? {
    org_id = google_organization_iam_policy.policy[0].org_id
    etag   = google_organization_iam_policy.policy[0].etag
  } : null
}

output "audit_configs" {
  description = "Map of audit config key => object with org_id, service and etag. Empty when audit_config_enabled is false."
  value = { for k, a in google_organization_iam_audit_config.audit_config : k => {
    org_id  = a.org_id
    service = a.service
    etag    = a.etag
  } }
}
