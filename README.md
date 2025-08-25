# 🚀 oc-mirror Hackathon Repository

**Complete OpenShift Disconnected Mirroring Workshop**

Welcome to the oc-mirror hackathon! This repository provides everything you need to master OpenShift content mirroring for disconnected environments.

## 🎯 Start Here: Hackathon Quick Start

### **➡️ [docs/hackathon-quickstart.md](docs/hackathon-quickstart.md)**

**Your complete guide from zero to oc-mirror expert!** This guide provides:

- 🎲 **Decision Matrix** - Choose the right path for your environment
- 🏗️ **AWS Infrastructure Setup** - Two-host architecture for air-gapped learning  
- 🔄 **oc-mirror Flow Patterns** - All 4 flows with tested procedures
- ✅ **Success Validation** - Know when you've mastered the content

### **🤔 New to oc-mirror? Start with the hackathon guide above!**

## 📚 Documentation Structure

### **🚀 [hackathon-quickstart.md](docs/hackathon-quickstart.md)**
**Start here!** Complete hackathon guide with decision matrix and path selection

### **🏗️ [setup/](docs/setup/)**  
Infrastructure and environment setup:
- **[aws-lab-infrastructure.md](docs/setup/aws-lab-infrastructure.md)** - Two-host AWS infrastructure
- **[oc-mirror-workflow.md](docs/setup/oc-mirror-workflow.md)** - Complete oc-mirror workflow

### **🔄 [flows/](docs/flows/)**
**oc-mirror --v2 flow patterns** (hackathon core content):
- **[mirror-to-disk.md](docs/flows/mirror-to-disk.md)** - Create portable archives for air-gapped transfer
- **[from-disk-to-registry.md](docs/flows/from-disk-to-registry.md)** - Deploy archives to disconnected registries
- **[mirror-to-registry.md](docs/flows/mirror-to-registry.md)** - Direct mirroring for semi-connected environments  
- **[delete.md](docs/flows/delete.md)** - Safe content cleanup and version management

### **📖 [guides/](docs/guides/)**
Step-by-step operational guides:
- **[collect-ocp.md](docs/guides/collect-ocp.md)** - Tool collection and setup
- **[openshift-create-cluster.md](docs/guides/openshift-create-cluster.md)** - Disconnected cluster creation
- **[cluster-upgrade.md](docs/guides/cluster-upgrade.md)** - Disconnected cluster upgrades

### **📚 [reference/](docs/reference/)**
Technical references and advanced patterns:
- **[workflows/](docs/reference/workflows/)** - Enterprise operational patterns  
- **[oc-mirror-v2-commands.md](docs/reference/oc-mirror-v2-commands.md)** - Complete command reference
- **[cache-management.md](docs/reference/cache-management.md)** - Storage optimization
- **[image-deletion.md](docs/reference/image-deletion.md)** - Comprehensive deletion reference

### **🛠️ Tools**
- **`collect_ocp`** - Simplified tool collection script (in repository root)

## Tools Included

- **oc-mirror** - Content mirroring for disconnected installations
- **OpenShift installer** - Cluster deployment tools
- **Mirror registry** - Local Quay container registry
- **Supporting utilities** - oc, butane, and other required tools

---

*Perfect for workshops, training, and enterprise disconnected OpenShift deployments.*