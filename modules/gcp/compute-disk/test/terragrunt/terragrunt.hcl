terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   disks = {
#     "data" = {
#       name  = "example-data"
#       zone  = "us-central1-a"
#       type  = "pd-ssd"
#       size  = 500
#     },
#   }
#   snapshot_schedule_policies = {
#     "daily" = {
#       name   = "example-daily-snapshots"
#       region = "us-central1"
#       snapshot_schedule_policy = {
#         daily_schedule = {
#           days_in_cycle = 1
#           start_time    = "10:00"
#         }
#       }
#     }
#   }
#   snapshot_schedule_attachments = {
#     "data" = {
#       disk_key   = "data"
#       policy_key = "daily"
#     }
#   }
# }

inputs = {
  disks  = {}
  snapshots = {}
  snapshot_schedule_policies   = {}
  snapshot_schedule_attachments = {}
}
