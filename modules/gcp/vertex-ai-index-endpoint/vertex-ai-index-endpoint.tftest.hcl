mock_provider "google" {}

run "endpoints_and_deployed_indexes" {
  command = plan

  variables {
    index_endpoints = {
      "psa" = {
        display_name = "example-psa-endpoint"
        region       = "europe-west4"
        network      = "projects/123456789012/global/networks/vpc-example"
        labels = {
          env = "example"
        }
      }
      "psc" = {
        display_name = "example-psc-endpoint"
        region       = "europe-west4"
        private_service_connect_config = {
          enable_private_service_connect = true
          project_allowlist              = ["example-prj"]
          psc_automation_configs = [
            {
              project_id = "example-prj"
              network    = "projects/123456789012/global/networks/vpc-example"
            },
          ]
        }
      }
      "public" = {
        display_name            = "example-public-endpoint"
        region                  = "europe-west4"
        public_endpoint_enabled = true
        encryption_spec = {
          kms_key_name = "projects/example-prj/locations/europe-west4/keyRings/example-kr/cryptoKeys/example-key"
        }
      }
    }

    deployed_indexes = {
      "auto" = {
        deployed_index_id  = "example_deployed_1"
        index              = "projects/example-prj/locations/europe-west4/indexes/12345"
        index_endpoint     = "projects/example-prj/locations/europe-west4/indexEndpoints/67890"
        region             = "europe-west4"
        deployment_group   = "example"
        reserved_ip_ranges = ["example-ip-range"]
        automatic_resources = {
          min_replica_count = 2
          max_replica_count = 4
        }
      }
      "dedicated" = {
        deployed_index_id     = "example_deployed_2"
        index                 = "projects/example-prj/locations/europe-west4/indexes/12345"
        index_endpoint        = "projects/example-prj/locations/europe-west4/indexEndpoints/67890"
        enable_access_logging = true
        deployed_index_auth_config = {
          auth_provider = {
            audiences       = ["https://example.com"]
            allowed_issuers = ["sa@example-prj.iam.gserviceaccount.com"]
          }
        }
        dedicated_resources = {
          machine_spec = {
            machine_type = "e2-standard-2"
          }
          min_replica_count = 1
          max_replica_count = 3
        }
      }
    }
  }
}

run "rejects_network_with_psc" {
  command = plan

  variables {
    deployed_indexes = {}
    index_endpoints = {
      "both" = {
        display_name = "example-endpoint"
        network      = "projects/123456789012/global/networks/vpc-example"
        private_service_connect_config = {
          enable_private_service_connect = true
        }
      }
    }
  }

  expect_failures = [var.index_endpoints]
}

run "rejects_bad_endpoint_deletion_policy" {
  command = plan

  variables {
    deployed_indexes = {}
    index_endpoints = {
      "endpoint" = {
        display_name    = "example-endpoint"
        deletion_policy = "KEEP"
      }
    }
  }

  expect_failures = [var.index_endpoints]
}

run "rejects_bad_deployed_index_id" {
  command = plan

  variables {
    index_endpoints = {}
    deployed_indexes = {
      "auto" = {
        deployed_index_id = "1_deployed"
        index             = "projects/example-prj/locations/europe-west4/indexes/12345"
        index_endpoint    = "projects/example-prj/locations/europe-west4/indexEndpoints/67890"
        automatic_resources = {
          min_replica_count = 2
        }
      }
    }
  }

  expect_failures = [var.deployed_indexes]
}

run "rejects_both_resource_types" {
  command = plan

  variables {
    index_endpoints = {}
    deployed_indexes = {
      "auto" = {
        deployed_index_id = "example_deployed"
        index             = "projects/example-prj/locations/europe-west4/indexes/12345"
        index_endpoint    = "projects/example-prj/locations/europe-west4/indexEndpoints/67890"
        automatic_resources = {
          min_replica_count = 2
        }
        dedicated_resources = {
          machine_spec = {
            machine_type = "e2-standard-2"
          }
          min_replica_count = 1
        }
      }
    }
  }

  expect_failures = [var.deployed_indexes]
}

run "rejects_neither_resource_type" {
  command = plan

  variables {
    index_endpoints = {}
    deployed_indexes = {
      "auto" = {
        deployed_index_id = "example_deployed"
        index             = "projects/example-prj/locations/europe-west4/indexes/12345"
        index_endpoint    = "projects/example-prj/locations/europe-west4/indexEndpoints/67890"
      }
    }
  }

  expect_failures = [var.deployed_indexes]
}

run "rejects_dedicated_replica_bounds" {
  command = plan

  variables {
    index_endpoints = {}
    deployed_indexes = {
      "dedicated" = {
        deployed_index_id = "example_deployed"
        index             = "projects/example-prj/locations/europe-west4/indexes/12345"
        index_endpoint    = "projects/example-prj/locations/europe-west4/indexEndpoints/67890"
        dedicated_resources = {
          machine_spec = {
            machine_type = "e2-standard-2"
          }
          min_replica_count = 3
          max_replica_count = 1
        }
      }
    }
  }

  expect_failures = [var.deployed_indexes]
}

run "rejects_dedicated_zero_min_replicas" {
  command = plan

  variables {
    index_endpoints = {}
    deployed_indexes = {
      "dedicated" = {
        deployed_index_id = "example_deployed"
        index             = "projects/example-prj/locations/europe-west4/indexes/12345"
        index_endpoint    = "projects/example-prj/locations/europe-west4/indexEndpoints/67890"
        dedicated_resources = {
          machine_spec = {
            machine_type = "e2-standard-2"
          }
          min_replica_count = 0
        }
      }
    }
  }

  expect_failures = [var.deployed_indexes]
}

run "rejects_automatic_replica_bounds" {
  command = plan

  variables {
    index_endpoints = {}
    deployed_indexes = {
      "auto" = {
        deployed_index_id = "example_deployed"
        index             = "projects/example-prj/locations/europe-west4/indexes/12345"
        index_endpoint    = "projects/example-prj/locations/europe-west4/indexEndpoints/67890"
        automatic_resources = {
          min_replica_count = 4
          max_replica_count = 2
        }
      }
    }
  }

  expect_failures = [var.deployed_indexes]
}

run "rejects_long_deployment_group" {
  command = plan

  variables {
    index_endpoints = {}
    deployed_indexes = {
      "auto" = {
        deployed_index_id = "example_deployed"
        index             = "projects/example-prj/locations/europe-west4/indexes/12345"
        index_endpoint    = "projects/example-prj/locations/europe-west4/indexEndpoints/67890"
        deployment_group  = "a123456789a123456789a123456789a123456789a123456789a123456789a1234"
        automatic_resources = {
          min_replica_count = 2
        }
      }
    }
  }

  expect_failures = [var.deployed_indexes]
}

run "rejects_bad_deployed_index_deletion_policy" {
  command = plan

  variables {
    index_endpoints = {}
    deployed_indexes = {
      "auto" = {
        deployed_index_id = "example_deployed"
        index             = "projects/example-prj/locations/europe-west4/indexes/12345"
        index_endpoint    = "projects/example-prj/locations/europe-west4/indexEndpoints/67890"
        deletion_policy   = "KEEP"
        automatic_resources = {
          min_replica_count = 2
        }
      }
    }
  }

  expect_failures = [var.deployed_indexes]
}
