/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

output "mysql_constraint_name" {
  description = "Name of the MySQL constraint"
  value       = var.enable_sql_mysql_constraints ? module.sql_mysql_constraints[0].custom_constraint_name : null
}

output "postgresql_constraint_names" {
  description = "List of PostgreSQL constraint names"
  value       = var.enable_sql_postgresql_constraints ? module.sql_postgresql_constraints[0].custom_constraint_names : []
}

output "sqlserver_constraint_names" {
  description = "List of SQL Server constraint names"
  value       = var.enable_sql_sqlserver_constraints ? module.sql_sqlserver_constraints[0].custom_constraint_names : []
}

output "alloydb_constraint_name" {
  description = "Name of the AlloyDB constraint"
  value       = var.enable_alloydb_constraints ? module.alloydb_private_ip_constraints[0].custom_constraint_name : null
}

output "alloydb_logging_constraint_names" {
  description = "Map of AlloyDB logging constraints"
  value       = var.enable_alloydb_constraints ? module.alloydb_logging_constraints[0].constraint_names : {}
}

output "dnssec_constraint_name" {
  description = "Name of the DNSSEC constraint"
  value       = var.enable_dns_constraint ? module.dns_dnssec_enabled_constraint[0].custom_constraint_name : null
}

output "dns_policy_logging_constraint_name" {
  description = "Name of the DNS Policy Logging constraint"
  value       = var.enable_dns_policy_logging_constraint ? module.dns_policy_logging_constraint[0].custom_constraint_name : null
}

# BigQuery Constraint Outputs
output "bq_dataset_cmek_constraint_name" {

  description = "Name of the BigQuery dataset CMEK constraint"
  value       = var.enable_bq_dataset_cmek_constraint ? module.bq_dataset_cmek_constraint[0].custom_constraint_name : null
}

# Dataproc Constraint Outputs
output "dataproc_cmek_constraint_name" {
  description = "Name of the Dataproc cluster CMEK constraint"
  value       = var.enable_dataproc_cmek_constraint ? module.dataproc_cmek_constraint[0].custom_constraint_name : null
}

output "instance_no_default_sa_constraint_name" {
  description = "Name of the instance no default service account constraint"
  value       = var.enable_instance_no_default_sa_constraint ? module.instance_no_default_sa_constraint[0].custom_constraint_name : null
}

output "instance_no_default_sa_full_scopes_constraint_name" {
  description = "Name of the instance no default SA with full scopes constraint"
  value       = var.enable_instance_no_default_sa_full_scopes_constraint ? module.instance_no_default_sa_full_scopes_constraint[0].custom_constraint_name : null
}

output "instance_no_ip_forwarding_constraint_name" {
  description = "Name of the instance no IP forwarding constraint"
  value       = var.enable_instance_no_ip_forwarding_constraint ? module.instance_no_ip_forwarding_constraint[0].custom_constraint_name : null
}

# DNS Constraint Outputs
output "dnssec_no_rsasha1_constraint_name" {
  description = "Name of the DNSSEC no RSASHA1 constraint"
  value       = var.enable_dnssec_no_rsasha1_constraint ? module.dnssec_no_rsasha1_constraint[0].custom_constraint_name : null
}
