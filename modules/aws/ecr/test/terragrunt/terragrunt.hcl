terraform {
  source = "../../"
}

# Example inputs (commented). To validate against AWS, replace the inputs below
# with real values (needs AWS creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   repositories = {
#     "app" = {
#       name                 = "example/team/app"
#       image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"
#       image_tag_mutability_exclusion_filters = [
#         { filter = "sha256-*" }
#       ]
#       scan_on_push = true
#       encryption = {
#         type    = "KMS"
#         kms_key = "arn:aws:kms:eu-central-1:111111111111:key/example"
#       }
#       lifecycle_policy = {
#         rules = [
#           {
#             rule_priority = 1
#             selection = {
#               tag_status   = "untagged"
#               count_type   = "sinceImagePushed"
#               count_unit   = "days"
#               count_number = 30
#             }
#           },
#           {
#             rule_priority = 2
#             selection = {
#               tag_status       = "tagged"
#               tag_prefix_list  = ["v"]
#               count_type       = "imageCountMoreThan"
#               count_number     = 30
#             }
#           },
#           {
#             rule_priority = 3
#             selection = {
#               tag_status   = "any"
#               count_type   = "sinceImagePushed"
#               count_unit   = "days"
#               count_number = 365
#             }
#           }
#         ]
#       }
#       repository_policy = {
#         policy = jsonencode({
#           Version = "2012-10-17"
#           Statement = [{
#             Sid       = "Pull"
#             Effect    = "Allow"
#             Principal = { AWS = "arn:aws:iam::111111111111:root" }
#             Action = [
#               "ecr:GetDownloadUrlForLayer",
#               "ecr:BatchGetImage",
#               "ecr:BatchCheckLayerAvailability"
#             ]
#           }]
#         })
#       }
#     }
#   }
# }

inputs = {
  repositories = {}
}
