terraform {
  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = ">= 12.0.0"
    }
  }
}

resource "akamai_dns_record" "record" {
  for_each = var.records

  zone       = var.zone
  name       = each.value.name
  recordtype = each.value.recordtype
  ttl        = each.value.ttl
  target     = each.value.target

  subtype                = each.value.subtype
  flags                  = each.value.flags
  protocol               = each.value.protocol
  algorithm              = each.value.algorithm
  key                    = each.value.key
  keytag                 = each.value.keytag
  digest_type            = each.value.digest_type
  digest                 = each.value.digest
  hardware               = each.value.hardware
  software               = each.value.software
  priority               = each.value.priority
  order                  = each.value.order
  preference             = each.value.preference
  flagsnaptr             = each.value.flagsnaptr
  service                = each.value.service
  regexp                 = each.value.regexp
  replacement            = each.value.replacement
  iterations             = each.value.iterations
  salt                   = each.value.salt
  next_hashed_owner_name = each.value.next_hashed_owner_name
  type_bitmaps           = each.value.type_bitmaps
  mailbox                = each.value.mailbox
  txt                    = each.value.txt
  type_covered           = each.value.type_covered
  original_ttl           = each.value.original_ttl
  expiration             = each.value.expiration
  inception              = each.value.inception
  signer                 = each.value.signer
  signature              = each.value.signature
  labels                 = each.value.labels
  weight                 = each.value.weight
  port                   = each.value.port
  fingerprint_type       = each.value.fingerprint_type
  fingerprint            = each.value.fingerprint
  priority_increment     = each.value.priority_increment
  name_server            = each.value.name_server
  email_address          = each.value.email_address
  refresh                = each.value.refresh
  retry                  = each.value.retry
  expiry                 = each.value.expiry
  nxdomain_ttl           = each.value.nxdomain_ttl
  usage                  = each.value.usage
  selector               = each.value.selector
  match_type             = each.value.match_type
  certificate            = each.value.certificate
  type_value             = each.value.type_value
  type_mnemonic          = each.value.type_mnemonic
  svc_priority           = each.value.svc_priority
  svc_params             = each.value.svc_params
  target_name            = each.value.target_name
}
