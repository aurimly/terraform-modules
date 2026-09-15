mock_provider "google" {}

run "connectors" {
  command = plan

  variables {
    connectors = {
      "dedicated" = {
        name          = "example-prj-connector"
        region        = "us-central1"
        network       = "projects/example-prj/global/networks/example-vpc"
        ip_cidr_range = "10.1.0.0/28"
        min_instances = 2
        max_instances = 5
      },
      "shared" = {
        name = "example-shared-conn"
        subnet = {
          name       = "example-subnet"
          project_id = "example-host-prj"
        }
        deletion_policy = "ABANDON"
      },
    }
  }
}

run "rejects_subnet_with_ip_cidr_range" {
  command = plan

  variables {
    connectors = {
      "bad" = {
        name          = "example-connector"
        network       = "example-vpc"
        ip_cidr_range = "10.1.0.0/28"
        subnet = {
          name = "example-subnet"
        }
      },
    }
  }

  expect_failures = [var.connectors]
}

run "rejects_min_instances_with_min_throughput" {
  command = plan

  variables {
    connectors = {
      "bad" = {
        name           = "example-connector"
        network        = "example-vpc"
        ip_cidr_range  = "10.1.0.0/28"
        min_instances  = 2
        max_instances  = 5
        min_throughput = 200
        max_throughput = 300
      },
    }
  }

  expect_failures = [var.connectors]
}

run "rejects_name_longer_than_25_chars" {
  command = plan

  variables {
    connectors = {
      "bad" = {
        name          = "example-serverless-vpc-connector-abc"
        network       = "example-vpc"
        ip_cidr_range = "10.1.0.0/28"
      },
    }
  }

  expect_failures = [var.connectors]
}

run "rejects_missing_network_with_ip_cidr_range" {
  command = plan

  variables {
    connectors = {
      "bad" = {
        name          = "example-connector"
        ip_cidr_range = "10.1.0.0/28"
      },
    }
  }

  expect_failures = [var.connectors]
}
