# OpenShift oc-mirror v2 Hackathon Guide

## 🎯 **Quick Decision Guide - Which Flow Do I Need?**

This hackathon repo provides **enterprise-ready oc-mirror v2 workflows** with production scripts, comprehensive documentation, and real-world testing patterns.

### **Choose Your Path:**

| **Your Scenario** | **Recommended Flow** | **Time to Complete** |
|------------------|---------------------|---------------------|
| **🔒 Fully Airgapped Environment** | [Mirror-to-Disk](flows/10-mirror-to-disk.md) → [From-Disk-to-Registry](flows/11-from-disk-to-registry.md) | 45-90 min |
| **🌐 Semi-Connected (Direct)** | [Mirror-to-Registry](flows/12-mirror-to-registry.md) | 30-60 min |
| **🗑️ Cleanup Old Versions** | [Delete Workflow](flows/13-delete.md) | 15-30 min |
| **⬆️ Cluster Upgrade** | [Cluster Upgrade Guide](flows/20-cluster-upgrade.md) | 60-120 min |

### **🏗️ Two-Host Architecture**

All flows designed for **enterprise deployment patterns:**

- **🖥️ Mirror Node**: Builds and manages mirror content (connected/semi-connected)
- **🏭 Registry Node**: Serves images to disconnected OpenShift clusters
- **📦 Portable Delivery**: Secure transport between environments

## 🚀 **Quick Start (5 Minutes)**

### **New to oc-mirror?**
1. **📋 Prerequisites**: Complete [02-shared-prereqs.md](02-shared-prereqs.md) *(one-time setup)*
2. **🎯 Choose Flow**: Select from table above
3. **✅ Ready Check**: Use [checklists/prereqs-ready.md](checklists/prereqs-ready.md)
4. **🔥 Execute**: Follow your chosen flow guide

### **Returning User?**
- **🔍 Quick Reference**: [04-conventions.md](04-conventions.md) - canonical variables
- **🛠️ Troubleshooting**: [references/troubleshooting.md](references/troubleshooting.md)
- **📊 Validation**: [checklists/post-done.md](checklists/post-done.md)

## 📚 **What's Different About This Hackathon Repo?**

### **🎯 Production-Ready Features:**
- ✅ **Standardized Scripts** - No manual command execution
- ✅ **Interactive Safety Checks** - Built-in confirmation gates  
- ✅ **Real-World Testing** - Validated in RHEL 9 environments
- ✅ **Enterprise Patterns** - Two-host deployment models
- ✅ **Complete Workflows** - Download → Upload → Upgrade → Delete

### **🛠️ Hackathon Optimized:**
- ✅ **Fast Setup** - Modular prereqs, no duplication
- ✅ **Clear Decision Trees** - Know exactly which flow to use
- ✅ **Ready/Go/Done Checklists** - Operational confidence
- ✅ **Troubleshooting Focus** - Common issues → quick fixes

## 📖 **Documentation Navigation**

### **📍 Start Here (Required Reading):**
- **[01-concepts.md](01-concepts.md)** - oc-mirror v2 fundamentals *(10 min)*
- **[02-shared-prereqs.md](02-shared-prereqs.md)** - Environment setup *(30-60 min)*
- **[03-env-profiles.md](03-env-profiles.md)** - Choose your environment type *(5 min)*
- **[04-conventions.md](04-conventions.md)** - Variables and standards *(5 min)*

### **🔄 Operational Flows:**
- **[flows/10-mirror-to-disk.md](flows/10-mirror-to-disk.md)** - Build portable mirror archives
- **[flows/11-from-disk-to-registry.md](flows/11-from-disk-to-registry.md)** - Deploy archives to registry  
- **[flows/12-mirror-to-registry.md](flows/12-mirror-to-registry.md)** - Direct registry mirroring
- **[flows/13-delete.md](flows/13-delete.md)** - Safe image deletion workflow
- **[flows/20-cluster-upgrade.md](flows/20-cluster-upgrade.md)** - OpenShift cluster upgrades

### **✅ Operational Checklists:**
- **[checklists/prereqs-ready.md](checklists/prereqs-ready.md)** - Environment validation
- **[checklists/run-go.md](checklists/run-go.md)** - Pre-execution checklist  
- **[checklists/post-done.md](checklists/post-done.md)** - Success validation

### **📚 Reference Materials:**
- **[references/troubleshooting.md](references/troubleshooting.md)** - Error diagnosis & fixes
- **[references/cache-management.md](references/cache-management.md)** - Storage optimization
- **[references/oc-mirror-commands.md](references/oc-mirror-commands.md)** - Complete command reference

## 🤝 **Contributing to the Hackathon**

See **[contributors-guide.md](contributors-guide.md)** for:
- Documentation standards and conventions
- How to add new flows or enhance existing ones  
- Testing and validation requirements
- PR submission guidelines

## 🎉 **Ready to Begin?**

**👉 Start with [01-concepts.md](01-concepts.md) then proceed to [02-shared-prereqs.md](02-shared-prereqs.md)**

---

## 📊 **Repository Stats & Status**

- **🔥 Active Flows**: 5 complete workflows
- **🧪 Testing Status**: All flows validated in RHEL 9  
- **📦 Scripts**: 8+ production-ready automation scripts
- **📖 Documentation**: 20+ comprehensive guides and references
- **🎯 Hackathon Ready**: Complete end-to-end workflows ✅

**Last Updated**: August 2025 | **Next Hackathon**: [Date] | **Status**: 🟢 Production Ready
