# VPC Custom Mode Test

This Terraform configuration is designed to test the `enforce-custom-mode-vpc-constraint` custom policy.

## Resources Created

This configuration will attempt to create two VPC networks:

1.  **`custom_mode_vpc`**: This is a **compliant** VPC network.
    *   It is created with `auto_create_subnetworks = false`, which means it's a "custom mode" VPC.
    *   Creation of this resource is expected to **succeed**.
    *   A subnetwork named `custom_subnet` is also created within this VPC.

2.  **`auto_mode_vpc`**: This is a **non-compliant** VPC network.
    *   It is created with `auto_create_subnetworks = true`, which means it's an "auto mode" VPC.
    *   Creation of this resource is expected to **fail** when the `enforce-custom-mode-vpc-constraint` is applied.

## How to Use

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
2.  **Apply the configuration:**
    ```bash
    terraform apply
    ```

When you run `terraform apply`, you can observe the behavior of the custom constraint. The `custom_mode_vpc` will be created successfully, while the creation of `auto_mode_vpc` will be blocked by the policy, resulting in an error.
