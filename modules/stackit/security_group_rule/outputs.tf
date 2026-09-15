output "security_group_rules" {
  description = "Map of security group rule key => object with `security_group_rule_id` (UUID) and `id` (\"{project_id},{region},{security_group_id},{security_group_rule_id}\", the import ID)."
  value = { for k, r in stackit_security_group_rule.security_group_rule : k => {
    security_group_rule_id = r.security_group_rule_id
    id                     = r.id
  } }
}
