terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   services = {
#     "api" = {
#       name    = "example-api"
#       cluster = "arn:aws:ecs:us-east-1:123456789012:cluster/example-main"
#       task_definition = {
#         family                = "example-api"
#         container_definitions = jsonencode([{ name = "api", image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/example-api:latest", portMappings = [{ containerPort = 8080, protocol = "tcp" }] }])
#         cpu                   = 256
#         memory                = 512
#       }
#       network_configuration = {
#         subnets = ["subnet-0a", "subnet-0b"]
#       }
#     },
#   }
# }

inputs = {
  services = {}
}
