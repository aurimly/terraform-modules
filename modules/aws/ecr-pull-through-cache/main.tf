resource "aws_ecr_pull_through_cache_rule" "rule" {
  for_each = var.rules

  ecr_repository_prefix      = each.value.ecr_repository_prefix
  upstream_registry_url      = each.value.upstream_registry_url
  credential_arn             = each.value.credential_arn
  custom_role_arn            = each.value.custom_role_arn
  upstream_repository_prefix = each.value.upstream_repository_prefix
}
