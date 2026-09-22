terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   subnets = {
#     "public-a" = {
#       name              = "example-public-us-east-1a"
#       vpc_id            = "vpc-0123456789abcdef0"
#       cidr_block        = "10.0.1.0/24"
#       availability_zone = "us-east-1a"
#       map_public_ip_on_launch = true
#     },
#     "private-a" = {
#       name              = "example-private-us-east-1a"
#       vpc_id            = "vpc-0123456789abcdef0"
#       cidr_block        = "10.0.11.0/24"
#       availability_zone = "us-east-1a"
#     },
#   }
# }

inputs = {
  subnets = {}
}
