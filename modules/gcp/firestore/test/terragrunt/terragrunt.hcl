terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   databases = {
#     "default" = {
#       name        = "(default)"
#       location_id = "nam5"
#       type        = "FIRESTORE_NATIVE"
#     }
#   }
# }

inputs = {
  databases = {}
}
