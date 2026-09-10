terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_volume" "volume" {
  for_each = var.volumes

  project_id        = each.value.project_id
  region            = each.value.region
  availability_zone = each.value.availability_zone
  name              = each.value.name
  description       = each.value.description
  performance_class = each.value.performance_class
  size              = each.value.size
  labels            = each.value.labels

  source = each.value.source != null ? {
    type = each.value.source.type
    id   = each.value.source.id
  } : null

  encryption_parameters = each.value.encryption_parameters != null ? {
    service_account    = each.value.encryption_parameters.service_account
    kek_keyring_id     = each.value.encryption_parameters.kek_keyring_id
    kek_key_id         = each.value.encryption_parameters.kek_key_id
    kek_key_version    = each.value.encryption_parameters.kek_key_version
    key_payload_base64 = each.value.encryption_parameters.key_payload_base64
  } : null
}
