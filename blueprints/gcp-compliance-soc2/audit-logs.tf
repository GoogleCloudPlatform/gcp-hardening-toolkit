module "enable-audit-logs" {
  source          = "../../modules/gcp-logging-audit-logs"
  organization_id = split("/", var.parent)[0] == "organizations" ? split("/", var.parent)[1] : ""
  log_project_id  = var.project_id
}
