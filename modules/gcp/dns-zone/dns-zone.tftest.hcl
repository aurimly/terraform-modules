mock_provider "google" {}

run "zones" {
  command = plan

  variables {
    zones = {
      "public" = {
        name     = "example-org-public"
        dns_name = "example.org."
        dnssec_config = {
          state = "on"
        }
      }
      "forwarding" = {
        name       = "example-onprem-forward"
        dns_name   = "corp.example.internal."
        visibility = "private"
        private_visibility_config = {
          networks = [
            { network_url = "https://www.googleapis.com/compute/v1/projects/example-prj/global/networks/vpc-example-prd" },
          ]
        }
        forwarding_config = {
          target_name_servers = [
            { ipv4_address = "10.0.0.10" },
          ]
        }
      }
      "peering" = {
        name       = "example-peer-net"
        dns_name   = "other.example.internal."
        visibility = "private"
        peering_config = {
          target_network = { network_url = "projects/example-producer-prj/global/networks/vpc-producer" }
        }
      }
    }
  }
}

run "rejects_dnssec_on_private_zone" {
  command = plan

  variables {
    zones = {
      "internal" = {
        name       = "example-internal"
        dns_name   = "internal.example."
        visibility = "private"
        dnssec_config = {
          state = "on"
        }
      }
    }
  }

  expect_failures = [var.zones]
}

run "rejects_peering_and_forwarding" {
  command = plan

  variables {
    zones = {
      "broken" = {
        name       = "example-broken"
        dns_name   = "broken.example.internal."
        visibility = "private"
        private_visibility_config = {
          networks = [
            { network_url = "https://www.googleapis.com/compute/v1/projects/example-prj/global/networks/vpc-example-prd" },
          ]
        }
        forwarding_config = {
          target_name_servers = [
            { ipv4_address = "10.0.0.10" },
          ]
        }
        peering_config = {
          target_network = { network_url = "projects/example-producer-prj/global/networks/vpc-producer" }
        }
      }
    }
  }

  expect_failures = [var.zones]
}

run "rejects_dns_name_without_trailing_dot" {
  command = plan

  variables {
    zones = {
      "public" = {
        name     = "example-org-public"
        dns_name = "example.org"
      }
    }
  }

  expect_failures = [var.zones]
}

run "rejects_bad_visibility" {
  command = plan

  variables {
    zones = {
      "public" = {
        name       = "example-org-public"
        dns_name   = "example.org."
        visibility = "Public"
      }
    }
  }

  expect_failures = [var.zones]
}

run "rejects_zone_name_with_underscore" {
  command = plan

  variables {
    zones = {
      "public" = {
        name     = "example_zone"
        dns_name = "example.org."
      }
    }
  }

  expect_failures = [var.zones]
}
