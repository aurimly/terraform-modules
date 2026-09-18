terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   jobs = {
#     "example" = {
#       name              = "example-df-wordcount"
#       template_gcs_path = "gs://example-bucket/templates/wordcount"
#       temp_gcs_location = "gs://example-bucket/tmp"
#     }
#   }
# }

inputs = {
  jobs = {}
}
