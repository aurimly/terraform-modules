terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   pools = {
#     "ci" = {
#       pool_id      = "example-ci-pool"
#       display_name = "CI federation",
#       providers = {
#         "gh" = {
#           provider_id  = "example-gh-oidc"
#           display_name = "GitHub Actions",
#           attribute_mapping = {
#             "google.subject"       = "assertion.sub"
#             "attribute.repository" = "assertion.repository",
#           },
#           oidc = {
#             issuer_uri = "https://token.actions.githubusercontent.com",
#           },
#           token_creators = {
#             "deployer" = {
#               service_account = "deploy-rt@example-prj.iam.gserviceaccount.com"
#               member          = "principalSet://iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/example-ci-pool/attribute.repository/example-org/example-repo",
#             },
#           },
#         },
#       },
#     },
#   }
# }

inputs = {
  pools = {}
}
