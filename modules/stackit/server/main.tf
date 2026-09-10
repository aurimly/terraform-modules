terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_server" "server" {
  for_each = var.servers

  project_id        = each.value.project_id
  region            = each.value.region
  name              = each.value.name
  machine_type      = each.value.machine_type
  availability_zone = each.value.availability_zone
  image_id          = each.value.image_id
  boot_volume = each.value.boot_volume != null ? {
    source_type           = each.value.boot_volume.source_type
    source_id             = each.value.boot_volume.source_id
    size                  = each.value.boot_volume.size
    performance_class     = each.value.boot_volume.performance_class
    delete_on_termination = each.value.boot_volume.delete_on_termination
  } : null
  network_interfaces = each.value.network_interface_ids
  keypair_name       = each.value.keypair_name
  affinity_group     = each.value.affinity_group
  user_data          = each.value.user_data
  desired_status     = each.value.desired_status
  labels             = each.value.labels

  agent = each.value.agent_provisioning_policy != null ? {
    provisioning_policy = each.value.agent_provisioning_policy
  } : null
}
