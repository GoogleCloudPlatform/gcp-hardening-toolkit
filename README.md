# GCP Hardening Toolkit (GHT)

![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.3-935ADA)
![Python](https://img.shields.io/badge/Python-3.x-3776AB)
![Bash](https://img.shields.io/badge/Bash-Shell-4EAA25)
![License](https://img.shields.io/badge/License-Apache%202.0-blue)
![Release](https://img.shields.io/badge/Release-Rolling-4B5563)

The GCP Hardening Toolkit (GHT) is an automated triage and remediation engine designed to safely manage security debt in complex, active (brownfield) Google Cloud environments.

While standard foundational toolkits provide blueprints for building from scratch, GHT is engineered for the realities of existing infrastructure. It combines state-aware Infrastructure as Code (IaC) with active triage automation, empowering security task forces to rapidly audit environments, identify vulnerabilities, and deploy incremental compliance guardrails—without disrupting active DevOps pipelines.

## Repository Strucure

The repository follows a **Library + Blueprints** architecture, decoupled to allow flexible composition.

```text
gcp-hardening-toolkit/
├── agent/                      # agentic solution for automated hardening
│   └── state-exporter/
│       └── ...
├── blueprints/                 # deployable solutions (stateful)
│   ├── gcp-foundation-org-iam/
│   └── ...
├── modules/                    # reusable components (stateless)
│   ├── gcp-iam-groups/
│   └── gcp-custom-constraints/ # org policy constraints
└── docs/                       # detailed documentation
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

## GHT vs. Cloud Foundation Toolkit (CFT)

We get this question a lot, so let's make the difference between the GCP Hardening Toolkit (GHT) and the Cloud Foundation Toolkit (CFT) CRYSTAL CLEAR.

While GHT includes several foundational examples, these are meant to be thin and leverage CFT to deploy standard infrastructure. GHT is an open-source tool built with a completely different vision and utility in mind.

### The Core Difference: Brownfield vs. Greenfield

*   **CFT** is the gold standard for **greenfield** deployments. It provides excellent blueprints for building from scratch. While tools like CFT Scorecard can audit an existing environment to tell you what is broken, its primary utility is establishing a baseline.
*   **GHT** is engineered for **brownfield** environments. It is built for scenarios where infrastructure is already deployed, messy, and has a lot of room for security improvement. GHT doesn't just evaluate; it actively remediates.

### The Pain Point GHT Solves

When teams conduct a Cloud Security Posture Review (CSPR), they get a clear picture of their security posture. But knowing the problems you have doesn't mean you know how to solve them without breaking production.

Usually, security teams must manually review the environment, negotiate with stakeholders, and implement restrictive policies while trying not to disrupt DevOps. This causes tremendous operational friction.

### The GHT Advantage: Triage and State-Aware Remediation

GHT is the engine that handles the heavy lifting of security debt and accelerates your path to compliance.

*   **Targeted Guardrails vs. Broad Enforcement:** CFT provides modules to enforce Organization Policies broadly. GHT provides the triage tools to figure out *how* to apply those guardrails in a running environment incrementally.
*   **State-Aware IaC & Triage Automation:** Unlike standard foundations that assume a clean slate, GHT uses state-aware IaC combined with specialized triage scripts. This allows you to deploy security without destroying existing configurations.
*   **Automated Execution:** Deploying foundations in brownfield environments is traditionally a manual, tedious process. GHT automates this by taking the current state, existing infrastructure, **and standard CFT modules** as its grounding input to bridge the gap to a hardened state.

For greenfield, GHT's use is mostly limited to creating compliance guardrails—a crucial 2nd layer of security. But for brownfield, GHT's automated triage and non-disruptive remediation are the features that define its utility.

---

### Summary Comparison

| Feature | Cloud Foundation Toolkit (CFT) | GCP Hardening Toolkit (GHT) |
| :--- | :--- | :--- |
| **Primary Use Case** | **Greenfield:** Building new infrastructure from scratch. | **Brownfield:** Triaging and hardening existing environments. |
| **Core Assets** | Static Terraform Blueprints & Modules. | State-Aware IaC, Triage Scripts & Deployable Guardrails. |
| **Environment State** | Assumes a "clean slate" standard state. | Grounded in the **current state** (respects existing tech debt). |
| **Guardrail Strategy** | Broad, top-down baseline enforcement. | Targeted, triage-based incremental enforcement. |
| **Compliance Focus** | Policy Monitoring & Auditing (e.g., Scorecard). | Active Remediation & Debt Reduction. |
| **DevOps Friction** | High, if forced onto existing messy infrastructure. | Low, designed to fix issues without disrupting active ops. |

---

### When to check out CFT
You should check out the [Cloud Foundation Toolkit](https://github.com/GoogleCloudPlatform/cloud-foundation-toolkit) if:
* You are starting a brand new Google Cloud organization.
* You need general-purpose, foundational blueprints (VPCs, Projects, Folders).
* You want to audit your current state against baseline policies.

### When to use GHT
Use this open-source toolkit if:
* You are conducting a CSPR and need to actively fix an existing environment.
* You need to accelerate the path to compliance across any framework by managing security debt.
* You want to search for low-hanging security fruits and implement incremental guardrails without breaking current operations.

## Hardening Agent

The GCP Hardening Agent is a specialized security assistant designed to triage Google Cloud environments and generate hardening blueprints. It functions as an interactive CLI agent that automates the audit of existing infrastructure to identify vulnerabilities and deploy incremental compliance guardrails—all while grounding its decisions in the environment's live state.

For more information on the agent's architecture, setup, and core capabilities, see the [Hardening Agent README](agent/README.md).

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

### Hash Pinning (Supply Chain Security)

We strongly recommend pinning modules to a specific commit hash for production environments. This prevents unintended updates and protects against potential supply chain compromises.

```hcl
module "gcp_hardening" {
  source = "github.com/GoogleCloudPlatform/gcp-hardening-toolkit//modules/gcp-org-policies?ref=<COMMIT_HASH>"
}
```

## Contributing

Contributions are welcome! Please refer to our [Contributing Guide](docs/contributing.md) for details.

## Feedback

Your feedback helps us prioritize features and improve the toolkit. Please share your experience via our brief survey.

[Take the 1-Minute Survey](https://forms.gle/LmgxXbJBoqu91dyA9)
