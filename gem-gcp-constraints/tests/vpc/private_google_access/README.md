# Private Google Access Test

This Terraform configuration is designed to test the `enforce-private-google-access-constraint` custom policy.

## Resources Created

This configuration will create one VPC network and attempt to create two subnets within it:

1.  **`compliant_subnetwork`**: This is a **compliant** subnet.
    *   It is created with `private_ip_google_access = true`.
    *   Creation of this resource is expected to **succeed**.

2.  **`non_compliant_subnetwork`**: This is a **non-compliant** subnet.
    *   It is created with `private_ip_google_access = false`.
    *   Creation of this resource is expected to **fail** when the `enforce-private-google-access-constraint` is applied.

## How to Use

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
2.  **Apply the configuration:**
    ```bash
    terraform apply
    ```

When you run `terraform apply`, you can observe the behavior of the custom constraint. The `compliant_subnetwork` will be created successfully, while the creation of `non_compliant_subnetwork` will be blocked by the policy, resulting in an error.
