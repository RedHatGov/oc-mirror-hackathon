# OpenShift Cluster Creation Guide for Disconnected Environments

A comprehensive guide for creating disconnected OpenShift clusters using mirrored content with oc-mirror v2.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Pre-Installation Planning](#pre-installation-planning)
4. [Installation Configuration](#installation-configuration)
5. [Cluster Deployment](#cluster-deployment)
6. [Post-Installation Configuration](#post-installation-configuration)
7. [Verification](#verification)
8. [Troubleshooting](#troubleshooting)
9. [References](#references)

## Overview

This guide walks you through creating a disconnected OpenShift cluster using content mirrored with our standardized `oc-mirror` workflow.

### What You'll Accomplish
- 🔑 **Prepare SSH keys and authentication** for cluster access
- ⚙️ **Configure installation settings** for disconnected deployment
- 🚀 **Deploy OpenShift cluster** using mirrored content
- ✅ **Configure post-installation trust** and operator sources
- 🛠️ **Verify cluster operation** in disconnected mode

## Prerequisites

### Required Access
- Administrative access to your cloud platform (AWS, Azure, GCP, vSphere, etc.)
- SSH access to the bastion/mirror host where mirrored content is available
- Valid Red Hat pull secret merged with mirror registry credentials

### Required Tools
- `openshift-install` binary (version matching your target OpenShift version)
- `oc` CLI tool
- Access to mirrored content created with `oc-mirror` v2
- Platform-specific CLI tools (aws-cli, az cli, gcloud, etc.)

### Technical Requirements
- **Mirror Registry**: Already deployed and containing required OpenShift content
- **Network Connectivity**: Access from cluster nodes to mirror registry
- **DNS Resolution**: Proper hostname resolution for mirror registry
- **Certificate Trust**: Valid certificates or trust bundle for mirror registry

### Mirrored Content Requirements
Before starting cluster installation, ensure you have completed:
- OpenShift release image mirroring for your target version
- Required operator catalog mirroring (if using operators)
- IDMS/ITMS resources generated during mirroring process

## Pre-Installation Planning

### 1. Verify Mirrored Content

**Check Available Content:**
```bash
# Navigate to mirror directory
cd ~/oc-mirror-hackathon/oc-mirror-master

# Verify mirrored content exists
ls -la content/

# Check generated cluster resources
ls -la content/working-dir/cluster-resources/
```

**Verify Mirror Registry Access:**
```bash
# Test registry connectivity
curl -k https://$(hostname):8443/v2/

# Check OpenShift release images
curl -k https://$(hostname):8443/v2/openshift/release-images/tags/list
```

### 2. Platform Preparation

**Generate SSH Key Pair:**
```bash
# Generate SSH key for cluster access
ssh-keygen -t ed25519 -C "openshift@$(hostname)"

# Accept defaults for key location and passphrase
# Verify key generation
ls -la ~/.ssh/id_ed25519*
```

**Prepare Authentication Configuration:**
```bash
# View your current auth configuration
cat ~/.config/containers/auth.json

# Extract registry-specific authentication for install config
# Format needed: {"auths": {"<MIRROR-REGISTRY>:8443": {"auth": "BASE64_CREDENTIALS"}}}

jq -c --arg reg "$(hostname):8443" '
  .auths[$reg].auth as $token
  | {"auths": { ($reg): {"auth": $token} }}
' ~/.config/containers/auth.json
```

**Expected Output:**
```json
{"auths":{"bastion.sandbox762.opentlc.com:8443":{"auth":"dXNlcjpwYXNzd29yZA=="}}}
```

## Installation Configuration

### 1. Create Base Installation Configuration

**Run OpenShift Installer Wizard:**
```bash
# Create install configuration
cd ~/oc-mirror-hackathon/ocp
openshift-install create install-config
```

**Provide Platform Information:**

| Parameter | Example Value | Notes |
|-----------|---------------|-------|
| **SSH Public Key** | `~/.ssh/id_ed25519.pub` | Generated above |
| **Platform** | AWS, Azure, GCP, vSphere, etc. | Your cloud/infrastructure provider |
| **Platform Credentials** | Various | Specific to your cloud provider |
| **Region/Location** | us-east-1, eastus, etc. | Provider-specific region |
| **Base Domain** | sandbox762.opentlc.com | Your DNS domain for the cluster |
| **Cluster Name** | ocp | Descriptive cluster name |
| **Pull Secret** | Registry auth JSON | From your merged auth.json file |

> 📋 **Platform-Specific Setup:** For detailed cloud-specific configuration, refer to the [OpenShift Installation Documentation](https://docs.openshift.com/container-platform/latest/installing/) for your specific platform.

### 2. Configure Disconnected Installation

**Add Image Mirror Sources:**

Edit the installation configuration to include mirror information:
```bash
# Edit the configuration
vi install-config.yaml
```

**Add the imageDigestSources section:**
```yaml
imageDigestSources:
  - mirrors:
    - $(hostname):8443/openshift/release
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
  - mirrors:
    - $(hostname):8443/openshift/release-images
    source: quay.io/openshift-release-dev/ocp-release
```

**Add Additional Trust Bundle:**

Include the registry certificate in the installation configuration:
```bash
# Get the registry certificate
cat ~/quay-install/quay-rootCA/rootCA.pem

# Add the certificate to install-config.yaml
{ echo "additionalTrustBundle: |"; sed 's/^/  /' ~/quay-install/quay-rootCA/rootCA.pem; } >> install-config.yaml
```

**Example Complete install-config.yaml Structure:**
```yaml
apiVersion: v1
baseDomain: sandbox762.opentlc.com
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  platform: {}
  replicas: 3
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  platform: {}
  replicas: 3
metadata:
  creationTimestamp: null
  name: ocp
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 10.0.0.0/16
  networkType: OVNKubernetes
  serviceNetwork:
  - 172.30.0.0/16
platform:
  aws:
    region: us-east-1
pullSecret: '{"auths":{"bastion.sandbox762.opentlc.com:8443":{"auth":"dXNlcjpwYXNzd29yZA=="}}}'
sshKey: |
  ssh-ed25519 AAAAC3Nza... openshift@bastion
imageDigestSources:
  - mirrors:
    - bastion.sandbox762.opentlc.com:8443/openshift/release
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
  - mirrors:
    - bastion.sandbox762.opentlc.com:8443/openshift/release-images
    source: quay.io/openshift-release-dev/ocp-release
additionalTrustBundle: |
  -----BEGIN CERTIFICATE-----
  MIIDNzCCAh+gAwIBAgIBADANBgkqhkiG9w0BAQsFADA...
  -----END CERTIFICATE-----
```

## Cluster Deployment

### 1. Pre-Deployment Validation

**Verify Configuration:**
```bash
# Check configuration syntax
cat install-config.yaml

# Verify SSH key is accessible
cat ~/.ssh/id_ed25519.pub

# Test mirror registry connectivity
curl -k https://$(hostname):8443/v2/openshift/release-images/tags/list
```

### 2. Execute Cluster Installation

**Deploy the Cluster:**
```bash
# Create a backup of your config
cp install-config.yaml install-config.yaml.backup

# Deploy the cluster with debug logging
openshift-install create cluster --log-level debug
```

**Monitor Installation Progress:**
```bash
# Watch installation logs (in another terminal)
tail -f .openshift_install.log

# Monitor installation state
openshift-install wait-for bootstrap-complete
openshift-install wait-for install-complete
```

> ⏱️ **Installation Time:** The installation typically takes 30-45 minutes. Monitor the output for any issues.

**Expected Output Upon Completion:**
```
INFO Install complete!
INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/home/ec2-user/oc-mirror-hackathon/ocp/auth/kubeconfig'
INFO Access the OpenShift web-console here: https://console-openshift-console.apps.ocp.sandbox762.opentlc.com
INFO Login to the console with user: "kubeadmin", and password: "ABC123-def456-GHI789-jkl012"
```

## Post-Installation Configuration

### 1. Configure Cluster Access

**Set up local access to your new cluster:**
```bash
# Set KUBECONFIG environment variable
export KUBECONFIG=~/oc-mirror-hackathon/ocp/auth/kubeconfig

# Create kube config directory
mkdir -p ~/.kube

# Copy cluster config
cp auth/kubeconfig ~/.kube/config

# Verify cluster access
oc whoami
oc get nodes
```

**Example Output:**
```
$ oc whoami
system:admin

$ oc get nodes
NAME                                         STATUS   ROLES                  AGE     VERSION
ip-10-0-142-100.us-east-1.compute.internal   Ready    control-plane,master   8m32s   v1.28.2+...
ip-10-0-161-89.us-east-1.compute.internal    Ready    control-plane,master   8m23s   v1.28.2+...
ip-10-0-180-134.us-east-1.compute.internal   Ready    control-plane,master   8m15s   v1.28.2+...
ip-10-0-200-45.us-east-1.compute.internal    Ready    worker                 4m12s   v1.28.2+...
ip-10-0-214-67.us-east-1.compute.internal    Ready    worker                 4m18s   v1.28.2+...
ip-10-0-230-89.us-east-1.compute.internal    Ready    worker                 4m21s   v1.28.2+...
```

### 2. Monitor Cluster Operators

**Watch cluster operators come online:**
```bash
# Monitor cluster operators
watch oc get co

# Check overall cluster status
oc get clusterversion

# View cluster nodes with details
oc get nodes -o wide
```

### 3. Access the Web Console

**Get Console Access Information:**
```bash
# Get the console URL
oc whoami --show-console

# Get the kubeadmin password
cat auth/kubeadmin-password
```

**Access the web console** using the URL and credentials provided.

### 4. Apply Mirror Configuration Resources

**Apply IDMS and ITMS resources generated during mirroring:**
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

### 5. Configure Additional Cluster Trust

**Create Certificate ConfigMap:**
```bash
# Create ConfigMap with registry certificate
oc create configmap registry-config \
  --from-file=$(hostname)..8443=${HOME}/quay-install/quay-rootCA/rootCA.pem \
  -n openshift-config
```

**Apply Certificate to Cluster:**
```bash
# Patch cluster image configuration to trust the registry
oc patch image.config.openshift.io/cluster \
  --patch '{"spec":{"additionalTrustedCA":{"name":"registry-config"}}}' \
  --type=merge
```

### 6. Disable Default Operator Sources

**Configure OperatorHub for disconnected operation:**
```bash
# Disable all default operator sources
oc patch OperatorHub cluster --type json \
  -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
```

> ⚠️ **Important:** This prevents the cluster from attempting to pull operators from external registries.

## Verification

### 1. Verify Cluster Health

**Check cluster operators:**
```bash
# All operators should be Available=True, Progressing=False, Degraded=False
oc get co

# Check cluster version
oc get clusterversion
```

**Expected Output:**
```
NAME                                       VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE   MESSAGE
authentication                            4.19.2    True        False         False      2m5s    
baremetal                                  4.19.2    True        False         False      8m23s   
cloud-controller-manager                   4.19.2    True        False         False      8m45s   
```

### 2. Verify Mirror Registry Usage

**Check applied mirror resources:**
```bash
# Check IDMS resources
oc get imageDigestMirrorSet

# Check ITMS resources
oc get imageTagMirrorSet

# Check catalog sources
oc get catalogsource -n openshift-marketplace
```

### 3. Verify Disconnected Operation

**Test image pulls from mirror registry:**
```bash
# Check image sources configuration
oc get imageDigestMirrorSet -o yaml

# Verify cluster is pulling from mirror registry
oc describe node | grep -i registry
```

### 4. Test Operator Installation

**Install an operator to verify disconnected functionality:**
```bash
# List available operators (should come from mirror registry)
oc get packagemanifests -n openshift-marketplace

# Install a test operator
oc create -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: cluster-logging
  namespace: openshift-logging
spec:
  channel: stable
  name: cluster-logging
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Installation Failures

**Mirror Registry Connection Issues:**
```bash
# Test connectivity from installer machine
curl -k https://$(hostname):8443/v2/

# Verify certificate trust
openssl s_client -connect $(hostname):8443 -servername $(hostname)

# Check DNS resolution
nslookup $(hostname)
```

**Authentication Problems:**
```bash
# Verify pull secret format
jq . ~/.config/containers/auth.json

# Test registry login
podman login $(hostname):8443

# Check merged pull secret in install-config.yaml
grep -A 10 pullSecret install-config.yaml
```

#### 2. Post-Installation Issues

**Cluster Operators Degraded:**
```bash
# Check specific operator status
oc get co <operator-name> -o yaml

# Check operator pods
oc get pods -n openshift-<operator-namespace>

# Review operator logs
oc logs -n openshift-<namespace> deployment/<operator-deployment>
```

**Image Pull Failures:**
```bash
# Check IDMS/ITMS configuration
oc get imageDigestMirrorSet -o yaml

# Verify registry trust
oc get image.config.openshift.io/cluster -o yaml

# Check registry certificate ConfigMap
oc get configmap registry-config -n openshift-config -o yaml
```

#### 3. Network Connectivity Issues

**Cluster Nodes Cannot Reach Mirror Registry:**
```bash
# Test from cluster node
oc debug node/<node-name>
# Inside debug pod:
chroot /host
curl -k https://$(hostname):8443/v2/
```

### Diagnostic Commands

**System Resources:**
```bash
# Check disk space
df -h

# Check memory usage  
free -h

# Check network connectivity
ping $(hostname)
telnet $(hostname) 8443
```

**OpenShift Specific:**
```bash
# Check cluster events
oc get events --sort-by=.metadata.creationTimestamp

# Check node status
oc describe nodes

# Check cluster network
oc get network.config/cluster -o yaml
```

## References

### Documentation Links
- [OpenShift Installation Documentation](https://docs.openshift.com/container-platform/latest/installing/)
- [Disconnected Installation Guide](https://docs.openshift.com/container-platform/latest/installing/disconnected_install/)
- [Image Registry Configuration](https://docs.openshift.com/container-platform/latest/registry/)

### Related Guides
- [OpenShift Content Mirroring Guide](../setup/oc-mirror-workflow.md)
- [Cluster Upgrade Guide](cluster-upgrade.md)
- [AWS Lab Infrastructure Setup](../setup/aws-lab-infrastructure.md)

### Troubleshooting Resources
- [OpenShift Troubleshooting](https://docs.openshift.com/container-platform/latest/support/troubleshooting/)
- [Installation Troubleshooting](https://docs.openshift.com/container-platform/latest/installing/installing-troubleshooting.html)

---

## Success Checklist

After completing this guide, you should have:

- [ ] ✅ **Deployed OpenShift cluster** using mirrored content
- [ ] ✅ **Configured disconnected operation** with IDMS/ITMS resources
- [ ] ✅ **Verified cluster health** with all operators available
- [ ] ✅ **Tested mirror registry usage** for image pulls
- [ ] ✅ **Disabled external operator sources** for security
- [ ] ✅ **Documented cluster access** credentials and URLs

Your disconnected OpenShift cluster is now ready for production workloads!
