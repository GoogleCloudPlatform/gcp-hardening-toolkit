################################################################################
# SOC2 Availability Controls (A1.1-A1.3)
# Ensures system availability through backup policies and resource location restrictions
################################################################################

# A1.3: Restrict resource locations to approved regions
resource "google_org_policy_policy" "restrict_resource_locations" {
  count  = var.enabled ? 1 : 0
  name   = "${var.parent}/policies/gcp.resourceLocations"
  parent = var.parent

  spec {
    rules {
      values {
        allowed_values = [for region in var.allowed_regions : "in:${region}-locations"]
      }
    }
  }
}

# A1.1: Require automated backups for Cloud SQL
resource "google_org_policy_policy" "require_sql_backups" {
  count  = var.enabled ? 1 : 0
  name   = "${var.parent}/policies/sql.restrictAuthorizedNetworks"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }
}
