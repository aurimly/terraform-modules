mock_provider "google" {}

run "pools" {
  command = plan

  variables {
    pools = {
      "ci" = {
        pool_id      = "example-ci-pool"
        display_name = "CI federation"
        providers = {
          "gh" = {
            provider_id         = "example-gh-oidc"
            display_name        = "GitHub Actions"
            attribute_condition = "assertion.repository == \"example-org/example-repo\""
            attribute_mapping = {
              "google.subject"       = "assertion.sub"
              "attribute.repository" = "assertion.repository"
            }
            oidc = {
              issuer_uri        = "https://token.actions.githubusercontent.com"
              allowed_audiences = ["https://iam.googleapis.com/projects/example-prj/locations/global/workloadIdentityPools/example-ci-pool/providers/example-gh-oidc"]
            }
            token_creators = {
              "deployer" = {
                service_account = "deploy-rt@example-prj.iam.gserviceaccount.com"
                member          = "principalSet://iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/example-ci-pool/attribute.repository/example-org/example-repo"
              }
            }
          }
          "aws" = {
            provider_id  = "example-aws"
            display_name = "AWS cross-cloud"
            attribute_mapping = {
              "google.subject"     = "assertion.sub"
              "attribute.aws_role" = "assertion.arn"
            }
            aws = { account_id = "123456789012" }
          }
        }
      }
      "partners" = {
        pool_id = "example-partners-pool"
        providers = {
          "saml" = {
            provider_id       = "example-partner-saml"
            display_name      = "Partner IdP"
            attribute_mapping = { "google.subject" = "assertion.name_id" }
            saml              = { idp_metadata_xml = "<EntityDescriptor xmlns=\"urn:oasis:names:tc:SAML:2.0:metadata\"></EntityDescriptor>" }
          }
          "x509" = {
            provider_id = "example-x509"
            x509 = {
              trust_store = {
                trust_anchors = [
                  { pem_certificate = "-----BEGIN CERTIFICATE----- EXAMPLE -----END CERTIFICATE-----" },
                ]
              }
            }
          }
        }
      }
    }
  }
}

run "rejects_two_protocols" {
  command = plan

  variables {
    pools = {
      "ci" = {
        pool_id = "example-ci-pool"
        providers = {
          "gh" = {
            provider_id       = "example-gh-oidc"
            attribute_mapping = { "google.subject" = "assertion.sub" }
            oidc              = { issuer_uri = "https://token.actions.githubusercontent.com" }
            aws               = { account_id = "123456789012" }
          }
        }
      }
    }
  }

  expect_failures = [var.pools]
}

run "rejects_oidc_mapping_without_subject" {
  command = plan

  variables {
    pools = {
      "ci" = {
        pool_id = "example-ci-pool"
        providers = {
          "gh" = {
            provider_id       = "example-gh-oidc"
            attribute_mapping = { "attribute.repo" = "assertion.repository" }
            oidc              = { issuer_uri = "https://token.actions.githubusercontent.com" }
          }
        }
      }
    }
  }

  expect_failures = [var.pools]
}

run "rejects_non_principal_member" {
  command = plan

  variables {
    pools = {
      "ci" = {
        pool_id = "example-ci-pool"
        providers = {
          "gh" = {
            provider_id       = "example-gh-oidc"
            attribute_mapping = { "google.subject" = "assertion.sub" }
            oidc              = { issuer_uri = "https://token.actions.githubusercontent.com" }
            token_creators = {
              "deployer" = {
                service_account = "deploy-rt@example-prj.iam.gserviceaccount.com"
                member          = "serviceAccount:deploy-rt@example-prj.iam.gserviceaccount.com"
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.pools]
}

run "rejects_bad_aws_account" {
  command = plan

  variables {
    pools = {
      "ci" = {
        pool_id = "example-ci-pool"
        providers = {
          "aws" = {
            provider_id       = "example-aws"
            attribute_mapping = { "google.subject" = "assertion.sub" }
            aws               = { account_id = "abc456789012" }
          }
        }
      }
    }
  }

  expect_failures = [var.pools]
}

run "rejects_x509_without_trust_anchors" {
  command = plan

  variables {
    pools = {
      "partners" = {
        pool_id = "example-partners-pool"
        providers = {
          "x509" = {
            provider_id = "example-x509"
            x509 = {
              trust_store = {
                trust_anchors = []
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.pools]
}
