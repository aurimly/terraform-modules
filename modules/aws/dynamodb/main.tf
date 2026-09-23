resource "aws_dynamodb_table" "table" {
  for_each = var.tables

  name                        = each.value.name
  hash_key                    = each.value.hash_key
  range_key                   = each.value.range_key
  billing_mode                = each.value.billing_mode
  read_capacity               = each.value.read_capacity
  write_capacity              = each.value.write_capacity
  deletion_protection_enabled = each.value.deletion_protection_enabled
  table_class                 = each.value.table_class
  stream_enabled              = each.value.stream_enabled
  stream_view_type            = each.value.stream_enabled ? each.value.stream_view_type : null
  tags                        = each.value.tags

  dynamic "attribute" {
    for_each = each.value.attributes

    content {
      name = attribute.key
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = each.value.global_secondary_indexes

    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = global_secondary_index.value.non_key_attributes
      read_capacity      = global_secondary_index.value.read_capacity
      write_capacity     = global_secondary_index.value.write_capacity
    }
  }

  dynamic "local_secondary_index" {
    for_each = each.value.local_secondary_indexes

    content {
      name               = local_secondary_index.value.name
      range_key          = local_secondary_index.value.range_key
      projection_type    = local_secondary_index.value.projection_type
      non_key_attributes = local_secondary_index.value.non_key_attributes
    }
  }

  dynamic "point_in_time_recovery" {
    for_each = each.value.point_in_time_recovery != null ? [each.value.point_in_time_recovery] : []

    content {
      enabled                 = point_in_time_recovery.value.enabled
      recovery_period_in_days = point_in_time_recovery.value.recovery_period_in_days
    }
  }

  dynamic "server_side_encryption" {
    for_each = each.value.server_side_encryption != null ? [each.value.server_side_encryption] : []

    content {
      enabled     = server_side_encryption.value.enabled
      kms_key_arn = server_side_encryption.value.kms_key_arn
    }
  }

  dynamic "ttl" {
    for_each = each.value.ttl != null ? [each.value.ttl] : []

    content {
      attribute_name = ttl.value.attribute_name
      enabled        = ttl.value.enabled
    }
  }
}
