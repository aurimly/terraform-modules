terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = ">= 0.114.0"
    }
  }
}

resource "stackit_key_pair" "key_pair" {
  for_each = var.key_pairs

  name       = each.value.name
  public_key = each.value.public_key
  labels     = each.value.labels
}
