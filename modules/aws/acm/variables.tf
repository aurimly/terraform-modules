variable "certificates" {
  description = "Map of ACM certificates keyed by an arbitrary identifier. Each entry requests one aws_acm_certificate, plus Route 53 validation records and an aws_acm_certificate_validation for DNS-validated certificates with zone info (see create_validation_records). Private CA ARNs are pass-through (pair with AWS Private CA); private-key import is out of scope."
  type = map(object({
    domain_name               = string
    subject_alternative_names = optional(set(string), [])
    validation_method         = optional(string, "DNS")
    certificate_authority_arn = optional(string)
    key_algorithm             = optional(string)
    options = optional(object({
      certificate_transparency_logging_preference = optional(string, "ENABLED")
      export                                      = optional(string)
    }))
    validation_option = optional(list(object({
      domain_name       = string
      validation_domain = string
    })))
    route53_zone              = optional(string)
    route53_zone_id           = optional(string)
    create_validation_records = optional(bool, true)
    tags                      = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = !anytrue([for k in keys(var.certificates) : can(regex("\\.", k))])
    error_message = "Map keys must not contain \".\"."
  }

  validation {
    condition     = alltrue([for c in var.certificates : can(regex("^([*]\\.)?([A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?\\.)+[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$", c.domain_name))])
    error_message = "domain_name must be a valid DNS name (letters, digits and hyphens in labels, no leading or trailing hyphens, optional leading *. for wildcards; ACM domain naming rules)."
  }

  validation {
    condition     = alltrue([for c in var.certificates : c.validation_method == null || contains(["DNS", "EMAIL"], c.validation_method)])
    error_message = "validation_method must be DNS or EMAIL; leave it unset for Private CA certificates (the API issues private certificates without domain validation)."
  }

  validation {
    condition     = alltrue([for c in var.certificates : c.certificate_authority_arn == null || c.validation_method == null])
    error_message = "certificate_authority_arn requires validation_method to be unset (private certificates are issued by the CA without domain validation; set validation_method = null on the certificate entry)."
  }

  validation {
    condition     = alltrue([for c in var.certificates : c.certificate_authority_arn != null || c.validation_method != null])
    error_message = "a certificate without certificate_authority_arn must set validation_method (DNS or EMAIL); certificate import is out of scope for this module."
  }

  validation {
    condition     = alltrue([for c in var.certificates : c.key_algorithm == null || contains(["EC_prime256v1", "EC_secp384r1", "EC_secp521r1", "RSA_1024", "RSA_2048", "RSA_3072", "RSA_4096"], c.key_algorithm)])
    error_message = "key_algorithm must be one of EC_prime256v1, EC_secp384r1, EC_secp521r1, RSA_1024, RSA_2048, RSA_3072 or RSA_4096 (ACM key algorithms; RSA_2048 is the default)."
  }

  validation {
    condition     = alltrue([for c in var.certificates : c.options == null || c.options.certificate_transparency_logging_preference == null || contains(["ENABLED", "DISABLED"], c.options.certificate_transparency_logging_preference)])
    error_message = "options.certificate_transparency_logging_preference must be ENABLED or DISABLED."
  }

  validation {
    condition     = alltrue([for c in var.certificates : c.options == null || c.options.export == null || contains(["ENABLED", "DISABLED"], c.options.export)])
    error_message = "options.export must be ENABLED or DISABLED; exportable public certificates are subject to additional charges and Private CA certificates cannot be exported."
  }

  validation {
    condition     = alltrue([for c in var.certificates : c.validation_method != "EMAIL" || c.validation_option == null])
    error_message = "validation_option applies to DNS validation only (the API rejects it on EMAIL-validated certificates)."
  }

  validation {
    condition     = alltrue([for c in var.certificates : (c.route53_zone != null) != (c.route53_zone_id != null) || (c.route53_zone == null && c.route53_zone_id == null)])
    error_message = "set at most one of route53_zone (a zone_keys map key) or route53_zone_id (a hosted zone ID, Z...)."
  }

  validation {
    condition     = alltrue([for c in var.certificates : !(c.validation_method == "DNS" && c.create_validation_records && c.route53_zone == null && c.route53_zone_id == null)])
    error_message = "DNS-validated certificates with create_validation_records = true (the default) need zone info: set route53_zone (a zone_keys map key) or route53_zone_id, or set create_validation_records = false when the validation records are managed in aws/route53-records."
  }
}

variable "zone_keys" {
  description = "Map of zone key => hosted zone ID (Z...) used to resolve the certificates' route53_zone references. Feed from the aws/route53-zone zone_ids output or any id map."
  type        = map(string)
  default     = {}
}
