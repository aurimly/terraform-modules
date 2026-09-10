terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   servers = {
#     "app" = {
#       project_id        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       region            = "eu01"
#       name              = "app-server"
#       machine_type      = "s3.2xlarge.8"
#       availability_zone = "eu01-3"
#       image_id          = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       keypair_name      = "deploy-key"
#       network_interface_ids = [
#         "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#       ]
#       user_data = <<-EOT
#         #cloud-config
#         packages: [nginx]
#       EOT
#       labels = {
#         "env" = "prod"
#       }
#     },
#     "boot-from-volume" = {
#       project_id        = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       region            = "eu01"
#       name              = "app-server-2"
#       machine_type      = "s3.2xlarge.8"
#       availability_zone = "eu01-3"
#       boot_volume = {
#         source_type           = "volume"
#         source_id             = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#         performance_class     = "storage_premium_perf2"
#       }
#       network_interface_ids = [
#         "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#       ]
#     },
#   }
# }

inputs = {
  servers = {}
}
