terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with the defaults
# needs no creds.
#
# inputs = {
#   service_account_keys = {
#     "api" = {
#       service_account = "api-rt@example-prj.iam.gserviceaccount.com"
#       keepers = {
#         rotation_epoch = "1"
#       }
#     }
#   }
# }

inputs = {
  service_account_keys = {
    "example" = {
      service_account = "api-rt@example-prj.iam.gserviceaccount.com"
    }
  }
}
