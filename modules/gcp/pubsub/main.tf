locals {
  subscriptions = {
    for b in flatten([
      for topic_key, topic in var.topics : [
        for sub_key, sub in topic.subscriptions : {
          topic_key    = topic_key
          sub_key      = sub_key
          topic        = topic
          subscription = sub
        }
      ]
    ]) : "${b.topic_key}/${b.sub_key}" => b
  }

  topic_role_bindings = {
    for b in flatten([
      for topic_key, topic in var.topics : [
        for binding_key, binding in topic.role_bindings : {
          topic_key   = topic_key
          binding_key = binding_key
          role        = binding.role
          members     = binding.members
          condition   = binding.condition
        }
      ]
    ]) : "${b.topic_key}/${b.binding_key}" => b
  }

  subscription_role_bindings = {
    for b in flatten([
      for topic_key, topic in var.topics : [
        for sub_key, sub in topic.subscriptions : [
          for binding_key, binding in sub.role_bindings : {
            topic_key   = topic_key
            sub_key     = sub_key
            binding_key = binding_key
            role        = binding.role
            members     = binding.members
            condition   = binding.condition
          }
        ]
      ]
    ]) : "${b.topic_key}/${b.sub_key}/${b.binding_key}" => b
  }
}

resource "google_pubsub_topic" "topic" {
  for_each = var.topics

  name                       = each.value.name
  project                    = each.value.project_id
  labels                     = each.value.labels
  kms_key_name               = each.value.kms_key_name
  message_retention_duration = each.value.message_retention_duration
  deletion_policy            = each.value.deletion_policy

  dynamic "schema_settings" {
    for_each = each.value.schema_settings != null ? [each.value.schema_settings] : []

    content {
      schema            = schema_settings.value.schema
      encoding          = schema_settings.value.encoding
      first_revision_id = schema_settings.value.first_revision_id
      last_revision_id  = schema_settings.value.last_revision_id
    }
  }

  dynamic "message_storage_policy" {
    for_each = each.value.message_storage_policy != null ? [each.value.message_storage_policy] : []

    content {
      allowed_persistence_regions = message_storage_policy.value.allowed_persistence_regions
      enforce_in_transit          = message_storage_policy.value.enforce_in_transit
    }
  }
}

resource "google_pubsub_subscription" "subscription" {
  for_each = local.subscriptions

  name    = each.value.subscription.name
  topic   = google_pubsub_topic.topic[each.value.topic_key].id
  project = each.value.subscription.project_id
  labels  = each.value.subscription.labels

  ack_deadline_seconds         = each.value.subscription.ack_deadline_seconds
  message_retention_duration   = each.value.subscription.message_retention_duration
  retain_acked_messages        = each.value.subscription.retain_acked_messages
  deletion_policy              = each.value.subscription.deletion_policy
  enable_message_ordering      = each.value.subscription.enable_message_ordering
  enable_exactly_once_delivery = each.value.subscription.enable_exactly_once_delivery
  filter                       = each.value.subscription.filter

  dynamic "expiration_policy" {
    for_each = each.value.subscription.expiration_policy != null ? [each.value.subscription.expiration_policy] : []

    content {
      ttl = expiration_policy.value.ttl
    }
  }

  dynamic "dead_letter_policy" {
    for_each = each.value.subscription.dead_letter_policy != null ? [each.value.subscription.dead_letter_policy] : []

    content {
      dead_letter_topic     = dead_letter_policy.value.dead_letter_topic
      max_delivery_attempts = dead_letter_policy.value.max_delivery_attempts
    }
  }

  dynamic "retry_policy" {
    for_each = each.value.subscription.retry_policy != null ? [each.value.subscription.retry_policy] : []

    content {
      minimum_backoff = retry_policy.value.minimum_backoff
      maximum_backoff = retry_policy.value.maximum_backoff
    }
  }

  dynamic "push_config" {
    for_each = each.value.subscription.push_config != null ? [each.value.subscription.push_config] : []

    content {
      push_endpoint = push_config.value.push_endpoint
      attributes    = push_config.value.attributes

      dynamic "no_wrapper" {
        for_each = push_config.value.no_wrapper != null ? [push_config.value.no_wrapper] : []

        content {
          write_metadata = no_wrapper.value.write_metadata
        }
      }

      dynamic "oidc_token" {
        for_each = push_config.value.oidc_token != null ? [push_config.value.oidc_token] : []

        content {
          service_account_email = oidc_token.value.service_account_email
          audience              = oidc_token.value.audience
        }
      }
    }
  }

  dynamic "bigquery_config" {
    for_each = each.value.subscription.bigquery_config != null ? [each.value.subscription.bigquery_config] : []

    content {
      table                 = bigquery_config.value.table
      use_topic_schema      = bigquery_config.value.use_topic_schema
      use_table_schema      = bigquery_config.value.use_table_schema
      write_metadata        = bigquery_config.value.write_metadata
      drop_unknown_fields   = bigquery_config.value.drop_unknown_fields
      service_account_email = bigquery_config.value.service_account_email
    }
  }

  dynamic "cloud_storage_config" {
    for_each = each.value.subscription.cloud_storage_config != null ? [each.value.subscription.cloud_storage_config] : []

    content {
      bucket                   = cloud_storage_config.value.bucket
      filename_prefix          = cloud_storage_config.value.filename_prefix
      filename_suffix          = cloud_storage_config.value.filename_suffix
      filename_datetime_format = cloud_storage_config.value.filename_datetime_format
      max_duration             = cloud_storage_config.value.max_duration
      max_bytes                = cloud_storage_config.value.max_bytes
      max_messages             = cloud_storage_config.value.max_messages
      service_account_email    = cloud_storage_config.value.service_account_email

      dynamic "text_config" {
        for_each = cloud_storage_config.value.text_config == true ? [1] : []

        content {}
      }

      dynamic "avro_config" {
        for_each = cloud_storage_config.value.avro_config != null ? [cloud_storage_config.value.avro_config] : []

        content {
          write_metadata   = avro_config.value.write_metadata
          use_topic_schema = avro_config.value.use_topic_schema
        }
      }
    }
  }

  depends_on = [google_pubsub_topic.topic]
}

resource "google_pubsub_topic_iam_binding" "topic_binding" {
  for_each = local.topic_role_bindings

  topic = google_pubsub_topic.topic[each.value.topic_key].id

  role    = each.value.role
  members = each.value.members

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []

    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }

  depends_on = [google_pubsub_topic.topic]
}

resource "google_pubsub_subscription_iam_binding" "subscription_binding" {
  for_each = local.subscription_role_bindings

  subscription = google_pubsub_subscription.subscription["${each.value.topic_key}/${each.value.sub_key}"].id

  role    = each.value.role
  members = each.value.members

  dynamic "condition" {
    for_each = each.value.condition != null ? [each.value.condition] : []

    content {
      title       = condition.value.title
      description = condition.value.description
      expression  = condition.value.expression
    }
  }

  depends_on = [google_pubsub_subscription.subscription]
}
