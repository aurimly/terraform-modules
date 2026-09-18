terraform {
  source = "../../"
}

# Example inputs (commented). To validate against GCP, replace the inputs below
# with real values (needs GCP creds). terragrunt validate with an empty map
# needs no creds.
#
# inputs = {
#   datasets = {
#     "images" = {
#       display_name        = "example-dataset"
#       metadata_schema_uri = "gs://google-cloud-aiplatform/schema/dataset/metadata/image_1.0.0.yaml"
#       region              = "europe-west4"
#     }
#   }
# }

inputs = {
  datasets = {}
}
