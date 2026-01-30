# GCP Hardening Toolkit

![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.3-935ADA)
![Python](https://img.shields.io/badge/Python-3.x-3776AB)
![Bash](https://img.shields.io/badge/Bash-Shell-4EAA25)
![Release](https://img.shields.io/badge/Release-Rolling-red)
![License](https://img.shields.io/badge/License-Apache%202.0-blue)

This repository contains a collection of curated Terraform modules designed to enhance the security posture of your Google Cloud Platform (GCP) environment. Each module is a reusable, documented, and tested component that applies a specific security best practice.

## Repository Structure

The repository follows a **Library + Blueprints** architecture, decoupled to allow flexible composition.

```text
gcp-hardening-toolkit/
├── blueprints/                 # 🚀 deployable solutions (stateful)
│   ├── gcp-foundation-org-iam/
│   └── ...
├── modules/                    # 🧩 reusable components (stateless)
│   ├── gcp-iam-groups/
│   └── gcp-custom-constraints/ # 🛡️ org policy constraints
└── docs/                       # 📚 detailed documentation
```

### Design Principles

- **Separation of Concerns**
    - **Modules**: Encapsulate logic and resources (implementation).
    - **Blueprints**: Handle orchestration and state (composition).
- **Adaptability**
    - **Reference Architectures**: Blueprints are production-ready but malleable.
    - **Customization**: Users are encouraged to modify Blueprints to fit their specific requirements.
- **Directness**
    - **Minimal Wrappers**: Modules are usually thin layers over Terraform resources.
    - **Value Add**: Abstraction is only added when it provides clear value (e.g., enforcing policy constraints).

## Features (Pillars)

The toolkit is organized into five core pillars:

1.  **Foundations** (`gcp-foundation`):
    Rapidly provisions core controls (IAM engineering standards, Org Policies, SCC enablement) to facilitate security research and testing.

2.  **Compliance** (`gcp-compliance`):
    Delivers ultra-fast, frictionless compliance by deploying comprehensive security measures in a single run (e.g., HIPAA).

3.  **Constraints** (`gcp-constraint`):
    Secures the environment against lateral movement by enforcing advanced hardening constraints (e.g., blocking service account creation).

4.  **Detection** (`gcp-detection`):
    Extends native observability with custom threat detection pipelines and advanced log routing to spot anomalies instantly.

5.  **Triage** (`gcp-triage`):
    Automates investigation and decision-making for security alerts, reducing alert fatigue.

## Vs Cloud Foundations Toolkit

Unlike the **Cloud Foundations Toolkit (CFT)**, which focuses on broad, standard deployment patterns, this toolkit is laser-focused on **deep security hardening**. We maintain this separation to **avoid bloat** in the CFT and provide a **specialized, agile toolkit** suited for **task-force-like engagements**.

## Usage

### Workflow

1.  **Select a Blueprint**: Choose a solution from `blueprints/` that matches your goal.
2.  **Customize**: Blueprints come with their own `examples` or default `variables`.
3.  **Deploy**: Authenticate and run Terraform within the blueprint directory.

```bash
cd blueprints/gcp-foundation-org-iam
terraform init
terraform apply
```

### Helper Scripts

- **Bash Scripts**: For one-time setup tasks (e.g., enabling SCC services, checking VPC-SC violations).
- **Python Scripts**: Used within Cloud Functions for advanced logic (e.g., automated project creation enforcement).

## Release Cycle & Versioning

We use a **Rolling Release** model (no semantic versioning). Every commit to `main` is stable.

### 📌 Hash Pinning

We recommend pinning modules to a specific commit hash to ensure stability.

```hcl
module "gcp_hardening" {
  source = "https://github.com/GoogleCloudPlatform/gcp-hardening-toolkit/tree/main/modules/gcp-org-policies?ref=ab1e62f5"
  # ...
}
```

## Contributing

Contributions are welcome! Please refer to our [Contributing Guide](docs/contributing.md) for details.

## Feedback

Your feedback helps us prioritize features and improve the toolkit. Please share your experience via our brief survey.

[Take the 1-Minute Survey](https://forms.gle/LmgxXbJBoqu91dyA9)
