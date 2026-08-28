output "members" {
  description = "Map of \"<entry key>/<role>\" (with the condition title appended when conditional, \"<entry key>/<role>/<condition title>\") => object with service_account (fully-qualified resource name), role, member and etag, one entry per granted role. Empty unless mode = \"member\"."
  value = { for k, m in google_service_account_iam_member.member : k => {
    service_account = m.service_account_id
    role            = m.role
    member          = m.member
    etag            = m.etag
  } }
}

output "bindings" {
  description = "Map of binding key => object with service_account (fully-qualified resource name), role, members and etag. Empty unless mode = \"binding\"."
  value = { for k, b in google_service_account_iam_binding.binding : k => {
    service_account = b.service_account_id
    role            = b.role
    members         = b.members
    etag            = b.etag
  } }
}

output "policies" {
  description = "Map of service account key => object with service_account (fully-qualified resource name) and etag of the service account IAM policy. Empty unless mode = \"policy\"."
  value = { for k, p in google_service_account_iam_policy.policy : k => {
    service_account = p.service_account_id
    etag            = p.etag
  } }
}
