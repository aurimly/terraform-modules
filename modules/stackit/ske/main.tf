terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_ske_cluster" "cluster" {
  for_each = var.clusters

  name                   = each.value.name
  project_id             = each.value.project_id
  region                 = each.value.region
  kubernetes_version_min = each.value.kubernetes_version_min
  node_pools = [for np in each.value.node_pools : {
    name                    = np.name
    machine_type            = np.machine_type
    availability_zones      = np.availability_zones
    minimum                 = np.minimum
    maximum                 = np.maximum
    allow_system_components = np.allow_system_components
    cri                     = np.cri
    os_name                 = np.os_name
    os_version_min          = np.os_version_min
    max_surge               = np.max_surge
    max_unavailable         = np.max_unavailable
    volume_type             = np.volume_type
    volume_size             = np.volume_size
    labels                  = np.labels
    taints                  = np.taints
  }]
  access       = each.value.access
  audit        = each.value.audit
  extensions   = each.value.extensions
  hibernations = each.value.hibernations
  maintenance  = each.value.maintenance
  network      = each.value.network
}

resource "stackit_ske_kubeconfig" "kubeconfig" {
  for_each = { for k, c in var.clusters : k => c if c.kubeconfig != null }

  project_id     = each.value.project_id
  cluster_name   = stackit_ske_cluster.cluster[each.key].name
  region         = each.value.region
  expiration     = each.value.kubeconfig.expiration
  refresh        = each.value.kubeconfig.refresh
  refresh_before = each.value.kubeconfig.refresh_before
}
