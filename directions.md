# OpenShift Disconnected Installation Complete Guide

A comprehensive step-by-step guide for setting up a disconnected OpenShift environment using AWS, including bastion host setup, mirror registry deployment, content mirroring, and cluster installation.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [AWS Environment Setup](#aws-environment-setup)
4. [Bastion Host Configuration](#bastion-host-configuration)
5. [OpenShift Tools Installation](#openshift-tools-installation)
6. [Mirror Registry Setup](#mirror-registry-setup)
7. [Content Mirroring](#content-mirroring)
8. [OpenShift Installation](#openshift-installation)
9. [Post-Installation](#post-installation)
10. [Troubleshooting](#troubleshooting)
11. [References](#references)

## Overview

This guide walks you through creating a complete disconnected OpenShift installation environment:

- **AWS Infrastructure**: Bastion host with proper networking
- **Mirror Registry**: Local Quay registry for container images
- **Content Mirroring**: OpenShift release images and operators
- **Disconnected Installation**: Air-gapped OpenShift cluster deployment

### What You'll Build
- 🖥️ **Bastion Host**: RHEL 9 instance with all required tools
- 🗃️ **Mirror Registry**: Self-hosted container registry
- 📦 **Mirrored Content**: OpenShift 4.19.2 release and operators
- ☁️ **OpenShift Cluster**: Disconnected cluster using mirrored content

## Prerequisites

### Required Access
- Access to Red Hat Demo Platform
- Valid Red Hat account with OpenShift pull secret access
- SSH client for connecting to EC2 instances
- Basic understanding of AWS EC2 and networking concepts

### Technical Requirements
- AWS Demo Environment (provided via Red Hat Demo Platform)
- 500GB+ storage for mirroring operations
- Stable internet connection for initial content download

## AWS Environment Setup

### 1. Create AWS Demo Environment

Navigate to the Red Hat Demo Platform and provision your AWS environment:

**🔗 Demo Platform URL:**
```
https://catalog.demo.redhat.com/catalog?item=babylon-catalog-prod/sandboxes-gpte.sandbox-open.prod&utm_source=webapp&utm_medium=share-link
```

**Configuration Settings:**
- **Purpose:** Practice / Enablement
- **Training Type:** Conduct internal training  
- **Duration:** Auto-stop, Auto-destroy (1 week)

> ⚠️ **Important:** Keep the demo environment page open for AWS credential access throughout the setup process.

### 2. AWS Console Access

1. **Copy the AWS URL** from the demo environment page
2. **Open in a new browser window**
3. **Navigate to required services** (open each in new tabs):
   - **EC2:** Instance management and configuration
   - **Route53:** DNS configuration for the bastion host

### 3. Network Infrastructure Setup

#### Create Default VPC (if needed)
1. Navigate to: [VPC Console - Create Default VPC](https://us-east-2.console.aws.amazon.com/vpc/home?region=us-east-2#CreateDefaultVpc:)
2. Click **"Create Default VPC"**
3. Wait for creation to complete

## Bastion Host Configuration

### 1. Launch EC2 Instance

#### Instance Configuration
1. In EC2 Console, click **"Launch Instance"**
2. Configure the following settings:

| Setting | Value | Notes |
|---------|-------|-------|
| **Name** | `bastion` | Descriptive name for identification |
| **OS** | Red Hat Enterprise Linux 9 | Latest RHEL version |
| **Instance Type** | `t2.large` | Minimum for mirroring operations |
| **Key Pair** | Create new or select existing | Download and save securely |
| **Storage** | 500 GB | Required for mirroring operations |
| **Network** | Default VPC and subnet | Use created VPC |

3. Click **"Launch Instance"**

### 2. Security Group Configuration

Configure inbound rules to allow mirror registry access:

1. **Select your bastion instance**
2. Navigate to **"Security"** tab
3. **Click on the Security Group** link (usually `launch-wizard-1`)
4. Click **"Edit Inbound Rules"**
5. **Add the following rule:**
   - **Type:** Custom TCP
   - **Port Range:** 8443
   - **Source:** 0.0.0.0/0 (for lab - restrict in production)
6. Click **"Save Rules"**

### 3. DNS Configuration

Set up DNS record for your bastion host:

1. **Copy the public IP address** from your EC2 instance details
2. **Navigate to Route53 console**
3. **Select your hosted zone** (e.g., `sandboxXXX.opentlc.com`)
4. **Click "Create Record"**:
   - **Record Name:** `bastion`
   - **Record Type:** A
   - **Value:** [Your EC2 Public IP]
5. **Click "Create Records"**

### 4. Connect to Bastion Host

#### SSH Connection
```bash
# Replace with your actual key file and IP address
ssh -i ~/.ssh/your-key.pem ec2-user@[BASTION-PUBLIC-IP]

# Alternative: Use the public DNS name
ssh -i ~/.ssh/your-key.pem ec2-user@bastion.sandboxXXX.opentlc.com
```

### 5. Initial System Setup

Once connected to your bastion host, perform initial configuration:

```bash
# Set the hostname (replace XXX with your sandbox number)
sudo hostnamectl hostname bastion.sandboxXXX.opentlc.com

# Install required packages
sudo dnf install -y podman git jq vim wget

# Verify installation
podman --version
git --version
```

## OpenShift Tools Installation

### 1. Clone Repository

```bash
# Clone the hackathon repository
git clone https://github.com/RedHatGov/oc-mirror-hackathon.git
cd oc-mirror-hackathon
```

### 2. Download OpenShift Binaries

Execute the automated collection script:

```bash
# Run the collection script
./collect_ocp
```

**This script downloads and installs:**
- 🔧 **oc-mirror** - Content mirroring tool for disconnected installations
- 🛠️ **openshift-install** - OpenShift cluster installer (v4.19.2)
- 💻 **oc** - OpenShift command-line interface
- 🗃️ **mirror-registry** - Local Quay container registry
- ⚙️ **butane** - Machine configuration generation tool

### 3. Verify Installation

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

# Install mirror registry (replace XXX with your sandbox number)
./mirror-registry install \
  --quayHostname bastion.sandboxXXX.opentlc.com \
  --quayRoot /home/ec2-user/registry \
  --quayStorage /home/ec2-user/mirror-storage
```

> 📝 **Critical:** When the installation completes, **save the generated registry credentials** (username and password) to a secure location. You'll need these for authentication.

### 2. Configure Security Group (During Installation)

While the mirror registry is installing, configure the security group:

1. **Return to your AWS EC2 console**
2. **Click on your bastion instance**
3. **Navigate to "Security" tab**
4. **Click on the Security Group** (usually `launch-wizard-1`)
5. **Click "Edit Inbound Rules"**
6. **Add rule:**
   - **Type:** Custom TCP
   - **Port Range:** 8443
   - **Source:** 0.0.0.0/0
7. **Click "Save Rules"**

### 3. Trust Registry SSL Certificate

Configure the system to trust the registry's self-signed certificate:

```bash
# Copy certificate to system trust store
sudo cp ~/quay-install/quay-rootCA/rootCA.pem /etc/pki/ca-trust/source/anchors/

# Update certificate trust
sudo update-ca-trust

# Verify certificate is trusted
curl -I https://bastion.sandboxXXX.opentlc.com:8443
```

### 4. Configure Authentication

#### Download Red Hat Pull Secret
1. **Navigate to:** [OpenShift Downloads](https://console.redhat.com/openshift/downloads)
2. **Download your pull secret**
3. **Copy the content to your bastion host**

#### Set Up Container Authentication
```bash
# Create container config directory
mkdir -p ~/.config/containers

# Create auth.json file with your Red Hat pull secret
vi ~/.config/containers/auth.json
# Paste your pull secret content here

# Login to your mirror registry (use credentials from installation)
podman login https://bastion.sandboxXXX.opentlc.com:8443 \
  --username init \
  --password [YOUR_REGISTRY_PASSWORD] \
  --authfile ~/.config/containers/auth.json
```

### 5. Verify Registry Access

Test registry access via web browser:
- **Navigate to:** `https://bastion.sandboxXXX.opentlc.com:8443`
- **Login with the credentials** from the installation
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
- Creates cache in `.cache/` directory

> 🔍 **Inspection Points:** While mirroring runs, explore these directories to understand the process:
> - `.cache/` - Downloaded content cache
> - `.oc-mirror/` - Metadata and state information
> - `content/` - Mirrored content ready for upload

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
# Format needed: {"auths": {"bastion.sandboxXXX.opentlc.com:8443": {"auth": "BASE64_ENCODED_CREDENTIALS"}}}
```

### 2. Create Installation Configuration

Run the OpenShift installer configuration wizard:

```bash
# Create install configuration
openshift-install create install-config
```

**Provide the following information:**

| Parameter | Value | Source |
|-----------|-------|--------|
| **SSH Public Key** | `~/.ssh/id_ed25519.pub` | Generated above |
| **Platform** | AWS | Your cloud provider |
| **AWS Access Key ID** | From demo.redhat.com | Demo platform credentials |
| **AWS Secret Access Key** | From demo.redhat.com | Demo platform credentials |
| **Region** | us-east-1 | Or your preferred region |
| **Base Domain** | sandboxXXX.opentlc.com | Your demo environment domain |
| **Cluster Name** | ocp | Descriptive cluster name |
| **Pull Secret** | Registry auth JSON | From your auth.json file |

### 3. Configure Disconnected Installation

#### Add Image Mirror Sources
Edit the installation configuration to include mirror information:

```bash
# Backup the original config
cp install-config.yaml install-config.yaml.backup

# Edit the configuration
vi install-config.yaml
```

**Add the imageDigestSources section:**
```yaml
imageDigestSources:
  - mirrors:
    - bastion.sandboxXXX.opentlc.com:8443/openshift/release
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
  - mirrors:
    - bastion.sandboxXXX.opentlc.com:8443/openshift/release-images
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

### 4. Deploy the Cluster

Execute the cluster installation:

```bash
# Create a final backup of your config
cp install-config.yaml install-config.yaml.final

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

### 4. Verify Disconnected Operation

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
- Verify security group allows port 8443
- Confirm DNS resolution: `nslookup bastion.sandboxXXX.opentlc.com`
- Check certificate trust: `curl -I https://bastion.sandboxXXX.opentlc.com:8443`
- Verify registry is running: `podman ps`

#### 2. Authentication Failures
**Symptoms:** Login failures during mirroring or installation

**Solutions:**
- Verify pull secret format and encoding
- Confirm registry credentials are correct
- Check auth.json file permissions: `chmod 600 ~/.config/containers/auth.json`
- Re-login to registry: `podman login https://bastion.sandboxXXX.opentlc.com:8443`

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
curl -k https://bastion.sandboxXXX.opentlc.com:8443/v2/
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
./mirror-registry install --quayHostname bastion.sandboxXXX.opentlc.com
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
