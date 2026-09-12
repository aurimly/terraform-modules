terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   functions = {
#     "example" = {
#       name     = "example-http-fn"
#       location = "europe-west4"
#       build_config = {
#         runtime = "nodejs20"
#         source = {
#           storage_source = {
#             bucket = "example-gcf-source"
#             object = "function-source.zip"
#           }
#         }
#       }
#     }
#   }
# }

inputs = {
  functions = {}
}
