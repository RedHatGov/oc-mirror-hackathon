# 🚀 oc-mirror Hackathon Repository

**OpenShift 4.20 oc-mirror v2 Disconnected Mirroring Workshop**

Welcome to the oc-mirror hackathon! This repository provides everything you need to master **oc-mirror v2** content mirroring for disconnected OpenShift 4.20 environments.

## 🎯 Hackathon Overview

This hackathon focuses on hands-on experience with **oc-mirror v2** using **OpenShift 4.20.0-ec.5** to learn disconnected mirroring workflows, air-gapped deployments, and enterprise-grade content management patterns.

### **🚀 Start Your Hackathon Journey**

### **➡️ [docs/hackathon-quickstart.md](docs/hackathon-quickstart.md)**

**Your complete guide from zero to oc-mirror expert!** This guide provides:

- 🎲 **Decision Matrix** - Choose the right path for your environment
- 🏗️ **AWS Infrastructure Setup** - Two-host architecture for air-gapped learning  
- 🔄 **oc-mirror Flow Patterns** - All 4 flows with tested procedures
- ✅ **Success Validation** - Know when you've mastered the content

## 📋 Hackathon Resources & Context

### **oc-mirror Development & Planning**
- **[oc-mirror Delivery Plan by Release](https://issues.redhat.com/secure/Dashboard.jspa?selectPageId=12365011)** - Release planning and roadmap
- **[Documentation JIRA Dashboard](https://issues.redhat.com/secure/Dashboard.jspa?selectPageId=12347526)** - Documentation tracking and issues

### **oc-mirror Version & Tools**  
- **[OpenShift 4.20.0-ec.5 Tools](https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/4.20.0-ec.5/)** - oc-mirror v2, oc client, installer binaries
- **[ICS Viewer - Operator Catalog Terminal UI](https://github.com/lmzuccarelli/rust-operator-catalog-viewer)** - Tool for viewing operator metadata in catalogs

### **Hackathon Documentation** 
- **[Hackathon Planning Document](https://docs.google.com/document/d/16ADTm829atCwwmeN6tjKKYc97UNkfzfAxotgqerkN9A/edit?tab=t.0#heading=h.66y4kqbj468a)** *(Note: Private access required)*

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
- **[mirror-to-mirror.md](docs/flows/mirror-to-mirror.md)** - Direct mirroring for semi-connected environments  
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