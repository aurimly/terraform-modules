terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   sinks = {
#     "example" = {
#       name        = "example-audit-sink"
#       destination = "storage.googleapis.com/example-audit-logs"
#       filter      = "severity>=WARNING"
#     }
#   }
# }

inputs = {
  sinks = {}
}
