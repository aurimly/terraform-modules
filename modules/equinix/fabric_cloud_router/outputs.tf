output "cloud_routers" {
  description = "Map of cloud router key => { uuid, id, state, href, equinix_asn, connections_count }. Feed uuid into equinix/fabric_connection as the CLOUD_ROUTER access point router.uuid."
  value = { for k, r in equinix_fabric_cloud_router.cloud_router : k => {
    uuid              = r.uuid
    id                = r.id
    state             = r.state
    href              = r.href
    equinix_asn       = r.equinix_asn
    connections_count = r.connections_count
  } }
}
