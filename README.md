# GCP Hardening Toolkit
This repository contains a collection of curated Terraform modules designed to enhance the security posture of your Google Cloud Platform (GCP) environment. Each module is a reusable, documented, and tested component that applies a specific security best practice.

## Vs Cloud Foundations Toolkit
Unlike the **Cloud Foundations Toolkit (CFT)**, which focuses on broad, standard deployment patterns, this toolkit is laser-focused on **deep security hardening** of specific GCP components. We maintain this separation to **avoid bloat** in the CFT and provide a **specialized, agile toolkit** suited for **task-force-like engagements** where rapid, deep security and compliance deployment is required.

## Features

### Foundations
**Prefix:** `gcp-foundation`

Serves as the toolkit’s cornerstone by rapidly deploying essential security baselines. Note that while these modules can deploy infrastructure, this is primarily to facilitate **security research and testing**—allowing users to quickly spin up an environment to validate hardening features. Deployment of underlying infrastructure is optional and intended for these specific use cases. It automatically provisions core controls, including IAM engineering standards, Organization Policies, Security Command Center (SCC) enablement, and log sinks.

### Compliance
**Prefix:** `gcp-compliance`

Delivers ultra-fast, frictionless compliance. By deploying comprehensive security measures in a single run, this feature removes barriers to adoption and ensures rapid adherence to strict regulatory requirements.

### Constraints
**Prefix:** `gcp-constraint`

Secures the environment against lateral movement by enforcing advanced hardening constraints. It restricts critical operations, such as blocking the creation of new service accounts and freezing changes to Workforce Identity Pools.

### Detection
**Prefix:** `gcp-detection`

Extends native observability by deploying custom threat detection pipelines. This pillar focuses on extracting signal from noise using advanced log routing and custom logic to spot anomalies instantly.

### Triage
**Prefix:** `gcp-triage`

Automates the investigation and decision-making process for security alerts. This pillar helps analysts cut through alert fatigue by enriching findings with context and providing structured frameworks for efficient remediation.

## Usage

This toolkit is built on a **modular architecture**, ensuring that components are **self-contained** and have minimal dependencies on each other.

### How it Works
Each subdirectory in this repository is a standalone module with its own **self-contained documentation**.
*   **Navigate to the module**: Go to the specific subdirectory for the hardening task you need.
*   **Read the Internal README**: Each module has a dedicated `README.md` explaining exactly what it does, how it works, and how to use it.
*   **Multi-Language Hardening**: While **Terraform** is used as the baseline for deploying infrastructure, deep security hardening often requires more than just Infrastructure-as-Code. Many modules leverage **Bash scripts**, **Python**, or **Go** to perform complex hardening tasks, logical checks, or API interactions that Terraform cannot handle alone.

This design supports **task-force-like engagements**, allowing security teams to rapidly deploy specific, targeted measures without needing to adopt a monolithic framework.

## Contributing

Contributions are welcome! Please refer to our [Contributing Guide](docs/contributing.md) for details. If you have a module idea, find a bug, or want to suggest an improvement, please open an issue or submit a pull request.

## Feedback
Do you use the Hardening Toolkit? We need your help!

We want to understand your user experience and improve the tool's usability.
It takes **less than 60 seconds**.

[**👉 Take the 1-Minute Survey**](https://forms.gle/LmgxXbJBoqu91dyA9)
