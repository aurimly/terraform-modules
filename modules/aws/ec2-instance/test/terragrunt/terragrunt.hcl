terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   instances = {
#     "app" = {
#       name                = "example-app"
#       instance_type       = "t3.micro"
#       subnet_id           = "subnet-0123456789abcdef0"
#       ami_ssm_parameter   = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
#       security_group_ids  = ["sg-0123456789abcdef0"]
#       root_block_device = {
#         volume_size = 20
#         encrypted   = true
#       }
#       ebs_block_devices = {
#         "data" = {
#           device_name = "/dev/sdf"
#           volume_size = 50
#         }
#       }
#     },
#   }
# }

inputs = {
  instances = {}
}
