terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   roles = {
#     "ec2-app" = {
#       name                    = "example-ec2-app"
#       create_instance_profile = true
#       trust = {
#         principal_type = "Service"
#         identifiers    = ["ec2.amazonaws.com"]
#       }
#       managed_policy_arns = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]
#     },
#     "ci-deployer" = {
#       name              = "example-ci-deployer"
#       trust_policy_json = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { AWS = "arn:aws:iam::123456789012:root" }, Action = "sts:AssumeRole" }] })
#     },
#   }
# }

inputs = {
  roles = {}
}
