terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   private_connections = {
#     "peering" = {
#       private_connection_id = "example-ds-connection"
#       display_name          = "Example Private Connection"
#       location              = "europe-west1"
#       vpc_peering_config = {
#         vpc    = "projects/example-prj/global/networks/example-net"
#         subnet = "10.0.0.0/29"
#       }
#     }
#   }
#   connection_profiles = {
#     "source" = {
#       connection_profile_id = "example-ds-source"
#       display_name          = "Example PostgreSQL Source"
#       location              = "europe-west1"
#       postgresql_profile = {
#         hostname = "example-db.example.internal"
#         username = "datastream"
#         password = "example-password"
#         database = "appdb"
#       }
#       private_connectivity = {
#         private_connection_key = "peering"
#       }
#     }
#   }
#   streams = {
#     "cdc" = {
#       stream_id    = "example-ds-stream"
#       location     = "europe-west1"
#       display_name = "Example Stream"
#       source_config = {
#         source_connection_profile_key = "source"
#         postgresql_source_config = {
#           replication_slot = "example_slot"
#           publication      = "example_pub"
#         }
#       }
#       destination_config = {
#         destination_connection_profile = "projects/example-prj/locations/europe-west1/connectionProfiles/example-ds-dest"
#         bigquery_destination_config = {
#           source_hierarchy_datasets = {
#             dataset_template = { location = "europe-west1" }
#           }
#         }
#       }
#       backfill_none = true
#     }
#   }
# }

inputs = {
  private_connections = {}
  connection_profiles = {}
  streams             = {}
}
