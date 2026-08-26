output "org_policies" {
  description = "Map of policy key => object with `id`, `name`, `parent`, `etag` and the `spec` / `dry_run_spec` blocks as returned by GCP."
  value = { for k, p in google_org_policy_policy.org_policy : k => {
    id           = p.id
    name         = p.name
    parent       = p.parent
    etag         = p.etag
    spec         = p.spec
    dry_run_spec = p.dry_run_spec
  } }
}
