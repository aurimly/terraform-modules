output "load_balancers" {
  description = "Map of load balancer key => object with `private_address` (transient — changes on replacement), `security_group_id` (security group assigned to the load balancer's targets), `load_balancer_security_group_id` (the load balancer's own security group, allow it in target-side security groups), `version` and `id` (\"{project_id},{region},{name}\", the import ID)."
  value = { for k, lb in stackit_loadbalancer.load_balancer : k => {
    private_address                 = lb.private_address
    security_group_id               = lb.security_group_id
    load_balancer_security_group_id = lb.load_balancer_security_group_id
    version                         = lb.version
    id                              = lb.id
  } }
}
