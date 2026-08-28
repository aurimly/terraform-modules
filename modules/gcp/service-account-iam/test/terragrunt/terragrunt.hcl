terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with the defaults
# needs no creds.
#
# inputs = {
#   service_accounts = {
#     "app" = "projects/my-project/serviceAccounts/app-prod@my-project.iam.gserviceaccount.com"
#   }
#   members = {
#     "ci-impersonation" = {
#       service_account = "app"
#       member          = "serviceAccount:ci-runner@my-project.iam.gserviceaccount.com"
#       roles           = ["roles/iam.serviceAccountUser"]
#     }
#   }
# }

inputs = {
  service_accounts = {
    "app" = "projects/my-project/serviceAccounts/app-prod@my-project.iam.gserviceaccount.com"
  }
}
