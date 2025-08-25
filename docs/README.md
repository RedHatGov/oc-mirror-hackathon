# oc-mirror Documentation

**Complete documentation for OpenShift disconnected installations using oc-mirror.**

## 🎯 Hackathon Participants: Start Here!

### **➡️ [hackathon-quickstart.md](hackathon-quickstart.md)**

**Your complete hackathon guide!** Includes decision matrix, AWS infrastructure setup, oc-mirror flow patterns, and success validation.

## 🚀 Alternative Quick Start Paths

**Experienced users or specific use cases:**

1. **[setup/aws-lab-infrastructure.md](setup/aws-lab-infrastructure.md)** - Two-host AWS infrastructure setup
2. **[flows/](flows/)** - Choose your oc-mirror --v2 flow pattern  
3. **[setup/oc-mirror-workflow.md](setup/oc-mirror-workflow.md)** - Complete traditional workflow
4. **[guides/](guides/)** - Specific operational guides

## 📁 Documentation Structure

### **🚀 [hackathon-quickstart.md](hackathon-quickstart.md)**
**Start here for hackathon!** Decision-guided complete learning path

### **🏗️ [setup/](setup/)**
Infrastructure and environment setup:
- **[aws-lab-infrastructure.md](setup/aws-lab-infrastructure.md)** - Two-host AWS infrastructure
- **[oc-mirror-workflow.md](setup/oc-mirror-workflow.md)** - Complete oc-mirror workflow

### **🔄 [flows/](flows/)**
**oc-mirror --v2 flow patterns** (hackathon core content):
- **[mirror-to-disk.md](flows/mirror-to-disk.md)** - Create portable archives  
- **[from-disk-to-registry.md](flows/from-disk-to-registry.md)** - Deploy to disconnected registries
- **[mirror-to-registry.md](flows/mirror-to-registry.md)** - Direct mirroring
- **[delete.md](flows/delete.md)** - Safe content cleanup

### **📖 [guides/](guides/)**  
Step-by-step operational guides:
- **[collect-ocp.md](guides/collect-ocp.md)** - Tool collection and setup
- **[openshift-create-cluster.md](guides/openshift-create-cluster.md)** - Cluster creation
- **[cluster-upgrade.md](guides/cluster-upgrade.md)** - Disconnected upgrades

### **📚 [reference/](reference/)**
Technical references and advanced patterns:
- **[workflows/](reference/workflows/)** - Enterprise operational patterns  
- **[oc-mirror-v2-commands.md](reference/oc-mirror-v2-commands.md)** - Complete command reference
- **[cache-management.md](reference/cache-management.md)** - Storage optimization
- **[image-deletion.md](reference/image-deletion.md)** - Comprehensive deletion reference

## 🎯 Choose Your Path

| I want to... | Go to... |
|---------------|----------|
| **🚀 Complete the hackathon** | **[hackathon-quickstart.md](hackathon-quickstart.md)** |
| Set up AWS infrastructure | **[setup/aws-lab-infrastructure.md](setup/aws-lab-infrastructure.md)** |
| Follow specific oc-mirror flows | **[flows/](flows/)** |
| Learn operational tasks | **[guides/](guides/)** |
| Optimize for production | **[reference/workflows/](reference/workflows/)** |
| Look up command syntax | **[reference/](reference/)** |

## 🛠️ Tools

- **`../collect_ocp`** - Simplified tool collection script (in repository root)
- **oc-mirror** - Content mirroring for disconnected installations
- **Mirror registry** - Local Quay container registry
- **OpenShift installer** - Cluster deployment tools

---

*Perfect for workshops, training, and enterprise disconnected OpenShift deployments.*
