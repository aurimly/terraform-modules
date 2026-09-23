output "instance_arns" {
  description = "Map of instance key => DB instance ARN."
  value       = { for k, db in aws_db_instance.instance : k => db.arn }
}

output "instance_addresses" {
  description = "Map of instance key => DB instance connection address."
  value       = { for k, db in aws_db_instance.instance : k => db.address }
}

output "instance_endpoints" {
  description = "Map of instance key => endpoint (host:port)."
  value       = { for k, db in aws_db_instance.instance : k => db.endpoint }
}

output "cluster_arns" {
  description = "Map of cluster key => cluster ARN."
  value       = { for k, c in aws_rds_cluster.cluster : k => c.arn }
}

output "cluster_endpoints" {
  description = "Map of cluster key => writer endpoint (host:port)."
  value       = { for k, c in aws_rds_cluster.cluster : k => c.endpoint }
}

output "cluster_reader_endpoints" {
  description = "Map of cluster key => reader endpoint (host:port)."
  value       = { for k, c in aws_rds_cluster.cluster : k => c.reader_endpoint }
}

output "cluster_ids" {
  description = "Map of cluster key => cluster identifier."
  value       = { for k, c in aws_rds_cluster.cluster : k => c.cluster_identifier }
}

output "cluster_instance_ids" {
  description = "Map of \"cluster-key.instance-key\" => cluster instance identifier."
  value       = { for k, i in aws_rds_cluster_instance.cluster_instance : k => i.identifier }
}
