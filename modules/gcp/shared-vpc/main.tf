locals {
  service_projects = {
    for s in flatten([
      for host_key, host in var.host_projects : [
        for service_project in host.service_projects : {
          host_key        = host_key
          service_project = service_project
          deletion_policy = host.service_deletion_policy
        }
      ]
    ]) : "${s.host_key}/${s.service_project}" => s
  }
}

resource "google_compute_shared_vpc_host_project" "host" {
  for_each = var.host_projects

  project         = each.value.project_id
  deletion_policy = each.value.host_deletion_policy
}

resource "google_compute_shared_vpc_service_project" "service" {
  for_each = local.service_projects

  host_project    = google_compute_shared_vpc_host_project.host[each.value.host_key].project
  service_project = each.value.service_project
  deletion_policy = each.value.deletion_policy
}
