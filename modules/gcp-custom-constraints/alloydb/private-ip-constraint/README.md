# Enforce Private IP for AlloyDB Instances

This module creates a custom organization policy constraint that ensures all AlloyDB instances use private IP addresses only and do not enable public IP access.

## Security Rationale

**Why this constraint matters:**
- **Network Isolation**: Prevents AlloyDB instances from being exposed to the public internet, reducing attack surface.
- **Compliance**: Meets security requirements that mandate database instances remain within private networks.
- **Defense in Depth**: Ensures database traffic stays within your VPC, protected by firewall rules and private networking.

## How It Works

The constraint uses `DENY` logic to block AlloyDB instances where public IP is explicitly enabled.

**Technical Details:**
- **Resource Type**: `alloydb.googleapis.com/Instance`
- **Action Type**: `DENY`
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: `resource.networkConfig.enablePublicIp == true`

## Usage

This constraint is enabled via the `enable_alloydb_private_ip_constraint` variable in the blueprint.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint |
| `org_policy_name` | The name of the organization policy |
