terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   public_ip_associates = {
#     "lb-nic" = {
#       project_id           = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       region               = "eu01"
#       public_ip_id         = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
#       network_interface_id = "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"
#     },
#   }
# }

inputs = {
  public_ip_associates = {}
}
