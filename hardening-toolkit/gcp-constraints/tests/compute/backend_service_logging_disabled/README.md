# Backend Service Logging Test

This Terraform configuration is designed to test the `enforce-backend-service-logging-constraint` custom policy.

## Resources Created

This configuration will attempt to create two backend services:

1.  **`compliant_service`**: This is a **compliant** backend service.
    *   It is created with logging enabled (`log_config { enable = true }`).
    *   Creation of this resource is expected to **succeed**.

2.  **`violating_service`**: This is a **non-compliant** backend service.
    *   It is created with logging disabled (`log_config { enable = false }`).
    *   Creation of this resource is expected to **fail** when the `enforce-backend-service-logging-constraint` is applied.

## How to Use

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
2.  **Apply the configuration:**
    You can test each resource individually using the `-target` flag.

    *   To test the compliant resource (should succeed):
        ```bash
        terraform apply -target=google_compute_backend_service.compliant_service
        ```
    *   To test the non-compliant resource (should fail):
        ```bash
        terraform apply -target=google_compute_backend_service.violating_service
        ```

When you run `terraform apply` on the `violating_service`, you can observe the behavior of the custom constraint. The creation of `violating_service` will be blocked by the policy, resulting in an error. The `compliant_service` will be created successfully.
