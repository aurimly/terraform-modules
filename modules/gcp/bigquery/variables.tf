variable "datasets" {
  description = "Map of BigQuery datasets keyed by an arbitrary identifier. Each entry creates one google_bigquery_dataset plus optional nested tables, native access grants, and IAM bindings."
  type = map(object({
    dataset_id                      = string
    location                        = string
    project_id                      = optional(string)
    friendly_name                   = optional(string)
    description                     = optional(string)
    labels                          = optional(map(string), {})
    default_table_expiration_ms     = optional(number)
    default_partition_expiration_ms = optional(number)
    max_time_travel_hours           = optional(number)
    default_collation               = optional(string)
    is_case_insensitive             = optional(bool)
    storage_billing_model           = optional(string)
    deletion_policy                 = optional(string)
    delete_contents_on_destroy      = optional(bool)
    resource_tags                   = optional(map(string))
    default_encryption_configuration = optional(object({
      kms_key_name = string
    }))
    access_grants = optional(map(object({
      role           = optional(string)
      domain         = optional(string)
      group_by_email = optional(string)
      user_by_email  = optional(string)
      special_group  = optional(string)
      iam_member     = optional(string)
      view = optional(object({
        project_id = string
        dataset_id = string
        table_id   = string
      }))
      dataset = optional(object({
        target_types = list(string)
        dataset = object({
          project_id = string
          dataset_id = string
        })
      }))
      routine = optional(object({
        project_id = string
        dataset_id = string
        routine_id = string
      }))
      condition = optional(object({
        title       = optional(string)
        description = optional(string)
        expression  = string
      }))
    })), {})
    tables = optional(map(object({
      table_id                     = string
      project_id                   = optional(string)
      friendly_name                = optional(string)
      description                  = optional(string)
      labels                       = optional(map(string), {})
      expiration_time              = optional(number)
      deletion_policy              = optional(string)
      deletion_protection          = optional(bool)
      schema                       = optional(string)
      ignore_auto_generated_schema = optional(bool)
      require_partition_filter     = optional(bool)
      clustering                   = optional(list(string))
      resource_tags                = optional(map(string))
      time_partitioning = optional(object({
        type          = string
        field         = optional(string)
        expiration_ms = optional(number)
      }))
      range_partitioning = optional(object({
        field = string
        range = object({
          start    = number
          end      = number
          interval = number
        })
      }))
      view = optional(object({
        query          = string
        use_legacy_sql = optional(bool)
      }))
      materialized_view = optional(object({
        query                            = string
        enable_refresh                   = optional(bool)
        refresh_interval_ms              = optional(number)
        allow_non_incremental_definition = optional(bool)
      }))
      encryption_configuration = optional(object({
        kms_key_name = string
      }))
      external_data_configuration = optional(object({
        autodetect            = optional(bool)
        source_format         = optional(string)
        source_uris           = optional(list(string))
        schema                = optional(string)
        connection_id         = optional(string)
        ignore_unknown_values = optional(bool)
        max_bad_records       = optional(number)
        compression           = optional(string)
        csv_options = optional(object({
          quote                 = string
          skip_leading_rows     = optional(number)
          field_delimiter       = optional(string)
          allow_jagged_rows     = optional(bool)
          allow_quoted_newlines = optional(bool)
          encoding              = optional(string)
        }))
        google_sheets_options = optional(object({
          skip_leading_rows = optional(number)
          range             = optional(string)
        }))
        hive_partitioning_options = optional(object({
          mode                     = optional(string)
          source_uri_prefix        = optional(string)
          require_partition_filter = optional(bool)
        }))
      }))
    })), {})
    role_bindings = optional(map(object({
      role    = string
      members = list(string)
      condition = optional(object({
        title       = optional(string)
        expression  = string
        description = optional(string)
      }))
    })), {})
  }))

  validation {
    condition     = alltrue([for k in keys(var.datasets) : !can(regex("/", k))])
    error_message = "dataset keys must not contain `/`; it is the composite-key separator for nested tables, access grants and IAM bindings."
  }

  validation {
    condition     = alltrue([for d in var.datasets : alltrue([for k in keys(d.tables) : !can(regex("/", k))])])
    error_message = "table keys must not contain `/`; it is the composite-key separator (dataset key/table key) used in outputs."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : alltrue([
        for k in concat(keys(d.role_bindings), keys(d.access_grants)) : !can(regex("/", k))
      ])
    ])
    error_message = "access_grants and role_bindings keys must not contain `/`; it is the composite-key separator (dataset key/binding key) used in outputs."
  }

  validation {
    condition     = alltrue([for d in var.datasets : can(regex("^[a-zA-Z0-9_]+$", d.dataset_id))])
    error_message = "dataset_id may contain only letters, digits and underscores, up to 1024 characters (BigQuery dataset naming rules)."
  }

  validation {
    condition     = alltrue([for d in var.datasets : can(regex("^[A-Za-z]+[A-Za-z0-9-]*$", d.location))])
    error_message = "location must look like a BigQuery location (e.g. US, EU, us-central1, eu-west1, aws-us-east-1); it is a shape check, not a list of valid locations."
  }

  validation {
    condition     = alltrue([for d in var.datasets : d.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", d.project_id))])
    error_message = "project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for d in var.datasets : alltrue([for t in d.tables : t.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", t.project_id))])])
    error_message = "tables.project_id must be 6 to 30 characters, start with a lowercase letter, contain only lowercase letters, digits and hyphens, and not end with a hyphen."
  }

  validation {
    condition     = alltrue([for d in var.datasets : d.storage_billing_model == null || contains(["LOGICAL", "PHYSICAL"], d.storage_billing_model)])
    error_message = "storage_billing_model must be one of LOGICAL or PHYSICAL (case-sensitive)."
  }

  validation {
    condition     = alltrue([for d in var.datasets : d.max_time_travel_hours == null || (d.max_time_travel_hours >= 48 && d.max_time_travel_hours <= 168)])
    error_message = "max_time_travel_hours must be between 48 and 168 (BigQuery time travel window bounds)."
  }

  validation {
    condition     = alltrue([for d in var.datasets : d.default_table_expiration_ms == null || d.default_table_expiration_ms >= 3600000])
    error_message = "default_table_expiration_ms must be at least 3600000 (one hour, the provider minimum)."
  }

  validation {
    condition     = alltrue([for d in var.datasets : d.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], d.deletion_policy)])
    error_message = "deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition     = alltrue([for d in var.datasets : alltrue([for t in d.tables : t.deletion_policy == null || contains(["DELETE", "PREVENT", "ABANDON"], t.deletion_policy)])])
    error_message = "tables.deletion_policy must be one of DELETE, PREVENT or ABANDON (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : !(length(d.access_grants) > 0 && length(d.role_bindings) > 0)
    ])
    error_message = "a dataset must use either access_grants (native BigQuery ACL access blocks) or role_bindings (dataset IAM bindings), not both: IAM binding resources overwrite the dataset access policy, silently dropping access entries and authorized-view grants."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : alltrue([
        for r in d.role_bindings : r.role == null || alltrue([
          !can(regex("^[A-Z]+$", r.role)),
          can(regex("^roles/[^/]+$", r.role)) || can(regex("^(projects|organizations)/[^/]+/roles/[^/]+$", r.role)),
        ])
      ])
    ])
    error_message = "role_bindings.role must be a predefined role (roles/bigquery.dataViewer and similar) or a fully qualified custom role (projects/{project}/roles/{id} or organizations/{org}/roles/{id}); bare legacy roles (OWNER, WRITER, READER) are not valid on IAM bindings."
  }

  validation {
    condition     = alltrue([for d in var.datasets : length(distinct([for r in d.role_bindings : r.role])) == length(d.role_bindings)])
    error_message = "role_bindings.role must be unique within each dataset; one IAM binding resource exists per role."
  }

  validation {
    condition     = alltrue([for d in var.datasets : alltrue([for r in d.role_bindings : length(r.members) > 0])])
    error_message = "role_bindings.members must contain at least one member."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : alltrue([
        for g in d.access_grants : length([
          for v in [
            g.domain, g.group_by_email, g.user_by_email, g.special_group,
            g.iam_member, g.view, g.dataset, g.routine,
          ] : v if v != null
        ]) == 1
      ])
    ])
    error_message = "access_grants identity must use exactly one of domain, group_by_email, user_by_email, special_group, iam_member, view, dataset or routine."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : alltrue([
        for g in d.access_grants : g.role != null || (g.view != null || g.routine != null || (g.dataset != null && g.dataset.target_types == ["VIEWS"]))
      ])
    ])
    error_message = "access_grants.role is required except for view and routine grants and for authorized datasets with target_types = [\"VIEWS\"] (the API ignores role there)."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : alltrue([
        for g in d.access_grants : g.dataset == null || g.dataset.target_types == ["VIEWS"]
      ])
    ])
    error_message = "access_grants.dataset.target_types supports only [\"VIEWS\"] (settled authorized-dataset grants; the other target types are not yet supported everywhere)."
  }

  validation {
    condition     = alltrue([for d in var.datasets : alltrue([for t in d.tables : can(regex("^[a-zA-Z0-9_]+$", t.table_id))])])
    error_message = "tables.table_id may contain only letters, digits and underscores, up to 1024 characters (BigQuery table naming rules); views in the same dataset count against this space and cannot start with a digit or underscore."
  }

  validation {
    condition     = alltrue([for d in var.datasets : alltrue([for t in d.tables : t.schema == null || alltrue([for e in try(jsondecode(t.schema), []) : can(e.name) && can(e.type)])])])
    error_message = "tables.schema must be a JSON string of a list of field objects, each with name and type (e.g. [{\"name\": \"id\", \"type\": \"STRING\"}])."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : alltrue([
        for t in d.tables : t.external_data_configuration == null || t.external_data_configuration.schema == null || alltrue([for e in try(jsondecode(t.external_data_configuration.schema), []) : can(e.name) && can(e.type)])
      ])
    ])
    error_message = "tables.external_data_configuration.schema must be a JSON string parsing to a JSON list of field objects; note it lives inside the external block, not at table level (except with connection_id)."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : alltrue([
        for t in d.tables : t.time_partitioning == null || contains(["DAY", "HOUR", "MONTH", "YEAR"], t.time_partitioning.type)
      ])
    ])
    error_message = "tables.time_partitioning.type must be one of DAY, HOUR, MONTH or YEAR (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : alltrue([
        for t in d.tables : !(t.time_partitioning != null && t.range_partitioning != null)
      ])
    ])
    error_message = "a table cannot set both time_partitioning and range_partitioning; BigQuery supports one partitioning scheme per table."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : alltrue([
        for t in d.tables : t.range_partitioning == null || alltrue([
          t.range_partitioning.range.start < t.range_partitioning.range.end,
          t.range_partitioning.range.interval > 0,
          t.range_partitioning.range.interval <= t.range_partitioning.range.end - t.range_partitioning.range.start,
        ])
      ])
    ])
    error_message = "tables.range_partitioning.range requires start < end, a positive interval, and interval <= end - start."
  }

  validation {
    condition     = alltrue([for d in var.datasets : alltrue([for t in d.tables : t.clustering == null || length(t.clustering) <= 4])])
    error_message = "tables.clustering accepts at most 4 columns."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : alltrue([
        for t in d.tables : t.clustering == null || t.time_partitioning != null || t.range_partitioning != null
      ])
    ])
    error_message = "tables.clustering requires partitioning on a new table (BigQuery rejects clustered, non-partitioned table creation)."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : alltrue([
        for t in d.tables : length([for v in [t.view != null, t.materialized_view != null, t.external_data_configuration != null] : v if v]) <= 1
      ])
    ])
    error_message = "a table allows at most one of view, materialized_view or external_data_configuration; none set means a physical table with a schema."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : alltrue([
        for t in d.tables : alltrue([
          t.view == null || t.schema == null,
          t.materialized_view == null || t.schema == null,
        ])
      ])
    ])
    error_message = "tables.view and tables.materialized_view replace the schema; a table cannot set both a schema and a view or materialized view."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : alltrue([
        for t in d.tables : anytrue([t.view != null, t.materialized_view != null, t.external_data_configuration != null, t.schema != null])
      ])
    ])
    error_message = "a physical table requires tables.schema (JSON); without it set view, materialized_view or external_data_configuration instead."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : alltrue([
        for t in d.tables : t.external_data_configuration == null || t.external_data_configuration.autodetect == true || t.external_data_configuration.schema != null
      ])
    ])
    error_message = "tables.external_data_configuration requires schema (JSON inside the external block) or autodetect = true; without either the API rejects the table at apply."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : alltrue([
        for t in d.tables : t.external_data_configuration == null || t.external_data_configuration.source_uris == null || length(t.external_data_configuration.source_uris) > 0
      ])
    ])
    error_message = "tables.external_data_configuration.source_uris must contain at least one URI."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : alltrue([
        for t in d.tables : t.external_data_configuration == null || t.external_data_configuration.csv_options == null || (t.external_data_configuration.csv_options.quote != null && length(t.external_data_configuration.csv_options.quote) > 0)
      ])
    ])
    error_message = "tables.external_data_configuration.csv_options.quote is required (it must be a single character); Terraform defers the default to the API, so set it explicitly."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : alltrue([
        for t in d.tables : t.external_data_configuration == null || t.external_data_configuration.google_sheets_options == null || (t.external_data_configuration.google_sheets_options.skip_leading_rows != null || t.external_data_configuration.google_sheets_options.range != null)
      ])
    ])
    error_message = "tables.external_data_configuration.google_sheets_options requires at least one of skip_leading_rows or range."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : alltrue([
        for t in d.tables : t.external_data_configuration == null || t.external_data_configuration.hive_partitioning_options == null || t.external_data_configuration.hive_partitioning_options.mode == null || contains(["AUTO", "STRING", "CUSTOM"], t.external_data_configuration.hive_partitioning_options.mode)
      ])
    ])
    error_message = "tables.external_data_configuration.hive_partitioning_options.mode must be one of AUTO, STRING or CUSTOM (case-sensitive)."
  }

  validation {
    condition = alltrue([
      for d in var.datasets : alltrue([
        for t in d.tables : t.external_data_configuration == null || t.external_data_configuration.connection_id == null || (t.schema != null && t.external_data_configuration.schema == null)
      ])
    ])
    error_message = "tables.external_data_configuration.connection_id requires the schema in the top-level tables.schema field, not inside external_data_configuration.schema (which must then be unset)."
  }
}
