output "connections" {
  description = "Map of connection key => { uuid, id, state, href, direction, is_remote, redundancy_group }. uuid is the import ID. redundancy_group lets you wire a secondary from the primary's output."
  value = { for k, c in equinix_fabric_connection.connection : k => {
    uuid             = c.uuid
    id               = c.id
    state            = c.state
    href             = c.href
    direction        = c.direction
    is_remote        = c.is_remote
    redundancy_group = try(one(c.redundancy).group, null)
  } }
}
