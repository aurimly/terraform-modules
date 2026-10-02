output "placement_groups" {
  description = "Map of placement group key => object with `id` (string of the numeric placement group ID, also the import ID), `name`, `labels` and `servers` (lexically sorted list of member server IDs as strings)."
  value = { for k, pg in hcloud_placement_group.placement_group : k => {
    id      = tostring(pg.id)
    name    = pg.name
    labels  = pg.labels
    servers = sort([for s in pg.servers : tostring(s)])
  } }
}
