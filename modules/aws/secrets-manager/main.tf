resource "aws_secretsmanager_secret" "secret" {
  for_each = var.secrets

  name                           = each.value.name
  name_prefix                    = each.value.name_prefix
  description                    = each.value.description
  kms_key_id                     = each.value.kms_key_id
  recovery_window_in_days        = each.value.recovery_window_in_days
  force_overwrite_replica_secret = each.value.force_overwrite_replica_secret
  type                           = each.value.type
  tags                           = merge(each.value.tags, { Name = coalesce(each.value.name, each.value.name_prefix) })

  dynamic "replica" {
    for_each = each.value.replicas

    content {
      region     = replica.value.region
      kms_key_id = replica.value.kms_key_id
    }
  }

  lifecycle {
    precondition {
      condition     = (each.value.name != null) != (each.value.name_prefix != null)
      error_message = "secret \"${each.key}\" must set exactly one of name or name_prefix."
    }
  }
}

resource "aws_secretsmanager_secret_version" "version" {
  for_each = { for k, s in var.secrets : k => s if s.secret_string != null || s.secret_binary != null }

  secret_id      = aws_secretsmanager_secret.secret[each.key].id
  secret_string  = each.value.secret_string
  secret_binary  = each.value.secret_binary
  version_stages = each.value.version_stages
}

resource "aws_secretsmanager_secret_rotation" "rotation" {
  for_each = { for k, s in var.secrets : k => s if s.rotation != null }

  secret_id           = aws_secretsmanager_secret.secret[each.key].id
  rotation_lambda_arn = each.value.rotation.rotation_lambda_arn
  rotate_immediately  = each.value.rotation.rotate_immediately

  dynamic "rotation_rules" {
    for_each = [each.value.rotation.rotation_rules]

    content {
      automatically_after_days = rotation_rules.value.automatically_after_days
      schedule_expression      = rotation_rules.value.schedule_expression
      duration                 = rotation_rules.value.duration
    }
  }

  depends_on = [aws_secretsmanager_secret_version.version]
}
