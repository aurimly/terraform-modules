terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">= 2.0.0"
    }
  }
}

resource "snowflake_table" "table" {
  for_each = var.tables

  database = each.value.database
  schema   = each.value.schema
  name     = each.value.name

  dynamic "column" {
    for_each = each.value.columns

    content {
      name           = column.value.name
      type           = column.value.type
      nullable       = column.value.nullable
      collate        = column.value.collate
      comment        = column.value.comment
      masking_policy = column.value.masking_policy

      dynamic "default" {
        for_each = column.value.default != null ? [column.value.default] : []
        iterator = column_default

        content {
          constant   = column_default.value.constant
          expression = column_default.value.expression
          sequence   = column_default.value.sequence
        }
      }

      dynamic "identity" {
        for_each = column.value.identity != null ? [column.value.identity] : []
        iterator = column_identity

        content {
          start_num = column_identity.value.start_num
          step_num  = column_identity.value.step_num
        }
      }
    }
  }

  cluster_by                  = each.value.cluster_by
  change_tracking             = each.value.change_tracking
  comment                     = each.value.comment
  data_retention_time_in_days = each.value.data_retention_time_in_days
}
