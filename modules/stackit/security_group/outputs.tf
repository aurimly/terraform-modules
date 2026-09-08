output "security_groups" {
  description = "Map of security group key => object with `security_group_id` (UUID) and `id` (\"{project_id},{region},{security_group_id}\", the import ID)."
  value = { for k, g in stackit_security_group.security_group : k => {
    security_group_id = g.security_group_id
    id                = g.id
  } }
}

output "rules" {
  description = "Map of security group rule composite key (\"<group key>.<rule key>\") => object with `security_group_rule_id` (UUID) and `id` (\"{project_id},{region},{security_group_id},{security_group_rule_id}\", the import ID)."
  value = { for k, r in stackit_security_group_rule.rule : k => {
    security_group_rule_id = r.security_group_rule_id
    id                     = r.id
  } }
}
