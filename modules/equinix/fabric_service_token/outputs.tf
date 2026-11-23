output "service_tokens" {
  description = "Map of service token key => { uuid, state, issuer_side, type, expiration_date_time, href }. uuid is the import ID and the value to wire into equinix/fabric_connection as a side's service_token.uuid."
  value = { for k, t in equinix_fabric_service_token.service_token : k => {
    uuid                 = t.uuid
    state                = t.state
    issuer_side          = t.issuer_side
    type                 = t.type
    expiration_date_time = t.expiration_date_time
    href                 = t.href
  } }
}
