# OpenShift Disconnected Installation Guide

This guide provides step-by-step instructions for setting up a disconnected OpenShift environment using AWS, including the creation of a mirror registry and mirroring OpenShift content for air-gapped installations.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [AWS Environment Setup](#aws-environment-setup)
3. [Bastion Host Configuration](#bastion-host-configuration)
4. [OpenShift Tools Installation](#openshift-tools-installation)
5. [Mirror Registry Setup](#mirror-registry-setup)
6. [Content Mirroring](#content-mirroring)
7. [Troubleshooting](#troubleshooting)
8. [References](#references)

## Prerequisites

- Access to Red Hat Demo Platform
- Basic understanding of AWS EC2 and networking concepts
- Valid Red Hat account with OpenShift pull secret access
- SSH client for connecting to EC2 instances

## AWS Environment Setup

### 1. Create AWS Demo Environment

Navigate to the Red Hat Demo Platform and provision your AWS environment:

```
https://catalog.demo.redhat.com/catalog?item=babylon-catalog-prod/sandboxes-gpte.sandbox-open.prod&utm_source=webapp&utm_medium=share-link
```

**Configuration Options:**
- **Purpose:** Practice / Enablement
- **Training Type:** Conduct internal training
- **Duration:** Auto-stop, Auto-destroy (1 week)

> ⚠️ **Important:** Keep the demo environment page open for AWS credential access

### 2. AWS Console Access

1. Copy the AWS URL from the demo environment page
2. Open in a new browser window
3. Navigate to the following services (open in new tabs):
   - **EC2:** For instance management
   - **Route53:** For DNS configuration

### 3. Network Infrastructure Setup

Create a default VPC if one doesn't exist:
- Navigate to: [VPC Console - Create Default VPC](https://us-east-2.console.aws.amazon.com/vpc/home?region=us-east-2#CreateDefaultVpc:)
- Click "Create Default VPC"

## Bastion Host Configuration

### 1. Launch EC2 Instance

1. In EC2 Console, click **"Launch Instance"**
2. Configure the following settings:
   - **Name:** `bastion`
   - **OS:** Red Hat Enterprise Linux 9
   - **Instance Type:** `t2.large` (minimum recommended)
   - **Key Pair:** Create new or select existing
   - **Storage:** 500 GB (recommended for mirroring operations)
   - **Network:** Use default VPC and subnet

3. Click **"Launch Instance"**

### 2. Security Group Configuration

Configure security group to allow mirror registry access:

1. Select your bastion instance
2. Navigate to **"Security"** tab
3. Click on the Security Group link
4. Click **"Edit Inbound Rules"**
5. Add the following rule:
   - **Type:** Custom TCP
   - **Port Range:** 8443
   - **Source:** 0.0.0.0/0 (for testing - restrict in production)
6. Click **"Save Rules"**

### 3. DNS Configuration

Set up DNS record for your bastion host:

1. Copy the public IP address from your EC2 instance details
2. Navigate to Route53 console
3. Select your hosted zone (e.g., `sandboxXXX.opentlc.com`)
4. Click **"Create Record"**:
   - **Record Name:** `bastion`
   - **Value:** [Your EC2 Public IP]
5. Click **"Create Records"**

### 4. Connect to Bastion Host

Connect to your RHEL instance via SSH:

```bash
ssh -i ~/.ssh/your-key.pem ec2-user@[BASTION-PUBLIC-IP]
```

### 5. Initial System Setup

Update system and install required packages:

```bash
# Set hostname
sudo hostnamectl hostname bastion.sandboxXXX.opentlc.com

# Install required packages
sudo dnf install -y podman git jq vim wget

# Create working directory
mkdir -p ~/openshift && cd ~/openshift
```

## OpenShift Tools Installation

### 1. Clone Repository

```bash
git clone https://github.com/RedHatGov/oc-mirror-hackathon.git
cd oc-mirror-hackathon
```

### 2. Download OpenShift Binaries

Execute the automated collection script:

```bash
./collect_ocp
```

This script downloads and installs:
- `oc-mirror` - Content mirroring tool
- `openshift-install` - OpenShift installer (v4.19.2)
- `oc` - OpenShift CLI client
- `mirror-registry` - Local container registry
- `butane` - Machine config generation tool

### 3. Verify Installation

Confirm tools are properly installed:

```bash
oc-mirror help
oc version
openshift-install version
```

## Mirror Registry Setup

### 1. Install Mirror Registry

Navigate to the mirror registry directory and run the installer:

```bash
cd ~/oc-mirror-hackathon/mirror-registry
./mirror-registry install \
  --quayHostname bastion.sandboxXXX.opentlc.com \
  --quayRoot /home/ec2-user/registry \
  --quayStorage /home/ec2-user/mirror-storage
```

> 📝 **Important:** Save the generated registry credentials to a secure location

### 2. Trust Registry SSL Certificate

Configure the system to trust the registry's self-signed certificate:

```bash
# Copy certificate to system trust store
sudo cp ~/quay-install/quay-rootCA/rootCA.pem /etc/pki/ca-trust/source/anchors/

# Update certificate trust
sudo update-ca-trust
```

### 3. Configure Authentication

Set up authentication for container operations:

```bash
# Create container config directory
mkdir -p ~/.config/containers

# Download pull secret from console.redhat.com
# Navigate to: https://console.redhat.com/openshift/downloads
# Copy pull secret and save to bastion host

# Configure authentication file (replace with your credentials)
podman login https://bastion.sandboxXXX.opentlc.com:8443 \
  --username init \
  --password [YOUR_REGISTRY_PASSWORD] \
  --authfile ~/.config/containers/auth.json
```

## Content Mirroring

### 1. Mirror OpenShift Content to Local Storage

Execute the mirroring process:

```bash
cd ~/oc-mirror-hackathon/oc-mirror-master/
./oc-mirror.sh
```

This command:
- Uses the `imageset-config.yaml` configuration
- Downloads OpenShift release content
- Stores content locally in the `content/` directory

### 2. Upload Content to Mirror Registry

Transfer mirrored content to your registry:

```bash
./oc-mirror-to-registry.sh
```

> 🔍 **Inspection Points:** While mirroring runs, explore:
> - `.cache/` directory structure
> - `.oc-mirror/` metadata
> - `content/` directory contents
> - `content/working-dir/cluster-resources/` for installation artifacts

### 3. Verify Mirror Content

Check the registry web interface:
- Navigate to: `https://bastion.sandboxXXX.opentlc.com:8443`
- Login with registry credentials
- Verify OpenShift repositories are present

## Preparing for OpenShift Installation

### 1. Generate SSH Key Pair

```bash
ssh-keygen -t ed25519 -C "openshift@bastion"
# Accept defaults for key location and passphrase
```

### 2. Prepare Pull Secret

Extract and format your pull secret for OpenShift installation:

```bash
# View current auth configuration
cat ~/.config/containers/auth.json

# Extract registry-specific auth (example format):
# {"auths": {"bastion.sandboxXXX.opentlc.com:8443": {"auth": "BASE64_ENCODED_CREDENTIALS"}}}
```

### 3. Create Installation Configuration

Run the OpenShift installer configuration wizard:

```bash
openshift-install create install-config
```

**Configuration Parameters:**
- **SSH Public Key:** `~/.ssh/id_ed25519.pub`
- **Platform:** AWS
- **AWS Access Key ID:** [From demo.redhat.com credentials]
- **AWS Secret Access Key:** [From demo.redhat.com credentials]
- **Region:** us-east-1 (or your preferred region)
- **Base Domain:** sandboxXXX.opentlc.com
- **Cluster Name:** ocp
- **Pull Secret:** Your formatted registry authentication JSON

## Troubleshooting

### Common Issues

**Mirror Registry Connection Issues:**
- Verify security group allows port 8443
- Confirm DNS resolution for bastion hostname
- Check certificate trust configuration

**Authentication Failures:**
- Verify pull secret format and encoding
- Confirm registry credentials are correct
- Check auth.json file permissions

**Mirroring Timeouts:**
- Ensure adequate storage space (500GB+)
- Verify network connectivity
- Monitor disk I/O performance

### Log Locations

- Mirror Registry logs: `~/quay-install/`
- oc-mirror logs: `~/.oc-mirror/logs/`
- System logs: `/var/log/messages`

## References

- [oc-mirror Documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/4.12/html/disconnected_installation_mirroring/installing-mirroring-disconnected)
- [OpenShift Disconnected Installation Guide](https://docs.openshift.com/container-platform/latest/installing/disconnected_install/)
- [Mirror Registry Documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/installing/disconnected-installation-mirroring)
- [oc-mirror GitHub Repository](https://github.com/openshift/oc-mirror)

---

> 📋 **Note:** This guide provides instructions for lab and development environments. For production deployments, implement additional security measures including proper certificate management, network segmentation, and access controls.