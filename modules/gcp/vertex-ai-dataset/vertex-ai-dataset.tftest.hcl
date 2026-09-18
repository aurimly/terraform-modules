mock_provider "google" {}

run "datasets" {
  command = plan

  variables {
    datasets = {
      "images" = {
        display_name        = "example-dataset"
        metadata_schema_uri = "gs://google-cloud-aiplatform/schema/dataset/metadata/image_1.0.0.yaml"
        region              = "europe-west4"
        labels = {
          env = "example"
        }
      }
      "encrypted" = {
        display_name        = "example-cmek-dataset"
        metadata_schema_uri = "gs://google-cloud-aiplatform/schema/dataset/metadata/tabular_1.0.0.yaml"
        deletion_policy     = "PREVENT"
        encryption_spec = {
          kms_key_name = "projects/example-prj/locations/europe-west4/keyRings/example-kr/cryptoKeys/example-key"
        }
      }
    }
  }
}

run "rejects_non_gs_schema_uri" {
  command = plan

  variables {
    datasets = {
      "images" = {
        display_name        = "example-dataset"
        metadata_schema_uri = "https://google-cloud-aiplatform/schema/dataset/metadata/image_1.0.0.yaml"
      }
    }
  }

  expect_failures = [var.datasets]
}

run "rejects_bad_kms_key" {
  command = plan

  variables {
    datasets = {
      "images" = {
        display_name        = "example-dataset"
        metadata_schema_uri = "gs://google-cloud-aiplatform/schema/dataset/metadata/image_1.0.0.yaml"
        encryption_spec = {
          kms_key_name = "projects/example-prj/keyRings/example-kr/cryptoKeys/example-key"
        }
      }
    }
  }

  expect_failures = [var.datasets]
}

run "rejects_bad_deletion_policy" {
  command = plan

  variables {
    datasets = {
      "images" = {
        display_name        = "example-dataset"
        metadata_schema_uri = "gs://google-cloud-aiplatform/schema/dataset/metadata/image_1.0.0.yaml"
        deletion_policy     = "KEEP"
      }
    }
  }

  expect_failures = [var.datasets]
}

run "rejects_uppercase_label" {
  command = plan

  variables {
    datasets = {
      "images" = {
        display_name        = "example-dataset"
        metadata_schema_uri = "gs://google-cloud-aiplatform/schema/dataset/metadata/image_1.0.0.yaml"
        labels = {
          Env = "example"
        }
      }
    }
  }

  expect_failures = [var.datasets]
}
