################################################################################
# SOC2 Security Controls (Common Criteria CC1-CC9)
# Implements IAM controls, access restrictions, and security monitoring
################################################################################

# CC6.1 & CC6.2: Block service account key creation
resource "google_org_policy_policy" "disable_sa_key_creation" {
  # Only create if the module is enabled and the policy doesn't already exist.
  count = var.enabled && lookup(var.existing_policies, "constraints/iam.disableServiceAccountKeyCreation", null) == null ? 1 : 0

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
  # Only create if the module is enabled and the policy doesn't already exist.
  count = var.enabled && lookup(var.existing_policies, "constraints/iam.automaticIamGrantsForDefaultServiceAccounts", null) == null ? 1 : 0

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
  # Only create if the module is enabled and the policy doesn't already exist.
  count = var.enabled && lookup(var.existing_policies, "constraints/iam.allowedPolicyMemberDomains", null) == null ? 1 : 0

  name   = "${var.parent}/policies/iam.allowedPolicyMemberDomains"
  parent = var.parent

  spec {
    dynamic "rules" {
      for_each = var.allowed_domains == null ? [1] : []
      content {
        allow_all = "TRUE"
      }
    }
    dynamic "rules" {
      for_each = var.allowed_domains != null ? [1] : []
      content {
        values {
          allowed_values = var.allowed_domains
        }
      }
    }
  }
}

# CC6.6: Restrict public IP access on Compute Engine instances
resource "google_org_policy_policy" "restrict_vm_external_ips" {
  # Only create if the module is enabled and the policy doesn't already exist.
  count = var.enabled && lookup(var.existing_policies, "constraints/compute.vmExternalIpAccess", null) == null ? 1 : 0

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
  # Only create if the module is enabled and the policy doesn't already exist.
  count = var.enabled && lookup(var.existing_policies, "constraints/compute.requireOsLogin", null) == null ? 1 : 0

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
  # Only create if the module is enabled and the policy doesn't already exist.
  count = var.enabled && lookup(var.existing_policies, "constraints/compute.requireShieldedVm", null) == null ? 1 : 0

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
  # Only create if the module is enabled and the policy doesn't already exist.
  count = var.enabled && lookup(var.existing_policies, "constraints/sql.restrictPublicIp", null) == null ? 1 : 0

  name   = "${var.parent}/policies/sql.restrictPublicIp"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }
}

# CC6.6: Restrict Cloud SQL authorized networks (network security)
resource "google_org_policy_policy" "restrict_sql_authorized_networks" {
  # Only create if the module is enabled and the policy doesn't already exist.
  count = var.enabled && lookup(var.existing_policies, "constraints/sql.restrictAuthorizedNetworks", null) == null ? 1 : 0

  name   = "${var.parent}/policies/sql.restrictAuthorizedNetworks"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }
}
