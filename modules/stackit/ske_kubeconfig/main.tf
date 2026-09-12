terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_ske_kubeconfig" "kubeconfig" {
  for_each = var.kubeconfigs

  project_id     = each.value.project_id
  cluster_name   = each.value.cluster_name
  region         = each.value.region
  expiration     = each.value.expiration
  refresh        = each.value.refresh
  refresh_before = each.value.refresh_before
}
