# Enforce Backend Service Logging

This module creates a custom organization policy to enforce that all new and updated Backend Services have logging enabled.

## Usage

```hcl
module "enforce_backend_service_logging" {
  source = "./modules/compute/enforce-backend-service-logging-constraint"

  parent = "organizations/123456789012"
}
```
