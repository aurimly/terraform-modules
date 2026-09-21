output "affinity_groups" {
  description = "Map of affinity group key => object with `affinity_group_id` (the UUID to feed into stackit/server's `affinity_group` input), `members` (list of member server UUIDs) and `id` (\"{project_id},{region},{affinity_group_id}\", the import ID)."
  value = { for k, g in stackit_affinity_group.affinity_group : k => {
    affinity_group_id = g.affinity_group_id
    members           = g.members
    id                = g.id
  } }
}
