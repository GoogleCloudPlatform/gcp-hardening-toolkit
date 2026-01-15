# DNSSEC Enabled Test

This Terraform configuration is designed to test the `dnssec-enabled-constraint` custom policy.

## Resources Created

This configuration will attempt to create two DNS managed zones:

1.  **`compliant_zone`**: This is a **compliant** DNS zone.
    *   It is created with DNSSEC enabled (`dnssec_config { state = "on" }`).
    *   Creation of this resource is expected to **succeed**.

2.  **`violating_zone`**: This is a **non-compliant** DNS zone.
    *   It is created with DNSSEC disabled (`dnssec_config { state = "off" }`).
    *   Creation of this resource is expected to **fail** when the `dnssec-enabled-constraint` is applied.

## How to Use

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
2.  **Apply the configuration:**
    ```bash
    terraform apply
    ```

When you run `terraform apply`, you can observe the behavior of the custom constraint. The `compliant_zone` will be created successfully, while the creation of `violating_zone` will be blocked by the policy, resulting in an error.
