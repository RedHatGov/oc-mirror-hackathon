# OpenShift Disconnected Installation with oc-mirror

A comprehensive step-by-step guide for setting up disconnected OpenShift content mirroring using oc-mirror. This guide is platform-agnostic and works on any Linux system with the required tools installed.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [OpenShift Tools Installation](#openshift-tools-installation)
4. [Mirror Registry Setup](#mirror-registry-setup)
5. [Content Mirroring](#content-mirroring)
6. [User Transfer Workflows](#user-transfer-workflows)
7. [OpenShift Installation](#openshift-installation)
8. [Post-Installation](#post-installation)
9. [Troubleshooting](#troubleshooting)
10. [References](#references)

## Overview

This guide walks you through setting up disconnected OpenShift content mirroring using oc-mirror:

- **Mirror Registry**: Self-hosted Quay container registry
- **Content Mirroring**: OpenShift release images and operators using oc-mirror v2
- **User Transfer Workflows**: Enterprise-grade content handoff scenarios  
- **Disconnected Installation**: Air-gapped OpenShift cluster deployment

### What You'll Build
- 🗃️ **Mirror Registry**: Self-hosted container registry for disconnected environments
- 📦 **Mirrored Content**: OpenShift 4.19.2 release images and operators
- 👥 **User Workflows**: Content transfer and handoff procedures
- ☁️ **OpenShift Cluster**: Disconnected cluster using mirrored content

> 📋 **Infrastructure Setup:** If you need to set up lab infrastructure (bastion host, networking, etc.), see the [AWS Lab Infrastructure Setup Guide](aws-lab-infrastructure.md) for platform-specific instructions.

## Prerequisites

### Required Access
- Valid Red Hat account with OpenShift pull secret access
- Access to [Red Hat Customer Portal](https://console.redhat.com/) for downloading pull secrets
- SSH access to your Linux system (if using remote host)

### Technical Requirements
- **Linux System**: RHEL 9/10, CentOS Stream, or compatible Linux distribution
- **Storage**: 500+ GB available disk space for mirroring operations
- **Memory**: 8+ GB RAM recommended for oc-mirror operations
- **Network**: Stable internet connection for initial content download
- **Container Runtime**: Podman 4.0+ installed and configured
- **Tools**: Git, curl, wget, tar, and basic command-line utilities

### System Preparation
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

**For disconnected installations:**
The script also creates `downloads/install.sh` for easy deployment on air-gapped systems:
1. Copy the entire `downloads/` directory to your disconnected environment
2. Run `cd downloads && ./install.sh` to install all tools

### 3. Verify Installation

Confirm all tools are properly installed and accessible:

```bash
# Check oc-mirror
oc-mirror help

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
cd ~/oc-mirror-hackathon/mirror-registry

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
- Downloads OpenShift 4.19.2 release content
- Stores content locally in the `content/` directory
- Creates cache in `content/.cache/` subdirectory

> 🔍 **Inspection Points:** While mirroring runs, explore these directories to understand the process:
> - `content/.cache/` - Downloaded content cache
> - `.oc-mirror/` - Metadata and state information
> - `content/` - Mirrored content ready for upload

## User Transfer Workflows

This section covers advanced workflows for transferring mirrored content between different users or systems, commonly used in enterprise environments with role separation.

### Transfer Content Between Hosts (Optional)

If you're using separate hosts for mirroring and registry operations, transfer the mirrored content:

```bash
# Create archive for transfer
tar -czf oc-mirror-content-$(date +%Y%m%d).tar.gz content/

# Transfer to registry host (replace with your target host)
scp oc-mirror-content-$(date +%Y%m%d).tar.gz registry-host:/tmp/

# On registry host, extract content
ssh registry-host "cd /path/to/oc-mirror && tar -xzf /tmp/oc-mirror-content-$(date +%Y%m%d).tar.gz"
```

### 3. Upload Content to Mirror Registry

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

### 4. Inspect Generated Resources

Review the generated cluster resources:

```bash
# View the IDMS file (Image Digest Mirror Set)
cat ~/oc-mirror-hackathon/oc-mirror-master/content/working-dir/cluster-resources/idms-oc-mirror.yaml

# View the ITMS file (Image Tag Mirror Set)
cat ~/oc-mirror-hackathon/oc-mirror-master/content/working-dir/cluster-resources/itms-oc-mirror.yaml
```

## OpenShift Installation

### 1. Prepare Installation Prerequisites

#### Generate SSH Key Pair
```bash
# Generate SSH key for cluster access
ssh-keygen -t ed25519 -C "openshift@bastion"
# Accept defaults for key location and passphrase

# Verify key generation
ls -la ~/.ssh/id_ed25519*
```

#### Prepare Authentication Configuration
```bash
# View your current auth configuration
cat ~/.config/containers/auth.json

# Extract registry-specific authentication for install config
# Format needed: {"auths": {"<YOUR-MIRROR-REGISTRY-HOSTNAME>:8443": {"auth": "BASE64_ENCODED_CREDENTIALS"}}}
```

### 2. Create Installation Configuration

Run the OpenShift installer configuration wizard:

```bash
# Create install configuration
cd ~/oc-mirror-hackathon/ocp
openshift-install create install-config
```

**Provide the following information based on your cloud platform:**

| Parameter | Example Value | Notes |
|-----------|---------------|-------|
| **SSH Public Key** | `~/.ssh/id_ed25519.pub` | Generated above |
| **Platform** | AWS, Azure, GCP, vSphere, etc. | Your cloud/infrastructure provider |
| **Platform Credentials** | Various | Specific to your cloud provider |
| **Region/Location** | us-east-1, eastus, etc. | Provider-specific region |
| **Base Domain** | example.com | Your DNS domain for the cluster |
| **Cluster Name** | ocp | Descriptive cluster name |
| **Pull Secret** | Registry auth JSON | From your auth.json file |

> 📋 **Platform-Specific Setup:** For detailed cloud-specific configuration, refer to the [OpenShift Installation Documentation](https://docs.openshift.com/container-platform/latest/installing/) for your specific platform.

### 3. Configure Disconnected Installation

#### Add Image Mirror Sources
Edit the installation configuration to include mirror information:

```bash
# Edit the configuration
vi install-config.yaml
```

**Add the imageDigestSources section:**
```yaml
imageDigestSources:
  - mirrors:
    - <YOUR-MIRROR-REGISTRY-HOSTNAME>:8443/openshift/release
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
  - mirrors:
    - <YOUR-MIRROR-REGISTRY-HOSTNAME>:8443/openshift/release-images
    source: quay.io/openshift-release-dev/ocp-release
```

> 🔧 **Replace `<YOUR-MIRROR-REGISTRY-HOSTNAME>`** with your actual mirror registry hostname/IP address.

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

### 4. Deploy the Cluster

Execute the cluster installation:

```bash
# Create a final backup of your config
cp install-config.yaml install-config.yaml.bk

# Deploy the cluster with debug logging
openshift-install create cluster --log-level debug
```

> ⏱️ **Installation Time:** The installation typically takes 30-45 minutes. Monitor the output for any issues.

## Post-Installation

### 1. Configure Cluster Access

Set up local access to your new cluster:

```bash
# Create kube config directory
mkdir -p ~/.kube

# Copy cluster config
cp auth/kubeconfig ~/.kube/config

# Verify cluster access
oc whoami
oc get nodes
```

### 2. Monitor Cluster Operators

Watch the cluster operators come online:

```bash
# Monitor cluster operators
watch oc get co

# Check overall cluster status
oc get clusterversion

# View cluster nodes
oc get nodes -o wide
```

### 3. Access the Web Console

1. **Get the console URL:**
   ```bash
   oc whoami --show-console
   ```

2. **Get the kubeadmin password:**
   ```bash
   cat auth/kubeadmin-password
   ```

3. **Access the web console** using the URL and credentials

### 4. Configure Cluster Certificate Trust

Configure the cluster to trust your mirror registry's SSL certificate:

#### Create Certificate ConfigMap
```bash
# Create ConfigMap with registry certificate
oc create configmap registry-config \
  --from-file=$(hostname)..8443=${HOME}/quay-install/quay-rootCA/rootCA.pem \
  -n openshift-config
```

#### Apply Certificate to Cluster
```bash
# Patch cluster image configuration to trust the registry
oc patch image.config.openshift.io/cluster \
  --patch '{"spec":{"additionalTrustedCA":{"name":"registry-config"}}}' \
  --type=merge
```

> 📝 **Note:** This step ensures all cluster nodes trust your mirror registry's self-signed certificate.

### 5. Disable Default Operator Sources

Disable the default OperatorHub sources to ensure operators are pulled from your mirror registry:

```bash
# Disable all default operator sources
oc patch OperatorHub cluster --type json \
  -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
```

> ⚠️ **Important:** This prevents the cluster from attempting to pull operators from external registries.

### 6. Apply Mirror Configuration Resources

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

### 7. Verify Disconnected Operation

Confirm your cluster is using mirrored content:

```bash
# Check image sources
oc get imageDigestMirrorSet

# Check image tag sources  
oc get imageTagMirrorSet

# Verify cluster is pulling from mirror registry
oc describe node | grep -i registry
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Mirror Registry Connection Issues
**Symptoms:** Cannot access registry web interface or authentication fails

**Solutions:**
- Verify firewall allows port 8443 (check iptables/firewalld/security groups)
- Confirm DNS resolution: `nslookup <YOUR-MIRROR-REGISTRY-HOSTNAME>`
- Check certificate trust: `curl -I https://<YOUR-MIRROR-REGISTRY-HOSTNAME>:8443`
- Verify registry is running: `podman ps`

#### 2. Authentication Failures
**Symptoms:** Login failures during mirroring or installation

**Solutions:**
- Verify pull secret format and encoding
- Confirm registry credentials are correct
- Check auth.json file permissions: `chmod 600 ~/.config/containers/auth.json`
- Re-login to registry: `podman login https://<YOUR-MIRROR-REGISTRY-HOSTNAME>:8443`

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
- Check AWS credentials and permissions
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
curl -k https://<YOUR-MIRROR-REGISTRY-HOSTNAME>:8443/v2/
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
./mirror-registry install --quayHostname <YOUR-MIRROR-REGISTRY-HOSTNAME>
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
# Destroy incomplete cluster
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
- [Red Hat Demo Platform](https://catalog.demo.redhat.com/) - AWS environment provisioning
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

# Deploy cluster
openshift-install create cluster --log-level debug

# Access cluster
export KUBECONFIG=auth/kubeconfig
oc get nodes && oc get co
```

### Emergency Contacts
- For technical issues: Red Hat Support Portal
- For demo environment issues: Red Hat Demo Platform support
- For urgent cluster issues: `oc adm must-gather`

---

> 📋 **Note:** This guide provides instructions for lab and development environments. For production deployments, implement additional security measures including proper certificate management, network segmentation, access controls, and backup strategies.

*Last Updated: December 2024*  
*OpenShift Version: 4.19.2*  
*Tested Environment: AWS Demo Platform*
