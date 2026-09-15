locals {
  tables = {
    for entry in flatten([
      for dataset_key, dataset in var.datasets : [
        for table_key, table in dataset.tables : {
          dataset_key = dataset_key
          table_key   = table_key
          dataset     = dataset
          table       = table
        }
      ]
    ]) : "${entry.dataset_key}/${entry.table_key}" => entry
  }

  dataset_role_bindings = {
    for entry in flatten([
      for dataset_key, dataset in var.datasets : [
        for binding_key, binding in dataset.role_bindings : {
          dataset_key = dataset_key
          binding_key = binding_key
          dataset     = dataset
          binding     = binding
        }
      ]
    ]) : "${entry.dataset_key}/${entry.binding_key}" => entry
  }
}

resource "google_bigquery_dataset" "dataset" {
  for_each = var.datasets

  dataset_id                      = each.value.dataset_id
  project                         = each.value.project_id
  location                        = each.value.location
  friendly_name                   = each.value.friendly_name
  description                     = each.value.description
  labels                          = each.value.labels
  default_table_expiration_ms     = each.value.default_table_expiration_ms
  default_partition_expiration_ms = each.value.default_partition_expiration_ms
  max_time_travel_hours           = each.value.max_time_travel_hours
  default_collation               = each.value.default_collation
  is_case_insensitive             = each.value.is_case_insensitive
  storage_billing_model           = each.value.storage_billing_model
  deletion_policy                 = each.value.deletion_policy
  delete_contents_on_destroy      = each.value.delete_contents_on_destroy
  resource_tags                   = each.value.resource_tags

  dynamic "default_encryption_configuration" {
    for_each = each.value.default_encryption_configuration != null ? [each.value.default_encryption_configuration] : []

    content {
      kms_key_name = default_encryption_configuration.value.kms_key_name
    }
  }

  dynamic "access" {
    for_each = each.value.access_grants

    content {
      role           = access.value.role
      domain         = access.value.domain
      group_by_email = access.value.group_by_email
      user_by_email  = access.value.user_by_email
      special_group  = access.value.special_group
      iam_member     = access.value.iam_member

      dynamic "view" {
        for_each = access.value.view != null ? [access.value.view] : []

        content {
          project_id = view.value.project_id
          dataset_id = view.value.dataset_id
          table_id   = view.value.table_id
        }
      }

      dynamic "dataset" {
        for_each = access.value.dataset != null ? [access.value.dataset] : []

        content {
          target_types = dataset.value.target_types

          dynamic "dataset" {
            for_each = [dataset.value.dataset]
            iterator = target

            content {
              project_id = target.value.project_id
              dataset_id = target.value.dataset_id
            }
          }
        }
      }

      dynamic "routine" {
        for_each = access.value.routine != null ? [access.value.routine] : []

        content {
          project_id = routine.value.project_id
          dataset_id = routine.value.dataset_id
          routine_id = routine.value.routine_id
        }
      }

      dynamic "condition" {
        for_each = access.value.condition != null ? [access.value.condition] : []

        content {
          title       = condition.value.title
          description = condition.value.description
          expression  = condition.value.expression
        }
      }
    }
  }
}

resource "google_bigquery_table" "table" {
  for_each = local.tables

  dataset_id                   = each.value.dataset.dataset_id
  project                      = each.value.table.project_id
  table_id                     = each.value.table.table_id
  friendly_name                = each.value.table.friendly_name
  description                  = each.value.table.description
  labels                       = each.value.table.labels
  expiration_time              = each.value.table.expiration_time
  require_partition_filter     = each.value.table.require_partition_filter
  deletion_policy              = each.value.table.deletion_policy
  deletion_protection          = each.value.table.deletion_protection
  schema                       = each.value.table.schema
  ignore_auto_generated_schema = each.value.table.ignore_auto_generated_schema
  clustering                   = each.value.table.clustering
  resource_tags                = each.value.table.resource_tags

  dynamic "time_partitioning" {
    for_each = each.value.table.time_partitioning != null ? [each.value.table.time_partitioning] : []

    content {
      type          = time_partitioning.value.type
      field         = time_partitioning.value.field
      expiration_ms = time_partitioning.value.expiration_ms
    }
  }

  dynamic "range_partitioning" {
    for_each = each.value.table.range_partitioning != null ? [each.value.table.range_partitioning] : []

    content {
      field = range_partitioning.value.field

      range {
        start    = range_partitioning.value.range.start
        end      = range_partitioning.value.range.end
        interval = range_partitioning.value.range.interval
      }
    }
  }

  dynamic "view" {
    for_each = each.value.table.view != null ? [each.value.table.view] : []

    content {
      query          = view.value.query
      use_legacy_sql = view.value.use_legacy_sql
    }
  }

  dynamic "materialized_view" {
    for_each = each.value.table.materialized_view != null ? [each.value.table.materialized_view] : []

    content {
      query                            = materialized_view.value.query
      enable_refresh                   = materialized_view.value.enable_refresh
      refresh_interval_ms              = materialized_view.value.refresh_interval_ms
      allow_non_incremental_definition = materialized_view.value.allow_non_incremental_definition
    }
  }

  dynamic "encryption_configuration" {
    for_each = each.value.table.encryption_configuration != null ? [each.value.table.encryption_configuration] : []

    content {
      kms_key_name = encryption_configuration.value.kms_key_name
    }
  }

  dynamic "external_data_configuration" {
    for_each = each.value.table.external_data_configuration != null ? [each.value.table.external_data_configuration] : []

    content {
      autodetect            = external_data_configuration.value.autodetect
      source_format         = external_data_configuration.value.source_format
      source_uris           = external_data_configuration.value.source_uris
      schema                = external_data_configuration.value.schema
      connection_id         = external_data_configuration.value.connection_id
      ignore_unknown_values = external_data_configuration.value.ignore_unknown_values
      max_bad_records       = external_data_configuration.value.max_bad_records
      compression           = external_data_configuration.value.compression

      dynamic "csv_options" {
        for_each = external_data_configuration.value.csv_options != null ? [external_data_configuration.value.csv_options] : []

        content {
          quote                 = csv_options.value.quote
          skip_leading_rows     = csv_options.value.skip_leading_rows
          field_delimiter       = csv_options.value.field_delimiter
          allow_jagged_rows     = csv_options.value.allow_jagged_rows
          allow_quoted_newlines = csv_options.value.allow_quoted_newlines
          encoding              = csv_options.value.encoding
        }
      }

      dynamic "google_sheets_options" {
        for_each = external_data_configuration.value.google_sheets_options != null ? [external_data_configuration.value.google_sheets_options] : []

        content {
          skip_leading_rows = google_sheets_options.value.skip_leading_rows
          range             = google_sheets_options.value.range
        }
      }

      dynamic "hive_partitioning_options" {
        for_each = external_data_configuration.value.hive_partitioning_options != null ? [external_data_configuration.value.hive_partitioning_options] : []

        content {
          mode                     = hive_partitioning_options.value.mode
          source_uri_prefix        = hive_partitioning_options.value.source_uri_prefix
          require_partition_filter = hive_partitioning_options.value.require_partition_filter
        }
      }
    }
  }

  depends_on = [google_bigquery_dataset.dataset]
}

resource "google_bigquery_dataset_iam_binding" "binding" {
  for_each = local.dataset_role_bindings

  dataset_id = google_bigquery_dataset.dataset[each.value.dataset_key].dataset_id
  project    = each.value.dataset.project_id

  role    = each.value.binding.role
  members = each.value.binding.members

  dynamic "condition" {
    for_each = each.value.binding.condition != null ? [each.value.binding.condition] : []

    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }

  depends_on = [google_bigquery_dataset.dataset]
}
