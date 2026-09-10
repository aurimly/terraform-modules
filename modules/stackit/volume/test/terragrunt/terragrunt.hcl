terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   volumes = {
#     "data" = {
#       project_id        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       region            = "eu01"
#       availability_zone = "eu01-3"
#       name              = "app-data"
#       size              = 100
#       performance_class = "storage_premium_perf2"
#       labels = {
#         "env" = "prod"
#       }
#     },
#     "from-image" = {
#       project_id        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       region            = "eu01"
#       availability_zone = "eu01-3"
#       name              = "app-boot"
#       size              = 20
#       source = {
#         type = "image"
#         id   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       }
#     },
#     "encrypted" = {
#       project_id        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       region            = "eu01"
#       availability_zone = "eu01-3"
#       size              = 50
#       encryption_parameters = {
#         service_account    = "some-sa@some-project.iam.sa.stackit.cloud"
#         kek_keyring_id     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#         kek_key_id         = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#         kek_key_version    = 1
#         key_payload_base64 = "QmFzZTY0RW5jcnlwdGVkS2V5"
#       }
#     },
#   }
# }

inputs = {
  volumes = {}
}
