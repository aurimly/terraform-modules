mock_provider "google" {}

run "shared_vpc" {
  command = plan

  variables {
    host_projects = {
      "prd" = {
        project_id       = "example-host-prd"
        service_projects = ["example-svc-a", "example-svc-b"]
      },
      "npd" = {
        project_id       = "example-host-npd"
        service_projects = ["example-svc-c"]
      },
    }
  }
}

run "rejects_duplicated_service_project" {
  command = plan

  variables {
    host_projects = {
      "a" = {
        project_id       = "example-host-a"
        service_projects = ["example-svc-a"]
      },
      "b" = {
        project_id       = "example-host-b"
        service_projects = ["example-svc-a"]
      },
    }
  }

  expect_failures = [var.host_projects]
}

run "rejects_self_attachment" {
  command = plan

  variables {
    host_projects = {
      "a" = {
        project_id       = "example-host-a"
        service_projects = ["example-host-a"]
      },
    }
  }

  expect_failures = [var.host_projects]
}

run "rejects_service_deletion_policy_delete" {
  command = plan

  variables {
    host_projects = {
      "a" = {
        project_id       = "example-host-a"
        service_projects = ["example-svc-a"]

        service_deletion_policy = "DELETE"
      },
    }
  }

  expect_failures = [var.host_projects]
}
