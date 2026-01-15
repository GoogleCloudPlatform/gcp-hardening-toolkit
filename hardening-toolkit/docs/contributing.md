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

#### 1. The Three Pillars

Your contribution must fall into one of the following three core categories:

- **`gcp-foundation`**: Baseline infrastructure setup and security defaults.
- **`gcp-compliance`**: Resources specifically configured to meet regulatory standards (e.g., NIST, PCI, CIS).
- **`gcp-constraint`**: Policy definitions and constraints to prevent violations.

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

#### 6. Support & Expectations

This toolkit is a **best-effort open-source project**. While our internal team reviews Issues and PRs to ensure quality, we cannot guarantee specific turnaround times for features or support requests.
