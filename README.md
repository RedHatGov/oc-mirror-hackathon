# oc-mirror Hackathon Repository

This repository contains comprehensive guides and tools for working with OpenShift disconnected installations using oc-mirror.

## Getting Started

### 📋 For Infrastructure Setup
If you need to set up lab infrastructure (bastion host, networking, etc.), start with:
**[docs/setup/aws-lab-infrastructure.md](docs/setup/aws-lab-infrastructure.md)** - AWS-specific infrastructure setup

### 🚀 For oc-mirror Workflow
For the main oc-mirror workflow (platform-agnostic), use:
**[docs/setup/oc-mirror-workflow.md](docs/setup/oc-mirror-workflow.md)** - Universal oc-mirror setup and operations

## Documentation Structure

### **📁 [setup/](docs/setup/)**
Essential setup guides to get started:
- **[aws-lab-infrastructure.md](docs/setup/aws-lab-infrastructure.md)** - Cloud infrastructure setup (AWS focus)
- **[oc-mirror-workflow.md](docs/setup/oc-mirror-workflow.md)** - Main oc-mirror workflow guide

### **📖 [guides/](docs/guides/)**
How-to guides for specific tasks:
- **[operator-mirroring.md](docs/guides/operator-mirroring.md)** - Operator mirroring specifics
- **[image-deletion.md](docs/guides/image-deletion.md)** - Image cleanup procedures
- **[airgap-testing.md](docs/guides/airgap-testing.md)** - Air-gap validation

### **⚙️ [workflows/](docs/workflows/)**
Advanced patterns and operational procedures:
- **[sequential-mirroring.md](docs/workflows/sequential-mirroring.md)** - Step-by-step workflows
- **[operational-patterns.md](docs/workflows/operational-patterns.md)** - Best practices
- **[infrastructure-patterns.md](docs/workflows/infrastructure-patterns.md)** - Advanced infrastructure

### **📚 [reference/](docs/reference/)**
Reference materials and command documentation:
- **[oc-mirror-v2-commands.md](docs/reference/oc-mirror-v2-commands.md)** - Complete oc-mirror v2 reference
- **[improvements-summary.md](docs/reference/improvements-summary.md)** - Project improvements

### **🛠️ Tools**
- **`collect_ocp`** - Automated tool collection script (in repository root)

## Tools Included

- **oc-mirror** - Content mirroring for disconnected installations
- **OpenShift installer** - Cluster deployment tools
- **Mirror registry** - Local Quay container registry
- **Supporting utilities** - oc, butane, and other required tools

---

*Perfect for workshops, training, and enterprise disconnected OpenShift deployments.*