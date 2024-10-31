locals {
  project1 = "aurimly-test-project-asdfa1"
  project2 = "aurimly-test-project-asdfa2"
  org_id = null
  deletion_policy = "DELETE"
}

terraform {
  source = "./empty/"
}

generate "loop" {
  path = "_loop.tf"
  if_exists = "overwrite"
  contents = <<EOF
module "project" {
  source = "git@me.github.com:aurimly/terraform-modules.git//modules/gcp/project"

  for_each = var.projects

  name = each.value.name
  project_id = each.value.project_id
  org_id = each.value.org_id
  auto_create_network = lookup(each.value, "auto_create_network", null)
  deletion_policy = lookup(each.value, "deletion_policy", null)
  labels = each.value.labels
}

variable "projects" {
  type = any
}
EOF
}

inputs = {
  projects = {
#    "${local.project1}" = {
#      name = local.project1
#      project_id = local.project1
#      org_id = local.org_id
#      deletion_policy = local.deletion_policy
#      labels = {
#        "env" = "test"
#      }
#    },
#    "${local.project2}" = {
#      name = local.project2
#      project_id = local.project2
#      org_id = local.org_id
#      deletion_policy = local.deletion_policy
#      labels = {
#        "env" = "test"
#      }
#    },
  }
}
