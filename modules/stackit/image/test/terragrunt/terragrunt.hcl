terraform {
  source = "../../"
}

# Example inputs (commented). To validate against STACKIT, replace the inputs
# below with real values (needs STACKIT creds). terragrunt validate with an
# empty map needs no creds.
#
# inputs = {
#   images = {
#     "ubuntu" = {
#       project_id      = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#       region          = "eu01"
#       name            = "ubuntu-2404-custom"
#       disk_format     = "qcow2"
#       local_file_path = "/path/to/ubuntu-24.04.qcow2"
#       min_disk_size   = 10
#       min_ram         = 512
#       config = {
#         disk_bus    = "virtio"
#         virtio_scsi = true
#       }
#       labels = {
#         "env" = "prod"
#       }
#     },
#   }
# }

inputs = {
  images = {}
}
