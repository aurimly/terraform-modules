terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = ">= 2.0.0"
    }
  }
}

resource "snowflake_stream_on_table" "stream" {
  for_each = var.streams

  database          = each.value.database
  schema            = each.value.schema
  name              = each.value.name
  table             = each.value.table
  append_only       = each.value.append_only != null ? tostring(each.value.append_only) : null
  show_initial_rows = each.value.show_initial_rows != null ? tostring(each.value.show_initial_rows) : null
  copy_grants       = each.value.copy_grants
  comment           = each.value.comment

  dynamic "at" {
    for_each = each.value.at != null ? [each.value.at] : []

    content {
      offset    = at.value.offset
      statement = at.value.statement
      stream    = at.value.stream
      timestamp = at.value.timestamp
    }
  }

  dynamic "before" {
    for_each = each.value.before != null ? [each.value.before] : []

    content {
      offset    = before.value.offset
      statement = before.value.statement
      stream    = before.value.stream
      timestamp = before.value.timestamp
    }
  }
}
