mock_provider "google" {}

run "ssl_policies" {
  command = plan

  variables {
    ssl_policies = {
      "global" = {
        name            = "example-global-tls12"
        description     = "restricted profile, min TLS 1.2"
        profile         = "RESTRICTED"
        min_tls_version = "TLS_1_2"
      },
      "custom" = {
        name            = "example-custom-ciphers"
        profile         = "CUSTOM"
        min_tls_version = "TLS_1_2"
        custom_features = ["TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"]
      },
      "post-quantum" = {
        name                      = "example-global-pq"
        profile                   = "MODERN"
        post_quantum_key_exchange = "ENABLED"
      },
    }
  }
}

run "rejects_custom_without_features" {
  command = plan

  variables {
    ssl_policies = {
      "global" = {
        name    = "example-global-custom"
        profile = "CUSTOM"
      },
    }
  }

  expect_failures = [var.ssl_policies]
}

run "rejects_tls13_without_restricted" {
  command = plan

  variables {
    ssl_policies = {
      "global" = {
        name            = "example-global-tls13"
        profile         = "MODERN"
        min_tls_version = "TLS_1_3"
      },
    }
  }

  expect_failures = [var.ssl_policies]
}

run "rejects_unknown_profile" {
  command = plan

  variables {
    ssl_policies = {
      "global" = {
        name    = "example-global-default"
        profile = "DEFAULT"
      },
    }
  }

  expect_failures = [var.ssl_policies]
}
