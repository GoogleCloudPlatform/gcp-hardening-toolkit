################################################################################
# SOC2 Confidentiality Controls (C1.1-C1.2)
# Protects confidential information through encryption and access controls
################################################################################

# C1.1: Enforce uniform bucket-level access for Cloud Storage
resource "google_org_policy_policy" "uniform_bucket_access" {
  count  = var.enabled ? 1 : 0
  name   = "${var.parent}/policies/storage.uniformBucketLevelAccess"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }
}

# C1.1: Prevent public access to Cloud Storage buckets
resource "google_org_policy_policy" "prevent_public_buckets" {
  count  = var.enabled ? 1 : 0
  name   = "${var.parent}/policies/storage.publicAccessPrevention"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }
}

# C1.1: Require CMEK (Customer-Managed Encryption Keys) for services
# This is a LIST constraint that specifies which services require CMEK
resource "google_org_policy_policy" "require_cmek" {
  count  = var.enabled ? 1 : 0
  name   = "${var.parent}/policies/gcp.restrictNonCmekServices"
  parent = var.parent

  spec {
    rules {
      # Deny these services from creating resources without CMEK
      values {
        denied_values = [
          "storage.googleapis.com",
          "bigquery.googleapis.com",
          "compute.googleapis.com",
          "sqladmin.googleapis.com"
        ]
      }
    }
  }
}

# C1.2: Restrict VPC peering to prevent data exfiltration
resource "google_org_policy_policy" "restrict_vpc_peering" {
  count  = var.enabled ? 1 : 0
  name   = "${var.parent}/policies/compute.restrictVpcPeering"
  parent = var.parent

  spec {
    rules {
      deny_all = true
    }
  }
}

