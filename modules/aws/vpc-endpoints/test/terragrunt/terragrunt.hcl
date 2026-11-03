terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   vpc_endpoints = {
#     "s3" = {
#       vpc_endpoint_type = "Gateway"
#       vpc_id            = "vpc-0123456789abcdef0"
#       service_name      = "com.amazonaws.us-east-1.s3"
#       route_table_ids   = ["rtb-0123456789abcdef0"]
#     }
#     "kms" = {
#       vpc_id              = "vpc-0123456789abcdef0"
#       service_name        = "com.amazonaws.us-east-1.kms"
#       subnet_ids          = ["subnet-0123456789abcdef0"]
#       security_group_ids  = ["sg-0123456789abcdef0"]
#       private_dns_enabled = true
#     }
#   }
# }

inputs = {
  vpc_endpoints = {}
}
