mock_provider "google" {}

run "keys" {
  command = plan

  variables {
    service_account_keys = {
      "api" = {
        service_account = "api-rt@example-prj.iam.gserviceaccount.com"
        key_algorithm   = "KEY_ALG_RSA_2048"
        keepers = {
          rotation_epoch = "1"
        }
      }
      "byok" = {
        service_account = "projects/example-prj/serviceAccounts/api-rt@example-prj.iam.gserviceaccount.com"
        public_key_data = base64encode("-----BEGIN PUBLIC KEY-----")
      }
    }
  }
}

run "bad_service_account_fails" {
  command = plan

  variables {
    service_account_keys = {
      "broken" = {
        service_account = "api-rt"
      }
    }
  }

  expect_failures = [var.service_account_keys]
}

run "public_key_data_with_type_fails" {
  command = plan

  variables {
    service_account_keys = {
      "broken" = {
        service_account  = "api-rt@example-prj.iam.gserviceaccount.com"
        public_key_data  = base64encode("-----BEGIN PUBLIC KEY-----")
        private_key_type = "TYPE_GOOGLE_CREDENTIALS_FILE"
      }
    }
  }

  expect_failures = [var.service_account_keys]
}

run "public_key_data_with_public_key_type_ok" {
  command = plan

  variables {
    service_account_keys = {
      "byok" = {
        service_account = "api-rt@example-prj.iam.gserviceaccount.com"
        public_key_data = base64encode("-----BEGIN PUBLIC KEY-----")
        public_key_type = "TYPE_X509_PEM_FILE"
      }
    }
  }
}

run "bad_deletion_policy_fails" {
  command = plan

  variables {
    service_account_keys = {
      "broken" = {
        service_account = "api-rt@example-prj.iam.gserviceaccount.com"
        deletion_policy = "KEEP"
      }
    }
  }

  expect_failures = [var.service_account_keys]
}
