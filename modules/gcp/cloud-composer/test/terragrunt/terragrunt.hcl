terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   environments = {
#     "example" = {
#       name   = "example-airflow"
#       region = "europe-west1"
#     }
#   }
# }

inputs = {
  environments = {}
}
