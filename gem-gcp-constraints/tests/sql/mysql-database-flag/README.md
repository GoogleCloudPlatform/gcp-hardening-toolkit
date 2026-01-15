# MySQL Database Flags Test

This Terraform configuration is designed to test the `enforce-mysql-database-flags-constraint` custom policy.

## Resources Created

This configuration will attempt to create two MySQL database instances:

1.  **`compliant_mysql`**: This is a **compliant** MySQL instance.
    *   It is created with the required database flags:
        *   `skip_show_database` = `on`
        *   `local_infile` = `off`
    *   Creation of this resource is expected to **succeed**.

2.  **`violating_mysql`**: This is a **non-compliant** MySQL instance.
    *   It is created with a non-compliant database flag (`local_infile` = `on`).
    *   Creation of this resource is expected to **fail** when the `enforce-mysql-database-flags-constraint` is applied.

## How to Use

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
2.  **Apply the configuration:**
    ```bash
    terraform apply
    ```

When you run `terraform apply`, you can observe the behavior of the custom constraint. The `compliant_mysql` instance will be created successfully, while the creation of `violating_mysql` will be blocked by the policy, resulting in an error.
