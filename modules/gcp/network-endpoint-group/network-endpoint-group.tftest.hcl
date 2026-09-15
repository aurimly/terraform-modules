mock_provider "google" {}

run "groups_and_endpoints" {
  command = plan

  variables {
    negs = {
      "hybrid" = {
        name       = "example-hybrid-neg"
        zone       = "us-central1-a"
        network    = "projects/example-prj/global/networks/example-vpc"
        subnetwork = "projects/example-prj/regions/us-central1/subnetworks/example-subnet"
      }
    }
    regional_negs = {
      "run" = {
        name   = "example-run-regneg"
        region = "us-central1"
        cloud_run = {
          service = "example-run-service"
        }
      }
      "psc" = {
        name                  = "example-psc-regneg"
        region                = "us-central1"
        network_endpoint_type = "PRIVATE_SERVICE_CONNECT"
        network               = "projects/example-prj/global/networks/example-vpc"
        subnetwork            = "projects/example-prj/regions/us-central1/subnetworks/example-subnet"
        psc_target_service    = "https://europe-west1-example-prj.cloudfunctions.net"
        psc_data = {
          producer_port = 8080
        }
      }
    }
    endpoints = {
      "one" = {
        neg        = "hybrid"
        ip_address = "10.10.0.10"
        port       = 8080
        instance   = "example-instance-1"
      }
    }
  }
}

run "rejects_endpoint_on_serverless_neg" {
  command = plan

  variables {
    negs = {
      "srv" = {
        name                  = "example-srv-neg"
        zone                  = "us-central1-a"
        network               = "projects/example-prj/global/networks/example-vpc"
        network_endpoint_type = "SERVERLESS"
      }
    }
    regional_negs = {
      "run" = {
        name   = "example-run-regneg"
        region = "us-central1"
        cloud_run = {
          service = "example-run-service"
        }
      }
    }
    endpoints = {
      "bad" = {
        neg        = "srv"
        ip_address = "10.10.0.10"
        port       = 8080
      }
    }
  }

  expect_failures = [var.endpoints]
}

run "rejects_two_serverless_targets" {
  command = plan

  variables {
    negs      = {}
    endpoints = {}
    regional_negs = {
      "bad" = {
        name   = "example-run-regneg"
        region = "us-central1"
        cloud_run = {
          service = "example-run-service"
        }
        app_engine = {
          service = "example-ae-service"
        }
      }
    }
  }

  expect_failures = [var.regional_negs]
}

run "rejects_endpoint_missing_port" {
  command = plan

  variables {
    regional_negs = {}
    negs = {
      "vm" = {
        name    = "example-vm-neg"
        zone    = "us-central1-a"
        network = "projects/example-prj/global/networks/example-vpc"
      }
    }
    endpoints = {
      "bad" = {
        neg        = "vm"
        ip_address = "10.10.0.10"
        instance   = "example-instance-1"
      }
    }
  }

  expect_failures = [var.endpoints]
}
