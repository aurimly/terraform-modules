terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   rules = {
#     "docker-hub" = {
#       ecr_repository_prefix = "docker-hub"
#       upstream_registry_url = "registry-1.docker.io"
#       credential_arn        = "arn:aws:secretsmanager:eu-central-1:111111111111:secret:ecr-pullthroughcache/docker-hub-abc123"
#     }
#     "root" = {
#       ecr_repository_prefix = "ROOT"
#       upstream_registry_url = "public.ecr.aws"
#     }
#     "cross-account-ecr" = {
#       ecr_repository_prefix      = "other-account"
#       upstream_registry_url      = "222222222222.dkr.ecr.us-east-1.amazonaws.com"
#       custom_role_arn            = "arn:aws:iam::111111111111:role/example-ecr-ptc"
#       upstream_repository_prefix = "ROOT"
#     }
#   }
# }

inputs = {
  rules = {}
}
