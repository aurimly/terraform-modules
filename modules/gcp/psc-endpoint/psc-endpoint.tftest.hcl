mock_provider "google" {}

run "psc_endpoints" {
  command = plan

  variables {
    psc_endpoints = {
      "mongodb" = {
        name                      = "example-mongodb-psc"
        region                    = "europe-west4"
        network                   = "vpc-example-production"
        subnetwork                = "psc-europe-west4"
        target_service_attachment = "projects/example-producer/regions/europe-west4/serviceAttachments/example-mongodb"
        allow_psc_global_access   = true
        labels = {
          "env" = "prd"
        }
      },
    }
  }
}

run "rejects_long_name_without_address_name" {
  command = plan

  variables {
    psc_endpoints = {
      "mongodb" = {
        name                      = "example-psc-endpoint-name-that-is-longer-than-sixty-characters"
        region                    = "europe-west4"
        network                   = "vpc-example-production"
        subnetwork                = "psc-europe-west4"
        target_service_attachment = "projects/example-producer/regions/europe-west4/serviceAttachments/example-mongodb"
      },
    }
  }

  expect_failures = [var.psc_endpoints]
}

run "rejects_bad_region" {
  command = plan

  variables {
    psc_endpoints = {
      "mongodb" = {
        name                      = "example-mongodb-psc"
        region                    = "EUROPE-WEST4"
        network                   = "vpc-example-production"
        subnetwork                = "psc-europe-west4"
        target_service_attachment = "projects/example-producer/regions/europe-west4/serviceAttachments/example-mongodb"
      },
    }
  }

  expect_failures = [var.psc_endpoints]
}
