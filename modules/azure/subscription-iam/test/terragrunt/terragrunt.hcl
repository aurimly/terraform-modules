terraform {
  source = "../../"
}

# Example inputs (commented). To validate against Azure, replace the inputs
# below with real values (needs Azure creds). terragrunt validate with the
# placeholder GUIDs needs no Azure creds — nothing here calls the API.
#
# inputs = {
#   subscription_id = "12345678-1234-5678-9012-123456789012"
#   role_assignments = {
#     "viewers" = {
#       role_definition_name = "Reader"
#       principal_id         = "aabbccdd-1122-3344-5566-778899aabbcc"
#       principal_type       = "Group"
#     }
#   }
# }

inputs = {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  role_assignments = {
    "viewers" = {
      role_definition_name = "Reader"
      principal_id         = "aabbccdd-1122-3344-5566-778899aabbcc"
      principal_type       = "Group"
    }
  }
}
