locals {
  project_name = "aurimly-test-project-asdfasdf1"
  project_id = local.project_name
  org_id = null
  deletion_policy = "DELETE"
}

terraform {
  source = "../../"
}

inputs = {
  name = local.project_name
  project_id = local.project_id
  org_id = local.org_id
  deletion_policy = local.deletion_policy
  labels = {
    "env" = "test"
  }
}
