terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   managers = {
#     "web" = {
#       name               = "example-web-mig"
#       base_instance_name = "example-web"
#       zone               = "us-central1-a"
#       versions = [
#         {
#           instance_template = "https://www.googleapis.com/compute/v1/projects/example-project-1234/global/instanceTemplates/example-web-20260907abc123def4"
#         },
#       ]
#       target_size = 3
#       autoscaler = {
#         autoscaling_policy = {
#           min_replicas = 2
#           max_replicas = 10
#           cpu_utilization = {
#             target = 0.6
#           }
#         }
#       }
#     },
#   }
# }

inputs = {
  managers = {}
}
