mock_provider "google" {}

run "roles" {
  command = plan

  variables {
    organization_roles = {
      "viewer" = {
        org_id  = "123456789012"
        role_id = "myCustomRole"
        title   = "Example Viewer"
        stage   = "EAP"
        permissions = [
          "storage.buckets.get",
          "storage.objects.list",
        ]
      }
    }

    project_roles = {
      "deployer" = {
        role_id = "example_deployer.v2"
        title   = "Example Deployer"
        permissions = [
          "run.services.get",
        ]
      }
    }
  }
}

run "rejects_org_id_prefix_form" {
  command = plan

  variables {
    project_roles = {}
    organization_roles = {
      "viewer" = {
        org_id  = "organizations/123456789012"
        role_id = "myCustomRole"
        title   = "Example Viewer"
        permissions = [
          "storage.buckets.get",
        ]
      }
    }
  }

  expect_failures = [var.organization_roles]
}

run "rejects_hyphenated_role_id" {
  command = plan

  variables {
    organization_roles = {}
    project_roles = {
      "deployer" = {
        role_id = "example-deployer"
        title   = "Example Deployer"
        permissions = [
          "run.services.get",
        ]
      }
    }
  }

  expect_failures = [var.project_roles]
}

run "rejects_bad_stage" {
  command = plan

  variables {
    organization_roles = {}
    project_roles = {
      "deployer" = {
        role_id = "exampleDeployer"
        title   = "Example Deployer"
        stage   = "eap"
        permissions = [
          "run.services.get",
        ]
      }
    }
  }

  expect_failures = [var.project_roles]
}

run "rejects_bad_permission_shape" {
  command = plan

  variables {
    organization_roles = {}
    project_roles = {
      "deployer" = {
        role_id     = "exampleDeployer"
        title       = "Example Deployer"
        permissions = ["run"]
      }
    }
  }

  expect_failures = [var.project_roles]
}
