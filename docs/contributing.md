# How to Contribute

We would love to accept your patches and contributions to this project.

## Before you begin

### Sign our Contributor License Agreement

Contributions to this project must be accompanied by a
[Contributor License Agreement](https://cla.developers.google.com/about) (CLA).
You (or your employer) retain the copyright to your contribution; this simply
gives us permission to use and redistribute your contributions as part of the
project.

If you or your current employer have already signed the Google CLA (even if it
was for a different project), you probably don't need to do it again.

Visit <https://cla.developers.google.com/> to see your current agreements or to
sign a new one.

### Review our Community Guidelines

This project follows [Google's Open Source Community
Guidelines](https://opensource.google/conduct/).

## Contribution process

### Code Reviews

All submissions, including submissions by project members, require review. We
use [GitHub pull requests](https://docs.github.com/articles/about-pull-requests)
for this purpose.

#### 2. Architecture & Naming Conventions
The repository follows a **Library + Blueprints** architecture.

- **Blueprints (`blueprints/`):** Comprehensive solutions (Pillar-based).
    - **Format:** `gcp-<pillar>-<name>` (e.g., `gcp-foundation-org-iam`)
- **Modules (`modules/`):** Reusable capabilities (Category-based).
    - **Format:** `gcp-<category>-<name>` (e.g., `gcp-iam-groups`)

#### 3. Strict Naming Policy
We enforce a **Singular Purpose, Singular Naming** policy.

1.  **Modules (Category-based)**
    - **Format:** `gcp-<category>-<name>`
    - **Example:** `modules/gcp-custom-constraints/dns-dnssec` (Constraint category - grouped in subfolder)
    - **Example:** `modules/gcp-org-policies-core` (Org Policies category)
    - **Note:** Do NOT use the pillar prefix (e.g., `foundation`) in module names unless it describes the category itself.

2.  **Blueprints (Pillar-based)**
    - **Format:** `gcp-<pillar>-<name>`
    - **Example:** `blueprints/gcp-compliance-hipaa`

#### 4. Contribution Workflow

Before coding, search the repository to ensure your proposed module does not already exist.

- **New Modules:** If the functionality is missing, create a new module following the naming conventions above.
- **Existing Modules:** If a module exists but lacks a specific feature, submit a Pull Request (PR) to improve it or open an Issue to discuss the enhancement. **Do not create duplicate modules.**

#### 5. Definition of Done

A contribution is not complete without:

- **Isolation:** The module must function as a standalone unit.
- **Documentation:** A `README.md` explaining the module's input, output, and purpose.
- **Verification:** Evidence that the module performs the intended hardening task (e.g., test results).

#### 6. Policy Compatibility & State Management

To ensure that multiple compliance frameworks (e.g., HIPAA and SOC2) can coexist without conflict, all modules must adhere to the **Incremental Compliance** principle.

* **Additive Logic:** Modules must be designed to be additive. If a policy or constraint is already active (e.g., enabled by a different module), the Terraform logic should verify the existing state rather than attempting a blind overwrite or failing.
* **Idempotency & Import:** Implement logic to detect if a required change already exists. If the Organization Policy is already set to the required value, the module should respect the existing state.
* **Non-Destructive Rollbacks:** A `terraform destroy` on one compliance module must **not** break the compliance posture of other active modules.
    * *Scenario:* If a user runs both HIPAA and SOC2 modules, destroying the HIPAA module should not disable shared security controls required by SOC2.
    * *Remediation:* Users should be able to restore compliance by re-applying the remaining module (e.g., `terraform apply` on SOC2 after destroying HIPAA), but ideally, shared resources should be managed to minimize this friction.

#### 7. Support & Expectations

This toolkit is a **best-effort open-source project**. While our internal team reviews Issues and PRs to ensure quality, we cannot guarantee specific turnaround times for features or support requests.

## Development Setup

To ensure consistent code quality and security checks, we use `pre-commit` hooks. Please follow these steps to set up your local development environment.

### 1. Create a Python Virtual Environment
It is recommended to use a virtual environment to manage dependencies and avoid conflicts.

```bash
# Create the virtual environment
python3 -m venv .tmp_venv

# Activate the virtual environment
source .tmp_venv/bin/activate
```

### 2. Install Dependencies
Install the required tools `pre-commit` and `detect-secrets`.

```bash
pip install pre-commit detect-secrets
```

### 3. Install Pre-commit Hooks
Install the git hooks so they run automatically on every commit.

```bash
pre-commit install
```

## Running Checks

You can manually run the pre-commit checks on all files in the repository at any time:

```bash
pre-commit run --all-files
```

If you encounter any "secrets" violations that are false positives (e.g., example values in configuration files), please do not bypass the check. Instead, ensure the baseline matches the expected state or discuss it in the Pull Request.
