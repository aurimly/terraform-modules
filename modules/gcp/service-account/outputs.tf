output "service_accounts" {
  description = "Map of service account key => object with `email`, `member` (\"serviceAccount:<email>\"), `name` (fully-qualified resource name \"projects/<project>/serviceAccounts/<email>\", usable as the values of the gcp/service-account-iam module's service_accounts input), `unique_id` and `project`."
  value = { for k, sa in google_service_account.service_account : k => {
    email     = sa.email
    member    = sa.member
    name      = sa.name
    unique_id = sa.unique_id
    project   = sa.project
  } }
}
