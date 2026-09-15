resource "google_compute_network_endpoint_group" "neg" {
  for_each = var.negs

  name                  = each.value.name
  project               = each.value.project_id
  zone                  = each.value.zone
  network               = each.value.network
  subnetwork            = each.value.subnetwork
  default_port          = each.value.default_port
  network_endpoint_type = each.value.network_endpoint_type
  description           = each.value.description
  deletion_policy       = each.value.deletion_policy
}

resource "google_compute_region_network_endpoint_group" "regional_neg" {
  for_each = var.regional_negs

  name                  = each.value.name
  project               = each.value.project_id
  region                = each.value.region
  network               = each.value.network
  subnetwork            = each.value.subnetwork
  network_endpoint_type = each.value.network_endpoint_type
  psc_target_service    = each.value.psc_target_service
  description           = each.value.description
  deletion_policy       = each.value.deletion_policy

  dynamic "psc_data" {
    for_each = each.value.psc_data != null ? [each.value.psc_data] : []

    content {
      producer_port = psc_data.value.producer_port
    }
  }

  dynamic "cloud_run" {
    for_each = each.value.cloud_run != null ? [each.value.cloud_run] : []

    content {
      service  = cloud_run.value.service
      tag      = cloud_run.value.tag
      url_mask = cloud_run.value.url_mask
    }
  }

  dynamic "app_engine" {
    for_each = each.value.app_engine != null ? [each.value.app_engine] : []

    content {
      service  = app_engine.value.service
      version  = app_engine.value.version
      url_mask = app_engine.value.url_mask
    }
  }

  dynamic "cloud_function" {
    for_each = each.value.cloud_function != null ? [each.value.cloud_function] : []

    content {
      function = cloud_function.value.function
      url_mask = cloud_function.value.url_mask
    }
  }
}

resource "google_compute_network_endpoint" "endpoint" {
  for_each = var.endpoints

  network_endpoint_group = google_compute_network_endpoint_group.neg[each.value.neg].name
  project                = each.value.project_id
  zone                   = google_compute_network_endpoint_group.neg[each.value.neg].zone
  ip_address             = each.value.ip_address
  port                   = each.value.port
  instance               = each.value.instance
  deletion_policy        = each.value.deletion_policy
}
