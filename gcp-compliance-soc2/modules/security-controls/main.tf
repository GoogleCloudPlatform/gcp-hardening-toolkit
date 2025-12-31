################################################################################
# SOC2 Security Controls (Common Criteria CC1-CC9)
# Implements IAM controls, access restrictions, and security monitoring
################################################################################

# CC6.1 & CC6.2: Block service account key creation
resource "google_org_policy_policy" "disable_sa_key_creation" {
  count  = var.enabled ? 1 : 0
  name   = "${var.parent}/policies/iam.disableServiceAccountKeyCreation"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }
}

# CC6.1: Disable automatic IAM grants for default service accounts
resource "google_org_policy_policy" "disable_default_sa_grants" {
  count  = var.enabled ? 1 : 0
  name   = "${var.parent}/policies/iam.automaticIamGrantsForDefaultServiceAccounts"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }
}

# CC6.1: Restrict which domains can be added to IAM policies
resource "google_org_policy_policy" "allowed_policy_member_domains" {
  count  = var.enabled ? 1 : 0
  name   = "${var.parent}/policies/iam.allowedPolicyMemberDomains"
  parent = var.parent

  spec {
    rules {
      allow_all = var.allowed_domains == null ? "TRUE" : "FALSE"
      
      dynamic "values" {
        for_each = var.allowed_domains != null ? [1] : []
        content {
          allowed_values = var.allowed_domains
        }
      }
    }
  }
}

# CC6.6: Restrict public IP access on Compute Engine instances
resource "google_org_policy_policy" "restrict_vm_external_ips" {
  count  = var.enabled ? 1 : 0
  name   = "${var.parent}/policies/compute.vmExternalIpAccess"
  parent = var.parent

  spec {
    rules {
      deny_all = true
      
      # Allow exemptions for specific projects
      dynamic "condition" {
        for_each = length(var.exempted_projects) > 0 ? [1] : []
        content {
          expression = join(" || ", [
            for project in var.exempted_projects :
            "resource.matchTag('projects/${project}', 'exempted')"
          ])
        }
      }
    }
  }
}

# CC7.2: Require OS Login for SSH access
resource "google_org_policy_policy" "require_os_login" {
  count  = var.enabled ? 1 : 0
  name   = "${var.parent}/policies/compute.requireOsLogin"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }
}

# CC7.2: Require Shielded VMs
resource "google_org_policy_policy" "require_shielded_vm" {
  count  = var.enabled ? 1 : 0
  name   = "${var.parent}/policies/compute.requireShieldedVm"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }
}

# CC6.6: Restrict Cloud SQL public IPs
resource "google_org_policy_policy" "restrict_sql_public_ip" {
  count  = var.enabled ? 1 : 0
  name   = "${var.parent}/policies/sql.restrictPublicIp"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }
}
