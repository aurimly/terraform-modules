mock_provider "google" {}

run "certificates" {
  command = plan

  variables {
    dns_authorizations = {
      "a" = {
        name     = "example-dns-auth"
        domain   = "service.example.com"
        location = "us-central1"
        labels   = { env = "example" }
      }
    }

    certificates = {
      "edge" = {
        name        = "example-edge-cert"
        description = "example cert"
        managed = {
          domains            = ["service.example.com"]
          dns_authorizations = ["a"]
        }
      }
      "self" = {
        name  = "example-self-cert"
        scope = "CLIENT_AUTH"
        self_managed = {
          pem_certificate = "-----BEGIN CERTIFICATE-----\nexample\n-----END CERTIFICATE-----"
          pem_private_key = "-----BEGIN PRIVATE KEY-----\nexample\n-----END PRIVATE KEY-----"
        }
      }
    }

    certificate_maps = {
      "lb" = {
        name = "example-lb-cert-map"
      }
    }

    certificate_map_entries = {
      "sni" = {
        map_key      = "lb"
        name         = "example-sni-entry"
        hostname     = "service.example.com"
        certificates = ["edge"]
      }
      "primary" = {
        map_key      = "lb"
        name         = "example-primary-entry"
        matcher      = "PRIMARY"
        certificates = ["self"]
      }
    }
  }
}

run "rejects_managed_and_self_info" {
  command = plan

  variables {
    certificates = {
      "bad" = {
        name = "example-both"
        managed = {
          domains = ["service.example.com"]
        }
        self_managed = {
          pem_certificate = "example"
          pem_private_key = "example"
        }
      }
    }
  }

  expect_failures = [var.certificates]
}

run "rejects_dns_auth_and_issuance" {
  command = plan

  variables {
    certificates = {
      "bad" = {
        name = "example-bad"
        managed = {
          domains            = ["service.example.com"]
          dns_authorizations = ["a"]
          issuance_config    = "projects/example-prj/locations/global/certificateIssuanceConfigs/example"
        }
      }
    }

    dns_authorizations = {
      "a" = {
        name   = "example-dns-auth"
        domain = "service.example.com"
      }
    }
  }

  expect_failures = [var.certificates]
}

run "rejects_primary_with_hostname" {
  command = plan

  variables {
    certificate_map_entries = {
      "bad" = {
        map_key      = "lb"
        name         = "example-bad-entry"
        hostname     = "service.example.com"
        matcher      = "PRIMARY"
        certificates = ["x"]
      }
    }

    certificate_maps = {
      "lb" = {
        name = "example-lb-cert-map"
      }
    }

    certificates = {
      "x" = {
        name = "example-x"
        managed = {
          domains = ["service.example.com"]
        }
      }
    }

    dns_authorizations = {
      "a" = {
        name   = "example-dns-auth"
        domain = "service.example.com"
      }
    }
  }

  expect_failures = [var.certificate_map_entries]
}

run "rejects_two_primary_per_map" {
  command = plan

  variables {
    certificates = {
      "x" = {
        name = "example-x"
        managed = {
          domains = ["service.example.com"]
        }
      }
    }

    certificate_maps = {
      "lb" = {
        name = "example-lb-cert-map"
      }
    }

    certificate_map_entries = {
      "one" = {
        map_key      = "lb"
        name         = "example-entry-one"
        matcher      = "PRIMARY"
        certificates = ["x"]
      }
      "two" = {
        map_key      = "lb"
        name         = "example-entry-two"
        matcher      = "PRIMARY"
        certificates = ["x"]
      }
    }
  }

  expect_failures = [var.certificate_map_entries]
}

run "rejects_bad_domain" {
  command = plan

  variables {
    dns_authorizations = {
      "bad" = {
        name   = "example-dns-auth"
        domain = "not a hostname"
      }
    }
  }

  expect_failures = [var.dns_authorizations]
}
