# OpenShift oc-mirror Infrastructure Guide

A comprehensive guide for setting up and operating oc-mirror for disconnected OpenShift environments, covering mirror registry deployment, content mirroring, and cluster configuration.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Infrastructure Requirements](#infrastructure-requirements)
4. [OpenShift Tools Installation](#openshift-tools-installation)
5. [Mirror Registry Setup](#mirror-registry-setup)
6. [Content Mirroring](#content-mirroring)
7. [Disconnected Installation Configuration](#disconnected-installation-configuration)
8. [Post-Installation Configuration](#post-installation-configuration)
9. [Troubleshooting](#troubleshooting)
10. [References](#references)

## Overview

This guide walks you through setting up a complete oc-mirror infrastructure for disconnected OpenShift installations:

- **Mirror Registry**: Local Quay registry for container images
- **Content Mirroring**: OpenShift release images and operators
- **Disconnected Configuration**: Cluster configuration for air-gapped environments

### What You'll Build
- 🗃️ **Mirror Registry**: Self-hosted container registry
- 📦 **Mirrored Content**: OpenShift releases and operators
- ⚙️ **Configuration Resources**: IDMS/ITMS manifests for disconnected clusters

## Prerequisites

### Required Access
- Valid Red Hat account with OpenShift pull secret access
- Administrative access to your infrastructure environment
- Network connectivity for initial content download

### Technical Requirements
- Linux host with container runtime (Podman/Docker)
- 500+ GB storage for mirroring operations
- Stable internet connection for initial content download
- DNS resolution capability for registry hostname

## Infrastructure Requirements

### Host Specifications
| Component | Minimum Requirement | Recommended |
|-----------|---------------------|-------------|
| **CPU** | 4 vCPUs | 8+ vCPUs |
| **Memory** | 8 GB RAM | 16+ GB RAM |
| **Storage** | 500 GB | 1+ TB |
| **Network** | Stable internet connection | High bandwidth connection |

### Network Requirements
- **Outbound Access**: Access to Red Hat registries during mirroring
- **Inbound Access**: Port 8443 for mirror registry (if serving other hosts)
- **DNS**: Resolvable hostname for the mirror registry

### Supported Operating Systems
- Red Hat Enterprise Linux 8+
- CentOS Stream 8+
- Fedora 35+
- Ubuntu 20.04+

## OpenShift Tools Installation

### 1. System Preparation

```bash
# Install required packages (RHEL/CentOS/Fedora)
sudo dnf install -y podman git jq vim wget

# For Ubuntu/Debian systems
# sudo apt update && sudo apt install -y podman git jq vim wget

# Verify installation
podman --version
git --version
```

### 2. Clone Repository

```bash
# Clone the hackathon repository
git clone https://github.com/RedHatGov/oc-mirror-hackathon.git
cd oc-mirror-hackathon
```

### 3. Download OpenShift Binaries

Execute the simplified collection script:

```bash
# Edit the OpenShift version if needed (default is "stable")
# Edit line 14 in collect_ocp_simple: OPENSHIFT_VERSION="4.19.2"

# Run the collection script
./collect_ocp_simple
```

**This script downloads and installs:**
- 🔧 **oc-mirror** - Content mirroring tool for disconnected OpenShift installations
- 🛠️ **openshift-install** - OpenShift cluster installer (version-specific)
- 💻 **oc** - OpenShift command-line interface
- 🗃️ **mirror-registry** - Local Quay container registry
- ⚙️ **butane** - Machine configuration generation tool

**For air-gapped systems:**
The script creates `downloads/install.sh` for easy deployment on disconnected systems:
1. Copy the entire `downloads/` directory to your air-gapped environment
2. Run `cd downloads && ./install.sh` to install all tools

### 4. Verify Installation

Confirm all tools are properly installed and accessible:

```bash
# Check oc-mirror
oc-mirror help

# Check OpenShift CLI
oc version

# Check installer
openshift-install version

# Check butane
butane --help
```

## Mirror Registry Setup

### 1. Install Mirror Registry

Navigate to the mirror registry directory and run the installer:

```bash
# Change to mirror registry directory
cd ~/oc-mirror-hackathon/mirror-registry

# Install mirror registry with your hostname
./mirror-registry install --quayHostname $(hostname -f)
```

> 📝 **Critical:** When the installation completes, **save the generated registry credentials** (username and password) from the last line of the log output to a secure location. You'll need these for authentication.

### 2. Trust Registry SSL Certificate

Configure the host to trust the registry's self-signed certificate:

```bash
# Copy certificate to system trust store
sudo cp ~/quay-install/quay-rootCA/rootCA.pem /etc/pki/ca-trust/source/anchors/

# Update certificate trust
sudo update-ca-trust

# Verify certificate is trusted
curl -I https://$(hostname -f):8443
```

### 3. Configure Authentication

#### Download Red Hat Pull Secret
1. **Navigate to:** [OpenShift Downloads](https://console.redhat.com/openshift/downloads)
2. **Copy your pull secret**
3. **Use the below commands to paste the pull secret on your host**

#### Set Up Container Authentication
```bash
# Create container config directory
mkdir -p ~/.config/containers

# Create auth.json file with your Red Hat pull secret
vi ~/.config/containers/auth.json
# Paste your pull secret content into this auth.json file

# Login to your mirror registry (use credentials from installation)
podman login https://$(hostname -f):8443 \
  --username init \
  --password [YOUR_REGISTRY_PASSWORD] \
  --authfile ~/.config/containers/auth.json
```

### 4. Verify Registry Access

Test registry access:

```bash
# Test API access
curl -k https://$(hostname -f):8443/v2/

# Test web interface (if accessible)
# Navigate to: https://your-hostname:8443
# Login with credentials from installation
```

## Content Mirroring

### 1. Understanding the Mirror Process

The mirroring process consists of two stages:
1. **Mirror to Local Storage:** Download content from Red Hat registries
2. **Upload to Mirror Registry:** Transfer content to your local registry

### 2. Mirror OpenShift Content to Local Storage

Execute the first mirroring stage:

```bash
# Navigate to oc-mirror configuration directory
cd ~/oc-mirror-hackathon/oc-mirror-master/

# Execute local mirroring
./oc-mirror.sh
```

**This command:**
- Uses the `imageset-config.yaml` configuration
- Downloads OpenShift release content
- Stores content locally in the `content/` directory
- Creates cache in `content/.cache/` subdirectory

> 🔍 **Inspection Points:** While mirroring runs, explore these directories to understand the process:
> - `content/.cache/` - Downloaded content cache
> - `.oc-mirror/` - Metadata and state information
> - `content/` - Mirrored content ready for upload

### 3. Transfer Content Between Hosts (Optional)

If you're using separate hosts for mirroring and registry operations, transfer the mirrored content:

```bash
# Create archive for transfer
tar -czf oc-mirror-content-$(date +%Y%m%d).tar.gz content/

# Transfer to registry host (replace with your target host)
scp oc-mirror-content-$(date +%Y%m%d).tar.gz registry-host:/tmp/

# On registry host, extract content
ssh registry-host "cd /path/to/oc-mirror && tar -xzf /tmp/oc-mirror-content-$(date +%Y%m%d).tar.gz"
```

### 4. Upload Content to Mirror Registry

Transfer mirrored content to your registry:

```bash
# Upload content to registry
./oc-mirror-to-registry.sh
```

**This command:**
- Uploads all mirrored content to your registry
- Creates installation resource files
- Generates IDMS and ITMS manifests for cluster installation

> 🔍 **Important Output:** Look for these messages indicating successful resource generation:
> ```
> [INFO]   : 📄 Generating IDMS file...
> [INFO]   : content/working-dir/cluster-resources/idms-oc-mirror.yaml file created
> [INFO]   : 📄 Generating ITMS file...
> [INFO]   : content/working-dir/cluster-resources/itms-oc-mirror.yaml file created
> ```

### 5. Inspect Generated Resources

Review the generated cluster resources:

```bash
# View the IDMS file (Image Digest Mirror Set)
cat ~/oc-mirror-hackathon/oc-mirror-master/content/working-dir/cluster-resources/idms-oc-mirror.yaml

# View the ITMS file (Image Tag Mirror Set)
cat ~/oc-mirror-hackathon/oc-mirror-master/content/working-dir/cluster-resources/itms-oc-mirror.yaml
```

## Disconnected Installation Configuration

### 1. Prepare Installation Prerequisites

#### Generate SSH Key Pair
```bash
# Generate SSH key for cluster access
ssh-keygen -t ed25519 -C "openshift@$(hostname)"
# Accept defaults for key location and passphrase

# Verify key generation
ls -la ~/.ssh/id_ed25519*
```

#### Prepare Authentication Configuration
```bash
# View your current auth configuration
cat ~/.config/containers/auth.json

# Extract registry-specific authentication for install config
# Format needed: {"auths": {"your-hostname:8443": {"auth": "BASE64_ENCODED_CREDENTIALS"}}}
```

### 2. Configure Disconnected Installation

When creating your OpenShift installation configuration, include the following sections:

#### Add Image Mirror Sources
```yaml
imageDigestSources:
  - mirrors:
    - your-hostname:8443/openshift/release
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
  - mirrors:
    - your-hostname:8443/openshift/release-images
    source: quay.io/openshift-release-dev/ocp-release
```

#### Add Additional Trust Bundle
Include the registry certificate in the installation configuration:

```bash
# Get the registry certificate
cat ~/quay-install/quay-rootCA/rootCA.pem
```

**Add the additionalTrustBundle section to install-config.yaml:**
```yaml
additionalTrustBundle: |
  -----BEGIN CERTIFICATE-----
  [PASTE YOUR CERTIFICATE CONTENT HERE]
  -----END CERTIFICATE-----
```

## Post-Installation Configuration

### 1. Configure Cluster Certificate Trust

Configure the cluster to trust your mirror registry's SSL certificate:

#### Create Certificate ConfigMap
```bash
# Create ConfigMap with registry certificate
oc create configmap registry-config \
  --from-file=$(hostname -f)..8443=${HOME}/quay-install/quay-rootCA/rootCA.pem \
  -n openshift-config
```

#### Apply Certificate to Cluster
```bash
# Patch cluster image configuration to trust the registry
oc patch image.config.openshift.io/cluster \
  --patch '{"spec":{"additionalTrustedCA":{"name":"registry-config"}}}' \
  --type=merge
```

### 2. Disable Default Operator Sources

Disable the default OperatorHub sources to ensure operators are pulled from your mirror registry:

```bash
# Disable all default operator sources
oc patch OperatorHub cluster --type json \
  -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
```

### 3. Apply Mirror Configuration Resources

Apply the IDMS and ITMS resources generated during the mirroring process:

```bash
# Navigate to mirror configuration directory
cd ~/oc-mirror-hackathon/oc-mirror-master

# Apply all cluster resources
oc apply -f content/working-dir/cluster-resources/
```

**Applied Resources:**
- **IDMS** (ImageDigestMirrorSet): Maps digest-based image references to mirror registry
- **ITMS** (ImageTagMirrorSet): Maps tag-based image references to mirror registry
- **CatalogSource**: Defines operator catalog sources from mirror registry

#### Verify Applied Resources
```bash
# Check IDMS resources
oc get imageDigestMirrorSet

# Check ITMS resources  
oc get imageTagMirrorSet

# Check catalog sources
oc get catalogsource -n openshift-marketplace
```

### 4. Verify Disconnected Operation

Confirm your cluster is using mirrored content:

```bash
# Check image sources
oc get imageDigestMirrorSet
oc get imageTagMirrorSet

# Verify cluster operators are healthy
oc get clusteroperators

# Check that pods are pulling from mirror registry
oc get events --all-namespaces | grep -i pull
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Mirror Registry Connection Issues
**Symptoms:** Cannot access registry or authentication fails

**Solutions:**
- Verify registry is running: `podman ps`
- Check DNS resolution: `nslookup $(hostname -f)`
- Test certificate trust: `curl -I https://$(hostname -f):8443`
- Verify firewall allows port 8443

#### 2. Authentication Failures
**Symptoms:** Login failures during mirroring or installation

**Solutions:**
- Verify pull secret format and encoding
- Confirm registry credentials are correct
- Check auth.json file permissions: `chmod 600 ~/.config/containers/auth.json`
- Re-login to registry: `podman login https://$(hostname -f):8443`

#### 3. Mirroring Timeouts or Failures
**Symptoms:** Downloads fail or timeout during mirroring

**Solutions:**
- Ensure adequate storage space: `df -h`
- Verify network connectivity to Red Hat registries
- Check disk I/O performance: `iostat`
- Restart mirroring process (cache will be preserved)

#### 4. Installation Failures
**Symptoms:** Cluster installation fails or hangs

**Solutions:**
- Verify install-config.yaml format and content
- Check platform-specific credentials and permissions
- Ensure mirror registry is accessible from cluster nodes
- Review installation logs in `.openshift_install.log`

#### 5. Post-Installation Issues
**Symptoms:** Cluster operators degraded or pods not starting

**Solutions:**
- Check cluster operator status: `oc get co`
- Verify image pull from mirror registry: `oc describe pod [pod-name]`
- Check node status and resources: `oc get nodes -o wide`
- Review cluster events: `oc get events --sort-by=.metadata.creationTimestamp`

### Diagnostic Commands

#### System Resources
```bash
# Check disk space
df -h

# Check memory usage
free -h

# Check CPU usage
top

# Check network connectivity
ping google.com
curl -I registry.redhat.io
```

#### Container and Registry Status
```bash
# Check running containers
podman ps -a

# Check registry logs
podman logs [registry-container-id]

# Test registry connectivity
curl -k https://$(hostname -f):8443/v2/
```

#### OpenShift Diagnostics
```bash
# Cluster version and status
oc get clusterversion
oc get clusteroperators

# Node status and details
oc get nodes -o wide
oc describe node [node-name]

# Pod status across namespaces
oc get pods --all-namespaces | grep -v Running

# Check image pull issues
oc describe pod [pod-name] | grep -i pull
```

### Log Locations

| Component | Log Location | Description |
|-----------|--------------|-------------|
| **Mirror Registry** | `~/quay-install/` | Registry installation and runtime logs |
| **oc-mirror** | `~/.oc-mirror/logs/` | Mirroring operation logs |
| **System Logs** | `/var/log/messages` | System-level logs |
| **OpenShift Install** | `./.openshift_install.log` | Installation process logs |
| **Podman** | `journalctl -u podman` | Container runtime logs |

### Emergency Recovery

#### Restart Mirror Registry
```bash
cd ~/oc-mirror-hackathon/mirror-registry
./mirror-registry install --quayHostname $(hostname -f)
```

#### Clean and Restart Mirroring
```bash
# Remove cache and restart
rm -rf ~/.oc-mirror/
cd ~/oc-mirror-hackathon/oc-mirror-master/
./oc-mirror.sh
```

#### Reset Installation
```bash
# Destroy incomplete cluster (platform-specific command)
openshift-install destroy cluster

# Recreate install config and try again
openshift-install create install-config
```

## References

### Official Documentation
- [oc-mirror Documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/4.12/html/disconnected_installation_mirroring/installing-mirroring-disconnected) - Comprehensive mirroring guide
- [OpenShift Disconnected Installation](https://docs.openshift.com/container-platform/latest/installing/disconnected_install/) - Official disconnected installation documentation
- [Mirror Registry Documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/installing/disconnected-installation-mirroring) - Mirror registry setup and configuration

### Additional Resources
- [oc-mirror GitHub Repository](https://github.com/openshift/oc-mirror) - Source code and latest updates
- [OpenShift Downloads](https://console.redhat.com/openshift/downloads) - Pull secrets and tools

### Community Resources
- [OpenShift Community](https://www.openshift.com/community/) - Community support and discussions
- [Red Hat Customer Portal](https://access.redhat.com/) - Official support and knowledge base

---

## Quick Command Reference

### Essential Commands
```bash
# Check system status
df -h && free -h && podman ps

# Mirror content
cd ~/oc-mirror-hackathon/oc-mirror-master/
./oc-mirror.sh && ./oc-mirror-to-registry.sh

# Deploy cluster (platform-specific)
openshift-install create cluster --log-level debug

# Access cluster
export KUBECONFIG=auth/kubeconfig
oc get nodes && oc get co
```

### Registry Management
```bash
# Check registry status
podman ps | grep quay

# View registry logs
podman logs $(podman ps | grep quay | awk '{print $1}')

# Test registry access
curl -k https://$(hostname -f):8443/v2/
```

---

> 📋 **Note:** This guide provides instructions for lab and development environments. For production deployments, implement additional security measures including proper certificate management, network segmentation, access controls, and backup strategies.

*Last Updated: December 2024*  
*Guide Focus: oc-mirror Infrastructure*  
*Platform: Infrastructure Agnostic*
