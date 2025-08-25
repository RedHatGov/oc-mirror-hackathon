# Setup Guides

Essential infrastructure and environment setup for oc-mirror hackathon.

## 🎯 Hackathon Participants: Start Here!

**Complete hackathon guide:** [../hackathon-quickstart.md](../hackathon-quickstart.md)

## Setup Guide Overview

### **Two-Host Architecture (Recommended for Hackathon)**

1. **[aws-lab-infrastructure.md](aws-lab-infrastructure.md)** - Two-host AWS infrastructure setup
2. Choose your oc-mirror flow from **[../flows/](../flows/)** based on your learning path

### **Traditional Single-Host Approach**

1. **[aws-lab-infrastructure.md](aws-lab-infrastructure.md)** - Single-host infrastructure  
2. **[oc-mirror-workflow.md](oc-mirror-workflow.md)** - Complete workflow on one host

## Files in this Directory

| File | Description | Architecture | Use Case |
|------|-------------|--------------|----------|
| **[aws-lab-infrastructure.md](aws-lab-infrastructure.md)** | AWS infrastructure with bastion + registry hosts | **Two-host** | Air-gapped simulation |
| **[oc-mirror-workflow.md](oc-mirror-workflow.md)** | Traditional complete oc-mirror workflow | Single-host | Comprehensive learning |

## Infrastructure Overview

Our **two-host architecture** enables true air-gapped learning:

- **🖥️ Bastion Host** (`bastion.sandboxXXX.opentlc.com`) - Connected operations  
- **🖥️ Registry Host** (`registry.sandboxXXX.opentlc.com`) - Disconnected operations
- **🔗 DNS Configuration** - Proper host separation and identification
- **🌉 Air-Gap Simulation** - Real enterprise deployment patterns

## What's Next?

After completing infrastructure setup:

- **[../flows/](../flows/)** - **oc-mirror --v2 flow patterns** (hackathon core content)
- **[../guides/](../guides/)** - Step-by-step operational guides  
- **[../reference/workflows/](../reference/workflows/)** - Enterprise operational patterns
