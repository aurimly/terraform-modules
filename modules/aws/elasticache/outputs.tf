output "redis_cluster_ids" {
  description = "Map of redis key => replication group ID (also the aws_elasticache_replication_group import ID)."
  value       = { for k, c in aws_elasticache_replication_group.redis : k => c.replication_group_id }
}

output "redis_arns" {
  description = "Map of redis key => replication group ARN."
  value       = { for k, c in aws_elasticache_replication_group.redis : k => c.arn }
}

output "redis_primary_endpoints" {
  description = "Map of redis key => primary endpoint address (cluster mode: use redis_configuration_endpoints for CONFIG commands)."
  value       = { for k, c in aws_elasticache_replication_group.redis : k => c.primary_endpoint_address }
}

output "redis_primary_ports" {
  description = "Map of redis key => primary endpoint port."
  value       = { for k, c in aws_elasticache_replication_group.redis : k => c.port }
}

output "redis_reader_endpoints" {
  description = "Map of redis key => reader endpoint address."
  value       = { for k, c in aws_elasticache_replication_group.redis : k => c.reader_endpoint_address }
}

output "redis_configuration_endpoints" {
  description = "Map of redis key => configuration endpoint {address, port}, cluster-mode groups only."
  value = {
    for k, c in aws_elasticache_replication_group.redis : k => {
      address = c.configuration_endpoint_address
      port    = c.port
    }
  }
}

output "redis_member_cluster_ids" {
  description = "Map of redis key => member cluster IDs (the <replication_group_id>-00N clusters)."
  value       = { for k, c in aws_elasticache_replication_group.redis : k => c.member_clusters }
}

output "redis_subnet_group_names" {
  description = "Map of redis key => subnet group name (module-created subnet groups use the input map key; also the aws_elasticache_subnet_group import ID)."
  value       = { for k, c in aws_elasticache_replication_group.redis : k => c.subnet_group_name }
}

output "redis_parameter_group_names" {
  description = "Map of redis key => parameter group name in use (module-created, pass-through, or engine default)."
  value       = { for k, c in aws_elasticache_replication_group.redis : k => c.parameter_group_name }
}

output "memcached_cluster_ids" {
  description = "Map of memcached key => cluster ID (also the aws_elasticache_cluster import ID)."
  value       = { for k, c in aws_elasticache_cluster.memcached : k => c.cluster_id }
}

output "memcached_arns" {
  description = "Map of memcached key => cluster ARN."
  value       = { for k, c in aws_elasticache_cluster.memcached : k => c.arn }
}

output "memcached_configuration_endpoints" {
  description = "Map of memcached key => configuration endpoint {address, port} (client-facing address for multi-node clusters)."
  value = {
    for k, c in aws_elasticache_cluster.memcached : k => {
      address = c.configuration_endpoint
      port    = c.port
    }
  }
}

output "memcached_addresses" {
  description = "Map of memcached key => list of node addresses (one per cache node)."
  value       = { for k, c in aws_elasticache_cluster.memcached : k => [for n in c.cache_nodes : n.address] }
}

output "memcached_ports" {
  description = "Map of memcached key => list of node ports (one per cache node)."
  value       = { for k, c in aws_elasticache_cluster.memcached : k => [for n in c.cache_nodes : n.port] }
}

output "memcached_cache_node_ids" {
  description = "Map of memcached key => list of cache node IDs (<cluster_id>-00N)."
  value       = { for k, c in aws_elasticache_cluster.memcached : k => [for n in c.cache_nodes : n.id] }
}

output "memcached_subnet_group_names" {
  description = "Map of memcached key => subnet group name (module-created subnet groups use the input map key; also the aws_elasticache_subnet_group import ID)."
  value       = { for k, c in aws_elasticache_cluster.memcached : k => c.subnet_group_name }
}

output "memcached_parameter_group_names" {
  description = "Map of memcached key => parameter group name in use (module-created or pass-through)."
  value       = { for k, c in aws_elasticache_cluster.memcached : k => c.parameter_group_name }
}
