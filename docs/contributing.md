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

### Module Architecture & Naming Conventions

To maintain the integrity of the Hardening Toolkit, all contributions must adhere to our strict architectural standards. Each module is designed to be **standalone**, **purpose-driven**, and **consistent**.

#### 1. The Five Pillars

Your contribution must fall into one of the following five core categories:

- **`gcp-foundation`**: Baseline infrastructure setup and security defaults.
- **`gcp-compliance`**: Resources specifically configured to meet regulatory standards (e.g., NIST, PCI, CIS).
- **`gcp-constraint`**: Policy definitions and constraints to prevent violations.
- **`gcp-detection`**: Custom threat detection pipelines and observability configurations.
- **`gcp-triage`**: Automations for alert analysis, enrichment, and remediation workflows.

#### 2. Strict Naming Convention

We enforce a **Singular Purpose, Singular Naming** policy. A module must solve exactly one problem.

- **Format:** `prefix-category-singular_name`
- **Example:** A module establishing a foundation is `gcp-foundation-networking`, _not_ `gcp-foundations-networking`.
- **Example:** A constraint module is `gcp-constraint-location`, _not_ `gcp-constraints-location`.
#### 3. Logical Grouping (Sub-modules)

For complex domains, use hierarchical prefixes to group related modules without breaking the singular purpose rule.

- **Format:** `prefix-category-group-product`
- **Example:**
    - `gcp-foundation-ai-vertex` (AI Foundation for Vertex)
    - `gcp-foundation-ai-ccai` (AI Foundation for Contact Center AI)

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
