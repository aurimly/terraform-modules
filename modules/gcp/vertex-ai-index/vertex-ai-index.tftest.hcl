mock_provider "google" {}

run "tree_ah_indexes" {
  command = plan

  variables {
    indexes = {
      "treeah" = {
        display_name = "example-treeah-index"
        region       = "europe-west4"
        description  = "example tree-AH index"
        labels = {
          env = "example"
        }
        metadata = {
          contents_delta_uri = "gs://example-bucket/index-delta"
          config = {
            dimensions                  = 128
            approximate_neighbors_count = 100
            shard_size                  = "SHARD_SIZE_SMALL"
            distance_measure_type       = "DOT_PRODUCT_DISTANCE"
            feature_norm_type           = "UNIT_L2_NORM"
            algorithm_config = {
              tree_ah_config = {
                leaf_node_embedding_count    = 1000
                leaf_nodes_to_search_percent = 10
              }
            }
          }
        }
      }
    }
  }
}

run "brute_force_streaming_index" {
  command = plan

  variables {
    indexes = {
      "brute" = {
        display_name        = "example-brute-force-index"
        index_update_method = "STREAM_UPDATE"
        deletion_policy     = "PREVENT"
        encryption_spec = {
          kms_key_name = "projects/example-prj/locations/europe-west4/keyRings/example-kr/cryptoKeys/example-key"
        }
        metadata = {
          contents_delta_uri = "gs://example-bucket/index-delta"
          config = {
            dimensions            = 768
            shard_size            = "SHARD_SIZE_MEDIUM"
            distance_measure_type = "SQUARED_L2_DISTANCE"
            algorithm_config = {
              brute_force_config = {}
            }
          }
        }
      }
    }
  }
}

run "rejects_bad_update_method" {
  command = plan

  variables {
    indexes = {
      "treeah" = {
        display_name        = "example-index"
        index_update_method = "REALTIME"
        metadata = {
          contents_delta_uri = "gs://example-bucket/index-delta"
          config = {
            dimensions = 128
          }
        }
      }
    }
  }

  expect_failures = [var.indexes]
}

run "rejects_non_gs_delta_uri" {
  command = plan

  variables {
    indexes = {
      "treeah" = {
        display_name = "example-index"
        metadata = {
          contents_delta_uri = "https://example-bucket.storage.googleapis.com/index-delta"
          config = {
            dimensions = 128
          }
        }
      }
    }
  }

  expect_failures = [var.indexes]
}

run "rejects_zero_dimensions" {
  command = plan

  variables {
    indexes = {
      "treeah" = {
        display_name = "example-index"
        metadata = {
          contents_delta_uri = "gs://example-bucket/index-delta"
          config = {
            dimensions = 0
          }
        }
      }
    }
  }

  expect_failures = [var.indexes]
}

run "rejects_bad_shard_size" {
  command = plan

  variables {
    indexes = {
      "treeah" = {
        display_name = "example-index"
        metadata = {
          contents_delta_uri = "gs://example-bucket/index-delta"
          config = {
            dimensions = 128
            shard_size = "SHARD_SIZE_HUGE"
          }
        }
      }
    }
  }

  expect_failures = [var.indexes]
}

run "rejects_bad_distance_measure" {
  command = plan

  variables {
    indexes = {
      "treeah" = {
        display_name = "example-index"
        metadata = {
          contents_delta_uri = "gs://example-bucket/index-delta"
          config = {
            dimensions            = 128
            distance_measure_type = "MANHATTAN"
          }
        }
      }
    }
  }

  expect_failures = [var.indexes]
}

run "rejects_bad_feature_norm" {
  command = plan

  variables {
    indexes = {
      "treeah" = {
        display_name = "example-index"
        metadata = {
          contents_delta_uri = "gs://example-bucket/index-delta"
          config = {
            dimensions        = 128
            feature_norm_type = "UNIT_NORM"
          }
        }
      }
    }
  }

  expect_failures = [var.indexes]
}

run "rejects_both_algorithms" {
  command = plan

  variables {
    indexes = {
      "treeah" = {
        display_name = "example-index"
        metadata = {
          contents_delta_uri = "gs://example-bucket/index-delta"
          config = {
            dimensions = 128
            algorithm_config = {
              tree_ah_config = {
                leaf_node_embedding_count = 1000
              }
              brute_force_config = {}
            }
          }
        }
      }
    }
  }

  expect_failures = [var.indexes]
}

run "rejects_treeah_without_neighbors_count" {
  command = plan

  variables {
    indexes = {
      "treeah" = {
        display_name = "example-index"
        metadata = {
          contents_delta_uri = "gs://example-bucket/index-delta"
          config = {
            dimensions = 128
            algorithm_config = {
              tree_ah_config = {
                leaf_node_embedding_count = 1000
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.indexes]
}

run "rejects_bad_leaf_nodes_percent" {
  command = plan

  variables {
    indexes = {
      "treeah" = {
        display_name = "example-index"
        metadata = {
          contents_delta_uri = "gs://example-bucket/index-delta"
          config = {
            dimensions                  = 128
            approximate_neighbors_count = 100
            algorithm_config = {
              tree_ah_config = {
                leaf_nodes_to_search_percent = 101
              }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.indexes]
}

run "rejects_bad_deletion_policy" {
  command = plan

  variables {
    indexes = {
      "treeah" = {
        display_name    = "example-index"
        deletion_policy = "KEEP"
        metadata = {
          contents_delta_uri = "gs://example-bucket/index-delta"
          config = {
            dimensions = 128
          }
        }
      }
    }
  }

  expect_failures = [var.indexes]
}
