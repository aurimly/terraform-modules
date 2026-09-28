locals {
  cert_domains = {
    for k, c in var.certificates : k => distinct(concat([c.domain_name], [for s in c.subject_alternative_names : replace(s, "*.", "")]))
  }

  cert_zone_ids = {
    for k, c in var.certificates : k => c.route53_zone != null ? try(var.zone_keys[c.route53_zone], "key:${c.route53_zone}") : c.route53_zone_id
  }

  cert_claim_keys = {
    for ck in keys(local.validation_certs) : ck => [for d in local.cert_domains[ck] : "${local.cert_zone_ids[ck]}|${d}"]
  }

  validation_certs = {
    for k, c in var.certificates : k => c
    if c.validation_method == "DNS" && (c.route53_zone != null || c.route53_zone_id != null) && c.create_validation_records
  }

  validation_claims = merge([
    for ck in reverse(sort(keys(local.validation_certs))) : {
      for d in local.cert_domains[ck] : "${local.cert_zone_ids[ck]}|${d}" => {
        cert_key     = ck
        domain       = d
        zone_id      = local.cert_zone_ids[ck]
        route53_zone = var.certificates[ck].route53_zone
      }
    }
  ]...)

  validation_dvos = {
    for claim_key, claim in local.validation_claims : claim_key =>
    [for dvo in aws_acm_certificate.certificate[claim.cert_key].domain_validation_options : dvo if replace(dvo.domain_name, "*.", "") == claim.domain][0]
  }
}

resource "aws_acm_certificate" "certificate" {
  for_each = var.certificates

  domain_name               = each.value.domain_name
  subject_alternative_names = each.value.subject_alternative_names
  validation_method         = each.value.validation_method
  certificate_authority_arn = each.value.certificate_authority_arn
  key_algorithm             = each.value.key_algorithm

  dynamic "options" {
    for_each = each.value.options != null ? [each.value.options] : []

    content {
      certificate_transparency_logging_preference = options.value.certificate_transparency_logging_preference
      export                                      = options.value.export
    }
  }

  dynamic "validation_option" {
    for_each = each.value.validation_option != null ? each.value.validation_option : []

    content {
      domain_name       = validation_option.value.domain_name
      validation_domain = validation_option.value.validation_domain
    }
  }

  tags = merge(each.value.tags, { Name = each.value.domain_name })
}

resource "aws_route53_record" "validation" {
  for_each = local.validation_claims

  zone_id = each.value.zone_id
  name    = local.validation_dvos[each.key].resource_record_name
  type    = local.validation_dvos[each.key].resource_record_type
  ttl     = 300
  records = [local.validation_dvos[each.key].resource_record_value]

  lifecycle {
    precondition {
      condition     = each.value.route53_zone == null || contains(keys(var.zone_keys), each.value.route53_zone)
      error_message = "validation record \"${each.key}\": route53_zone is not a key of the zone_keys map."
    }
  }
}

resource "aws_acm_certificate_validation" "validation" {
  for_each = local.validation_certs

  certificate_arn         = aws_acm_certificate.certificate[each.key].arn
  validation_record_fqdns = [for claim_key in local.cert_claim_keys[each.key] : aws_route53_record.validation[claim_key].fqdn]
}
