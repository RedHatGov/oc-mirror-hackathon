# Mirror-to-Disk Flow

**oc-mirror --v2 Flow Pattern**

## Overview

The **mirror-to-disk** flow creates portable archive packages of OpenShift content that can be transferred to disconnected environments. This flow downloads content from external registries and stores it in local disk storage, ready for transfer across air gaps.

## Use Cases

- **Air-gapped environments** - Create portable content for transfer across air gaps
- **Bandwidth-constrained sites** - Download once, use multiple times
- **Offline installations** - Package content for disconnected deployment
- **Content distribution** - Create standardized deployment packages
- **Disaster recovery** - Backup OpenShift content for restoration

## Flow Pattern

```mermaid
flowchart LR
    A[Red Hat Registries] --> B[oc-mirror --v2]
    B --> C[Local Disk Storage]
    C --> D[content/ Directory]
    D --> E[Portable Archive]
```

## Prerequisites

### System Requirements
- **Linux System:** RHEL 9+, CentOS Stream, or compatible distribution  
- **Storage:** 500+ GB available disk space for mirroring operations
- **Memory:** 8+ GB RAM recommended for oc-mirror operations
- **Network:** Stable internet connection for initial content download
- **Container Runtime:** Podman 4.0+ installed and configured

### Required Tools
- **oc-mirror:** OpenShift mirroring tool v2
- **Red Hat Pull Secret:** Valid authentication for Red Hat registries
- **Basic utilities:** git, curl, tar for archive operations

### Setup Verification
```bash
# Verify oc-mirror is available
oc-mirror --help

# Verify podman is working
podman version

# Check available disk space (need 500+ GB)
df -h /
```

## Configuration

### ImageSet Configuration

Create or verify your `imageset-config.yaml`:

```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
archiveSize: 8
mirror:
  platform:
    channels:
    - name: stable-4.19
      minVersion: 4.19.2
      maxVersion: 4.19.2 
    graph: true
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.19
      packages:
        - name: web-terminal
  additionalImages: 
    - name: registry.redhat.io/ubi9/ubi:latest
```

**Key Configuration Options:**
- **archiveSize: 8** - Creates 8GB archive chunks for easier transfer
- **platform.graph: true** - Includes Cincinnati graph data (required for upgrades)
- **minVersion/maxVersion** - Controls which OpenShift versions to mirror
- **operators** - Optional operator content to include
- **additionalImages** - Extra container images to mirror

---

## System Preparation

### Prerequisites Setup

Before starting, ensure your Linux system has:

```bash
# Install required packages (RHEL/CentOS)
sudo dnf install -y podman git jq vim wget curl

# Verify installations
podman --version
git --version
```

#### Set System Hostname
```bash
# Set a proper hostname for your system (replace with your desired hostname)
sudo hostnamectl set-hostname mirror-registry.example.com

# Verify hostname is set
hostname
```

#### Configure Local Firewall
Configure the firewall to allow inbound access to the registry:

```bash
# Allow HTTP traffic (port 80)
sudo firewall-cmd --permanent --add-port=80/tcp

# Allow HTTPS traffic (port 443)  
sudo firewall-cmd --permanent --add-port=443/tcp

# Allow mirror registry traffic (port 8443)
sudo firewall-cmd --permanent --add-port=8443/tcp

# Reload firewall to apply changes
sudo firewall-cmd --reload

# Verify firewall rules
sudo firewall-cmd --list-ports
```

> 🛡️ **Security Note:** These firewall rules allow access from any source. In production environments, restrict access to specific IP ranges using `--source=IP_RANGE/CIDR` instead of opening ports globally.

## OpenShift Tools Installation

### 1. Clone Repository

```bash
# Clone the hackathon repository
git clone https://github.com/RedHatGov/oc-mirror-hackathon.git
cd oc-mirror-hackathon
```

### 2. Download OpenShift Binaries

Execute the simplified collection script:

```bash
# Edit the OpenShift version if needed (default is "stable")
# Edit line 14 in collect_ocp: OPENSHIFT_VERSION="4.19.2" 

# Run the collection script
./collect_ocp
```

**This script downloads and installs:**
- 🔧 **oc-mirror** - Content mirroring tool for disconnected OpenShift installations
- 🛠️ **openshift-install** - OpenShift cluster installer (version-specific)
- 💻 **oc** - OpenShift command-line interface
- 🗃️ **mirror-registry** - Local Quay container registry
- ⚙️ **butane** - Machine configuration generation tool

**For disconnected installations:**

1. Copy the entire `downloads/` directory to your disconnected environment
2. Run `cd downloads && ./install.sh` to install all tools

### 2.5. Hackathon-Specific oc-mirror v2 (OpenShift 4.20.0-ec.5)

**For exact hackathon version consistency**, upgrade to oc-mirror v2 from 4.20.0-ec.5:

```bash
# After running collect_ocp, get the hackathon-specific oc-mirror v2
cd downloads/

# Download oc-mirror v2 from OpenShift 4.20.0-ec.5
echo "🔄 Downloading hackathon-specific oc-mirror v2..."
curl -L -o oc-mirror-hackathon.rhel9.tar.gz \
  "https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/4.20.0-ec.5/oc-mirror.rhel9.tar.gz"

# Backup the existing oc-mirror (optional)
mv oc-mirror oc-mirror-stable-backup 2>/dev/null || true

# Extract and install hackathon oc-mirror
tar -xzf oc-mirror-hackathon.rhel9.tar.gz
chmod +x oc-mirror

# Install to PATH
sudo cp oc-mirror /usr/local/bin/
```

> **💡 Hackathon Tip:** This ensures all participants use the exact same oc-mirror v2 version for consistent results and troubleshooting.

### 3. Verify Installation

Confirm all tools are properly installed and accessible:

```bash
# Check oc-mirror
oc-mirror help

# Verify hackathon version (4.20.0-ec.5)
oc-mirror --version

# Check OpenShift CLI
oc version

# Check installer (Note: the installer is specific for a release image)
openshift-install version

# Check butane
butane --help
```

## Mirror Registry Setup

### 1. Install Mirror Registry

Navigate to the mirror registry directory and run the installer:

```bash
# Change to mirror registry directory
cd ~/oc-mirror-hackathon/downloads/mirror-registry

# Install mirror registry
./mirror-registry install 
```

> 📝 **Critical:** When the installation completes, **save the generated registry credentials** (username and password) from the last line of the log output to a secure location. You'll need these for authentication.

### 2. Trust Registry SSL Certificate

Configure the bastion to trust the registry's self-signed certificate:

```bash
# Copy certificate to system trust store
sudo cp ~/quay-install/quay-rootCA/rootCA.pem /etc/pki/ca-trust/source/anchors/

# Update certificate trust
sudo update-ca-trust

# Verify certificate is trusted
curl -I https://$(hostname):8443
```

### 3. Configure Authentication

#### Download Red Hat Pull Secret
1. **Navigate to:** [OpenShift Downloads](https://console.redhat.com/openshift/downloads)
2. **Copy your pull secret**
3. **Use the below commands to paste the pull secret in your bastion**

#### Set Up Container Authentication
```bash
# Create container config directory
mkdir -p ~/.config/containers

# Create auth.json file with your Red Hat pull secret
vi ~/.config/containers/auth.json
# Paste your pull secret content into this auth.json file

# Login to your mirror registry (use credentials from installation)
podman login https://$(hostname):8443 \
  --username init \
  --password [YOUR_REGISTRY_PASSWORD] \
  --authfile ~/.config/containers/auth.json
```

### 4. Verify Registry Access

Test registry access via web browser:
- **Navigate to your registry URL:** e.g. `https://<YOUR-MIRROR-REGISTRY-HOSTNAME>:8443`
- **Login with your credentials** from the installation
- **Verify the registry interface loads**

---

## Step-by-Step Procedure

### 1. Navigate to Working Directory

```bash
# Navigate to oc-mirror configuration directory
cd ~/oc-mirror-hackathon/oc-mirror-master/
```

### 2. Execute Mirror-to-Disk Operation

```bash
# Execute mirror-to-disk using our tested script
./oc-mirror-to-disk.sh
```

**This command:**
- Uses the `imageset-config.yaml` configuration
- Downloads OpenShift 4.19.2+ release content from Red Hat registries
- Stores content locally in the `content/` directory
- Creates performance cache in `.cache/` directory
- Packages content into portable format

### 3. Monitor Progress

While mirroring runs (typically 15-45 minutes), monitor these indicators:

```bash
# Check content directory growth
watch -n 30 "du -sh content/ .cache/"

# Monitor oc-mirror logs for progress
tail -f ~/.oc-mirror/logs/oc-mirror.log
```

> 🔍 **Inspection Points:** Explore these directories to understand the process:
> - `content/working-dir/` - Essential metadata and Cincinnati graph data
> - `content/` - Mirrored container images and manifests
> - `.cache/` - Performance cache (not transferred to disconnected systems)

### 4. Verify Mirror Success

```bash
# Check final content size
du -sh content/

# Verify working directory structure
ls -la content/working-dir/

# Check for essential files
ls -la content/working-dir/cluster-resources/
```

**Expected Output:**
- **content/** directory: 20-50GB of mirrored OpenShift content
- **cluster-resources/** directory: IDMS/ITMS YAML files for installation
- **Cincinnati graph data** for upgrade operations

## Create Portable Archive

### 5. Package Content for Transfer

```bash
# Create timestamped archive for transfer
tar -czf oc-mirror-content-$(date +%Y%m%d-%H%M).tar.gz content/

# Verify archive was created successfully
ls -lh oc-mirror-content-*.tar.gz

# Generate checksums for integrity verification
sha256sum oc-mirror-content-*.tar.gz > oc-mirror-content-$(date +%Y%m%d-%H%M).sha256
```

**Transfer Package Contents:**
- **oc-mirror-content-YYYYMMDD-HHMM.tar.gz** - Complete mirrored content
- **oc-mirror-content-YYYYMMDD-HHMM.sha256** - Integrity verification checksums

## What Gets Created

| Component | Purpose | Transfer Required |
|-----------|---------|-------------------|
| **content/working-dir/** | Essential metadata, Cincinnati graph data | ✅ Yes |
| **content/images/** | OpenShift release images and manifests | ✅ Yes |
| **content/cluster-resources/** | IDMS/ITMS files for cluster installation | ✅ Yes |
| **.cache/** | Performance optimization cache | ❌ No (recreated on target) |

## Performance Optimization

For comprehensive performance tuning guidance:
**➡️ [oc-mirror Performance Tuning Reference](../reference/oc-mirror-v2-commands.md#performance-tuning)**

**Quick performance tips for mirror-to-disk:**
- Use `archiveSize: 8` for optimal transfer chunks
- Configure `--parallel-images` for faster downloads
- Schedule during off-peak hours for better network performance

---

## Troubleshooting

For comprehensive troubleshooting guidance:
**➡️ [oc-mirror v2 Troubleshooting Reference](../reference/oc-mirror-v2-commands.md#troubleshooting)**  
**➡️ [Cache-Specific Issues](../reference/cache-management.md#troubleshooting)**

**Quick debugging for mirror-to-disk:**
```bash
# Verify Red Hat authentication
podman login registry.redhat.io

# Check available disk space  
df -h /

# Use verbose logging for diagnostics
oc-mirror -c imageset-config.yaml file://content --v2 --verbose
```

---

## When to Use This Flow

### Choose Mirror-to-Disk When:
- ✅ **Air-gapped environments** requiring content transfer across security boundaries
- ✅ **Multiple disconnected sites** needing standardized deployment packages
- ✅ **Bandwidth constraints** where one-time download is preferred
- ✅ **Compliance requirements** for offline content validation
- ✅ **Disaster recovery** scenarios requiring content backup

### Choose Direct Registry Flows When:
- ❌ **Semi-connected environments** with reliable internet access
- ❌ **Single target deployment** with direct network connectivity
- ❌ **Real-time content needs** requiring immediate availability

---

## Next Steps

🎉 **Mirror-to-Disk Complete!** Your content is packaged in the `content/` directory.

### **📦 Create Portable Archive**

```bash
# Create compressed archive for transfer
tar -czf openshift-content-$(date +%Y%m%d).tar.gz content/

# Verify archive integrity
tar -tzf openshift-content-$(date +%Y%m%d).tar.gz | head -10
```

### **🚀 Deploy to Disconnected Environment**

**➡️ [from-disk-to-registry.md](from-disk-to-registry.md)**

Transfer your archive to the disconnected environment, then follow the from-disk-to-registry flow to:
- ✅ **Extract archived content** on the registry node
- ✅ **Upload to target registry** using mirrored content  
- ✅ **Generate IDMS/ITMS** for cluster configuration
- ✅ **Verify registry content** availability

### **🔄 Alternative Path**

For **two-host air-gapped workflow**, your content is ready for the complete disconnected deployment process.

## References

### **oc-mirror Flow Patterns**
- **Next Flow:** [from-disk-to-registry.md](from-disk-to-registry.md)
- **Alternative Flow:** [mirror-to-registry.md](mirror-to-registry.md) (semi-connected)
- **Image Deletion:** [delete.md](delete.md)
- **Flow Decision Guide:** [README.md](README.md)

### **Next Steps**
- **Registry Deployment:** [from-disk-to-registry.md](from-disk-to-registry.md)
- **OpenShift Cluster Creation:** [../guides/openshift-create-cluster.md](../guides/openshift-create-cluster.md)
- **Cluster Upgrade Guide:** [../guides/cluster-upgrade.md](../guides/cluster-upgrade.md)

### **Technical References**
- **oc-mirror v2 Commands & Troubleshooting:** [../reference/oc-mirror-v2-commands.md](../reference/oc-mirror-v2-commands.md)
- **Cache Management Guide:** [../reference/cache-management.md](../reference/cache-management.md)
- **Performance Tuning:** [../reference/oc-mirror-v2-commands.md#performance-tuning](../reference/oc-mirror-v2-commands.md#performance-tuning)

### **Setup & Infrastructure**
- **AWS Lab Infrastructure:** [../setup/aws-lab-infrastructure.md](../setup/aws-lab-infrastructure.md)
- **Complete oc-mirror Workflow:** [../setup/oc-mirror-workflow.md](../setup/oc-mirror-workflow.md)
