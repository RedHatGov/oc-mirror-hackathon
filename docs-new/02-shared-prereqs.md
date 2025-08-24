# Shared Prerequisites - One-Time Setup

## 🎯 **Single Source of Truth for Environment Setup**

Complete these prerequisites **once** per environment. All workflow guides reference this document rather than duplicating setup steps.

## 🏗️ **Environment Architecture**

### **Host Roles (Choose Your Pattern):**

#### **🔄 Single Host Lab (Hackathon Friendly)**
- **Mirror Node + Registry Node**: Same system
- **Use Case**: Learning, testing, resource-constrained environments
- **Requirements**: Minimum specs for combined workload

#### **🏢 Two-Host Production (Enterprise Pattern)**  
- **Mirror Node**: Connected/semi-connected system for content preparation
- **Registry Node**: Disconnected system serving OpenShift clusters
- **Use Case**: Real enterprise deployments, air-gapped environments

## 🖥️ **System Requirements**

### **Minimum Hardware:**
- **CPU**: 4 cores
- **Memory**: 16GB RAM  
- **Storage**: 500GB+ available (adjust based on mirror scope)
- **Network**: Reliable connectivity to required sources

### **Supported Operating Systems:**
- ✅ **RHEL 9.x** (Tested and validated)
- ✅ **RHEL 8.x** (Supported)
- ✅ **Fedora 38+** (Community testing)

## 🔧 **Required Tools Installation**

### **Install oc-mirror v2 and Dependencies:**
```bash
# Download and install OpenShift tools (use our simplified script)
./collect_ocp

# Or manually install required tools:
# - oc-mirror v2
# - oc (OpenShift CLI)  
# - openshift-install
# - podman/docker
# - jq, yq (JSON/YAML processing)
# - sha256sum (checksum verification)
# - skopeo (container image utilities)
```

### **Verify Tool Versions:**
```bash
# Essential version checks
oc-mirror --v2 version
oc version --client
podman --version
jq --version

# Expected output patterns:
# oc-mirror: v2.x.x
# oc: 4.19+ 
# podman: 4.0+
```

## 🌐 **Network Configuration**

### **Internet Connectivity Requirements:**

#### **Mirror Node (Connected/Semi-Connected):**
- **Outbound HTTPS (443)** to:
  - `registry.redhat.io` (Red Hat images)
  - `quay.io` (OpenShift release images) 
  - `mirror.openshift.com` (Cincinnati graph data)
- **Optional**: Proxy configuration if required

#### **Registry Node (Can be Disconnected):**
- **Inbound HTTPS (8443)** from OpenShift cluster nodes
- **No internet required** (serves only cached/mirrored content)

### **DNS and Certificate Requirements:**
- **Registry FQDN**: Must resolve and match TLS certificates
- **Time Synchronization**: NTP configured and working
- **Firewall Rules**: Ports open for registry and image transfer

## 🔒 **OpenShift Cluster Prerequisites**

### **Cluster Access:**
```bash
# Verify OpenShift cluster access
oc whoami --show-console
oc get nodes

# Expected: Authenticated cluster admin access
# Required for applying mirror configuration
```

### **Cluster Version Requirements:**
- **OpenShift 4.19+** for oc-mirror v2 full compatibility
- **Cluster Admin** privileges required
- **ImageContentSourcePolicy/ImageDigestMirrorSet** support

## 🏭 **Registry Setup**

### **Option 1: Mirror Registry (Recommended for Hackathon)**
```bash
# Deploy Red Hat's mirror-registry
cd downloads/mirror-registry/
sudo ./mirror-registry install \
    --quayHostname $(hostname) \
    --quayRoot /opt/quay

# Creates registry at: $(hostname):8443
```

### **Option 2: Existing Registry (Enterprise)**
- **Quay Enterprise**: Full-featured enterprise registry
- **Artifactory**: JFrog enterprise registry solution
- **Harbor**: Cloud-native registry with security scanning

### **Registry Configuration Requirements:**
- ✅ **TLS Enabled**: Production deployments require HTTPS
- ✅ **Push/Pull Permissions**: Service account with appropriate access
- ✅ **Storage**: Adequate space for mirrored content
- ✅ **Garbage Collection**: Configured retention policies

## 🔐 **Authentication Setup**

### **Registry Authentication:**
```bash
# Login to your registry (creates auth.json)
podman login $(hostname):8443

# Verify authentication file
cat ~/.config/containers/auth.json

# Required: Valid credentials for push/pull operations
```

### **Pull Secret Integration:**
```bash
# Download cluster pull secret from Red Hat Console
# Location: https://console.redhat.com/openshift/install/pull-secret

# Merge with registry credentials if needed
# Details in individual flow guides
```

## 🗂️ **Directory Structure Setup**

### **Create Canonical Directory Structure:**
```bash
# Create standard directory layout (will be defined in 04-conventions.md)
sudo mkdir -p /srv/oc-mirror/{workspace,deliveries,archive}
sudo chown -R $(whoami):$(whoami) /srv/oc-mirror/

# Alternative: Use relative paths in home directory
mkdir -p ~/oc-mirror/{workspace,deliveries,archive}
```

### **Storage Considerations:**
- **Workspace**: Persistent, moderate size (10-50GB)
- **Deliveries**: Temporary, large archives (100-500GB)
- **Archive**: Long-term retention, manageable cleanup

## ⚡ **Performance Optimization**

### **Storage Performance:**
- **SSD Recommended**: For workspace and cache directories
- **Network Storage**: Acceptable for delivery archives  
- **Separate Filesystems**: Consider dedicating storage to oc-mirror

### **Network Optimization:**
```bash
# Configure parallel operations (in ImageSetConfiguration)
# Or via command flags:
--parallel-images 8
--parallel-layers 10

# Adjust based on bandwidth and target capacity
```

## 🔍 **Validation & Health Checks**

### **Environment Validation:**
```bash
# Comprehensive environment check
echo "=== Environment Validation ==="

# 1. Tool Versions
echo "Tools:"
oc-mirror --v2 version 2>/dev/null || echo "❌ oc-mirror v2 not found"
oc version --client 2>/dev/null || echo "❌ oc not found"

# 2. Cluster Access  
echo "Cluster:"
oc whoami 2>/dev/null && echo "✅ Cluster access" || echo "❌ No cluster access"

# 3. Registry Connectivity
echo "Registry:"
curl -sk https://$(hostname):8443/v2/ && echo "✅ Registry accessible" || echo "❌ Registry not accessible"

# 4. Storage Space
echo "Storage:"
df -h /srv/oc-mirror/ 2>/dev/null || df -h ~/oc-mirror/ 2>/dev/null

# 5. Time Sync
echo "Time:"
timedatectl status | grep "NTP service" || echo "⚠️ Check NTP configuration"
```

## 🎯 **Checkpoint: Prerequisites Complete**

Before proceeding to any workflow, verify:

- [ ] **System Requirements**: Hardware, OS, storage adequate
- [ ] **Tools Installed**: oc-mirror v2, oc, podman, utilities
- [ ] **Network Access**: Appropriate connectivity for your pattern  
- [ ] **OpenShift Access**: Cluster admin authentication working
- [ ] **Registry Deployed**: Accessible and authenticated
- [ ] **Directory Structure**: Created and accessible
- [ ] **Validation Passed**: Environment check script successful

## 🚀 **Next Steps**

### **Choose Your Path:**
1. **Environment Profiles**: [03-env-profiles.md](03-env-profiles.md) - Select deployment pattern
2. **Conventions**: [04-conventions.md](04-conventions.md) - Learn standard variables
3. **Prerequisites Checklist**: [checklists/prereqs-ready.md](checklists/prereqs-ready.md) - Final validation

## 💡 **Troubleshooting Common Setup Issues**

### **oc-mirror v2 Installation Issues:**
```bash
# If oc-mirror not found:
which oc-mirror || echo "Use ./collect_ocp script to install"

# If wrong version:
oc-mirror version | grep -q "v2" || echo "Ensure v2 installation"
```

### **Registry Connection Issues:**
```bash
# Test registry connectivity:
curl -k https://$(hostname):8443/v2/
# Expected: {} (empty JSON response)

# Check authentication:
podman login --get-login $(hostname):8443
# Expected: username output
```

### **Permission Issues:**
```bash
# Fix ownership for oc-mirror directories:
sudo chown -R $(whoami):$(whoami) /srv/oc-mirror/

# Verify OpenShift cluster admin:
oc auth can-i '*' '*' --all-namespaces
# Expected: yes
```

---

**⚠️ Important**: This setup is required only once per environment. All workflow guides assume these prerequisites are complete and reference this document for any environment-specific requirements.
