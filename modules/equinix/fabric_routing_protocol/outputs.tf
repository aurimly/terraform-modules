output "direct_protocols" {
  description = "Map of direct protocol key => { uuid, state, equinix_asn, href }. uuid is the import ID."
  value = { for k, p in equinix_fabric_routing_protocol.direct : k => {
    uuid        = p.uuid
    state       = p.state
    equinix_asn = p.equinix_asn
    href        = p.href
  } }
}

output "bgp_protocols" {
  description = "Map of BGP protocol key => { uuid, state, equinix_asn, href }. uuid is the import ID; equinix_asn is the Equinix-side peer ASN."
  value = { for k, p in equinix_fabric_routing_protocol.bgp : k => {
    uuid        = p.uuid
    state       = p.state
    equinix_asn = p.equinix_asn
    href        = p.href
  } }
}
