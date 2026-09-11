locals {
  providers = {
    for b in flatten([
      for pool_key, pool in var.pools : [
        for provider_key, provider in pool.providers : {
          pool_key     = pool_key
          provider_key = provider_key
          pool         = pool
          provider     = provider
        }
      ]
    ]) : "${b.pool_key}/${b.provider_key}" => b
  }

  token_creators = {
    for b in flatten([
      for pool_key, pool in var.pools : [
        for provider_key, provider in pool.providers : [
          for creator_key, creator in provider.token_creators : {
            pool_key           = pool_key
            provider_key       = provider_key
            creator_key        = creator_key
            service_account_id = can(regex("^projects/", creator.service_account)) ? creator.service_account : format("projects/%s/serviceAccounts/%s", regex("^[^@]+@([^@]+)\\.iam\\.gserviceaccount\\.com", creator.service_account)[0], creator.service_account)
            member             = creator.member
          }
        ]
      ]
    ]) : "${b.pool_key}/${b.provider_key}/${b.creator_key}" => b
  }
}

resource "google_iam_workload_identity_pool" "pool" {
  for_each = var.pools

  workload_identity_pool_id = each.value.pool_id
  project                   = each.value.project_id
  display_name              = each.value.display_name
  description               = each.value.description
  disabled                  = each.value.disabled
  mode                      = each.value.mode
  deletion_policy           = each.value.deletion_policy
}

resource "google_iam_workload_identity_pool_provider" "provider" {
  for_each = local.providers

  workload_identity_pool_id          = google_iam_workload_identity_pool.pool[each.value.pool_key].id
  workload_identity_pool_provider_id = each.value.provider.provider_id
  project                            = each.value.pool.project_id
  display_name                       = each.value.provider.display_name
  description                        = each.value.provider.description
  disabled                           = each.value.provider.disabled
  attribute_condition                = each.value.provider.attribute_condition
  attribute_mapping                  = each.value.provider.attribute_mapping
  deletion_policy                    = each.value.provider.deletion_policy

  dynamic "oidc" {
    for_each = each.value.provider.oidc != null ? [each.value.provider.oidc] : []

    content {
      issuer_uri        = oidc.value.issuer_uri
      allowed_audiences = oidc.value.allowed_audiences
      jwks_json         = oidc.value.jwks_json
    }
  }

  dynamic "saml" {
    for_each = each.value.provider.saml != null ? [each.value.provider.saml] : []

    content {
      idp_metadata_xml = saml.value.idp_metadata_xml
    }
  }

  dynamic "aws" {
    for_each = each.value.provider.aws != null ? [each.value.provider.aws] : []

    content {
      account_id = aws.value.account_id
    }
  }

  dynamic "x509" {
    for_each = each.value.provider.x509 != null ? [each.value.provider.x509] : []

    content {
      dynamic "trust_store" {
        for_each = [each.value.provider.x509.trust_store]

        content {
          dynamic "trust_anchors" {
            for_each = trust_store.value.trust_anchors

            content {
              pem_certificate = trust_anchors.value.pem_certificate
            }
          }

          dynamic "intermediate_cas" {
            for_each = trust_store.value.intermediate_cas != null ? trust_store.value.intermediate_cas : []

            content {
              pem_certificate = intermediate_cas.value.pem_certificate
            }
          }
        }
      }
    }
  }

  depends_on = [google_iam_workload_identity_pool.pool]
}

resource "google_service_account_iam_member" "token_creator" {
  for_each = local.token_creators

  service_account_id = each.value.service_account_id
  role               = "roles/iam.workloadIdentityUser"
  member             = each.value.member

  depends_on = [google_iam_workload_identity_pool_provider.provider]
}
