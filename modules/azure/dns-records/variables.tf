variable "zones" {
  description = "Map of Azure DNS zones with their record sets. Keys are arbitrary identifiers; public zones take zone_name + resource_group_name (from the azure/dns-zone module outputs), private zones take private_dns_zone_id."
  type = map(object({
    zone_name           = optional(string)
    resource_group_name = optional(string)
    private_dns_zone_id = optional(string)
    records = map(object({
      name               = string
      type               = string
      ttl                = number
      records            = optional(list(string))
      record             = optional(string)
      target_resource_id = optional(string)
      mx = optional(list(object({
        preference = number
        exchange   = string
      })))
      srv = optional(list(object({
        priority = number
        weight   = number
        port     = number
        target   = string
      })))
      txt = optional(list(string))
      caa = optional(list(object({
        flags = number
        tag   = string
        value = string
      })))
      tags = optional(map(string), {})
    }))
  }))

  validation {
    condition = alltrue([
      for zone_key in keys(var.zones) : !can(regex("\\.", zone_key))
    ])
    error_message = "zone map keys must not contain \".\" — they are composed into record identifiers of the form \"<zone_key>.<record_key>\"; a dot would make outputs ambiguous and flattened keys collision-prone."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for record_key in keys(zone.records) : !can(regex("\\.", record_key))
      ]
    ]))
    error_message = "record map keys must not contain \".\" — they are composed into identifiers of the form \"<zone_key>.<record_key>\"; use the record name attribute to encode hostnames instead."
  }

  validation {
    condition = alltrue([
      for zone in var.zones : (zone.zone_name != null) != (zone.private_dns_zone_id != null)
    ])
    error_message = "each zone entry must reference exactly one zone: public by setting zone_name (+ resource_group_name), private by setting private_dns_zone_id."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for record in zone.records : zone.zone_name != null
        ? length(trimspace(coalesce(zone.resource_group_name, " "))) > 0
        : zone.resource_group_name == null
      ]
    ]))
    error_message = "public zone entries must set resource_group_name (the resource group hosting the zone); private zone entries must not set it — private records reference the zone by private_dns_zone_id only."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for record in zone.records : contains(["A", "AAAA", "CAA", "CNAME", "MX", "NS", "PTR", "SRV", "TXT"], record.type)
      ]
    ]))
    error_message = "records.type must be one of \"A\", \"AAAA\", \"CAA\", \"CNAME\", \"MX\", \"NS\", \"PTR\", \"SRV\" or \"TXT\" (uppercase)."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for record in zone.records : zone.private_dns_zone_id != null
        ? record.type != "CAA" && record.type != "NS" && record.target_resource_id == null
        : true
      ]
    ]))
    error_message = "private zone entries cannot hold CAA or NS records (Azure Private DNS does not support those types) and cannot alias via target_resource_id (private record resources take value-only payloads)."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for record in zone.records : zone.zone_name != null && record.target_resource_id != null
        ? can(regex("^/", record.target_resource_id))
        : true
      ]
    ]))
    error_message = "target_resource_id must be a full ARM resource ID of an Azure resource (starts with \"/\") — aliases point at things like a public IP or a load balancer."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for record in zone.records : length(trimspace(record.name)) > 0
        && (zone.zone_name == null ? record.ttl >= 0 : record.ttl >= 1)
        && record.ttl <= 2147483647
      ]
    ]))
    error_message = "each record must set a non-empty name and a ttl — public zones 1–2147483647 seconds, private 0–2147483647 (private zones also accept ttl = 0)."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for rk, r in zone.records : [
          for ok, o in zone.records :
          rk == ok || !(lower(r.name) == lower(o.name) && r.type == o.type)
        ]
      ]
    ]))
    error_message = "within one zone every record name+type combination must be unique case-insensitively — two map keys naming the same Azure record set address one record set and fail at apply with a 409 from ARM."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for record in zone.records : record.type == "A" || record.type == "AAAA"
        ? ((record.records != null && length(record.records) > 0) != (record.target_resource_id != null))
        && record.record == null && record.mx == null && record.srv == null && record.txt == null && record.caa == null
        : true
      ]
    ]))
    error_message = "A and AAAA records must set exactly one of records (value list) or target_resource_id (alias to an Azure resource, public zones only); no other payload field applies."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for record in zone.records : record.type != "CNAME"
        ? true
        : ((record.record != null && length(trimspace(record.record)) > 0) != (record.target_resource_id != null))
        && record.records == null && record.mx == null && record.srv == null && record.txt == null && record.caa == null
      ]
    ]))
    error_message = "CNAME records must set exactly one of record (target hostname) or target_resource_id (alias to an Azure resource, public zones only); no other payload field applies."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for record in zone.records : record.type == "NS" || record.type == "PTR"
        ? record.record == null && record.target_resource_id == null && record.mx == null && record.srv == null && record.txt == null && record.caa == null
        && record.records != null && length(record.records) > 0
        : record.type == "TXT"
        ? record.records == null && record.record == null && record.target_resource_id == null && record.mx == null && record.srv == null && record.caa == null && record.txt != null && length(record.txt) > 0 && alltrue([for value in record.txt : length(value) > 0])
        : record.type == "MX"
        ? record.records == null && record.record == null && record.target_resource_id == null && record.srv == null && record.txt == null && record.caa == null && record.mx != null && length(record.mx) > 0
        : record.type == "SRV"
        ? record.records == null && record.record == null && record.target_resource_id == null && record.mx == null && record.txt == null && record.caa == null && record.srv != null && length(record.srv) > 0
        : record.type == "CAA"
        ? record.records == null && record.record == null && record.target_resource_id == null && record.mx == null && record.srv == null && record.txt == null && record.caa != null && length(record.caa) > 0
        : true
      ]
    ]))
    error_message = "record payloads depend on the type: NS and PTR take one list of hostnames in records, TXT one list of strings in txt, MX the mx blocks, SRV the srv blocks and CAA the caa blocks — exactly one value source per record type, values only in the field matching the record type."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for record in zone.records : record.type == "MX" && record.mx != null
        ? alltrue([for m in record.mx : m.preference >= 0 && m.preference <= 65535 && length(trimspace(m.exchange)) > 0])
        : true
      ]
    ]))
    error_message = "MX values: preference is 0–65535 and exchange a non-empty hostname."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for record in zone.records : record.type == "SRV" && record.srv != null
        ? alltrue([for srv in record.srv : srv.port >= 0 && srv.port <= 65535 && srv.priority >= 0 && srv.priority <= 65535 && srv.weight >= 0 && srv.weight <= 65535 && length(trimspace(srv.target)) > 0])
        : true
      ]
    ]))
    error_message = "SRV values: port, priority and weight are 0–65535 and target a non-empty hostname (a leading dot targets the zone apex)."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for record in zone.records : record.type == "CAA" && record.caa != null
        ? alltrue([for caa in record.caa : contains(["issue", "issuewild", "iodef", "contactemail"], caa.tag) && caa.flags >= 0 && caa.flags <= 255 && length(trimspace(caa.value)) > 0])
        : true
      ]
    ]))
    error_message = "CAA values: tag one of \"issue\", \"issuewild\", \"iodef\" or \"contactemail\", flags 0–255 and a non-empty value."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for record in zone.records : contains(["A"], record.type) && record.records != null
        ? alltrue([for ipv4 in record.records : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", ipv4)) && can(cidrhost("${ipv4}/32", 0))])
        : true
      ]
    ]))
    error_message = "A record values must be IPv4 addresses (four dotted decimal octets, each 0–255)."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for record in zone.records : record.type == "AAAA" && record.records != null
        ? alltrue([for address in record.records : can(cidrhost("${address}/128", 0))])
        : true
      ]
    ]))
    error_message = "AAAA record values must be IPv6 addresses — bare addresses, no zone index and no port suffix."
  }

  validation {
    condition = alltrue(flatten([
      for zone in var.zones : [
        for record in zone.records : length(record.tags) <= 50 && alltrue([for k, v in record.tags : length(k) <= 512 && length(v) <= 256])
      ]
    ]))
    error_message = "record tags are limited to 50 entries, keys to 512 characters and values to 256 characters (provider-enforced limits)."
  }
}
