terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   topics = {
#     "events" = {
#       name         = "example-events"
#       display_name = "example"
#     },
#   }
# }

inputs = {
  topics = {}
}
