# OpenShift Cluster Upgrade Guide for Disconnected Environments

A comprehensive guide for upgrading disconnected OpenShift clusters using mirrored content with oc-mirror v2.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Pre-Upgrade Planning](#pre-upgrade-planning)
4. [Mirror Latest Content](#mirror-latest-content)
5. [Cluster Preparation](#cluster-preparation)
6. [Execute Upgrade](#execute-upgrade)
7. [Post-Upgrade Verification](#post-upgrade-verification)
8. [Troubleshooting](#troubleshooting)
9. [References](#references)

## Overview

This guide walks you through upgrading a disconnected OpenShift cluster from **4.19.2 → 4.19.7** using content mirrored with our standardized `oc-mirror` workflow.

### What You'll Accomplish
- 📋 **Pre-upgrade validation** of current cluster state
- 🔄 **Mirror updated content** using our standardized scripts
- ⚡ **Execute cluster upgrade** to target version
- ✅ **Post-upgrade verification** of all components
- 🛠️ **Update client tools** to match cluster version

## Prerequisites

### Required Access
- Administrative access to the OpenShift cluster
- Access to the mirror registry (`bastion.sandbox762.opentlc.com:8443`)
- Valid Red Hat pull secret for downloading updates

### Required Tools
- `oc` CLI tool (current cluster version)
- `oc-mirror` v2 (latest version)
- Access to our standardized mirror scripts

### Technical Requirements
- Sufficient bandwidth for mirroring updates (GB-scale)
- Storage space for new release images and operators
- Network connectivity between bastion and cluster

## Pre-Upgrade Planning

### 1. Review Upgrade Documentation

**Essential Reading:**
- [OCP Cluster Upgrade Graph](https://access.redhat.com/labs/ocpupgradegraph/update_path/) - Plan your upgrade path
- [OpenShift Updating Clusters](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/updating_clusters/index#updating-cluster-cli)
- [Disconnected Environment Updates](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/disconnected_environments/index#updating-disconnected-cluster)

### 2. Verify Current Cluster State

```bash
# Set cluster context
export KUBECONFIG=~/oc-mirror-hackathon/ocp/auth/kubeconfig

# Verify cluster connectivity
oc whoami --show-console

# Check current cluster version
oc get clusterversion
```

**Example Output:**
```
NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
version   4.19.2    True        False         3d      Cluster version is 4.19.2
```

### 3. Identify Current Release Channel

```bash
# Check cluster update channel
oc get clusterversion version -o jsonpath='{.spec.channel}{"\n"}'

# Expected output: stable-4.19
```

## Mirror Latest Content

### 1. Navigate to Mirror Directory

```bash
cd ~/oc-mirror-hackathon/oc-mirror-master
```

### 2. Review Mirror Configuration

```bash
# Check what content will be mirrored
cat imageset-config.yaml
```

**Verify Configuration:**
```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
mirror:
  platform:
    channels:
    - name: stable-4.19
      minVersion: 4.19.2
      maxVersion: 4.19.10  # Ensure target version is included
    graph: true
  operators:
    # Your operator configuration
  additionalImages:
    # Any additional images
```

### 3. Mirror Updated Content

**Use the same mirroring pattern you used to initially hydrate your registry:**

**Option A: Direct Registry Mirroring (Semi-Connected)**
```bash
# Follow the mirror-to-mirror flow for direct updates
echo "🔄 Using mirror-to-mirror pattern for upgrade content..."
```
**➡️ [Follow: mirror-to-mirror.md](../flows/mirror-to-mirror.md)** - Use this if you initially used direct registry mirroring

**Option B: Disk-Based Mirroring (Air-Gapped)**  
```bash
# Follow the two-step disk pattern for air-gapped updates  
echo "📦 Using mirror-to-disk → disk-to-mirror pattern..."
```
**➡️ [Follow: mirror-to-disk.md](../flows/mirror-to-disk.md)** → **[disk-to-mirror.md](../flows/disk-to-mirror.md)** - Use this for air-gapped environments

### 4. Verify Content Update

**Confirm upgrade content is available:**
```bash
# Check content was updated successfully  
ls -la oc-mirror-master/content/working-dir/cluster-resources/

# Verify new IDMS/ITMS were generated
ls -la oc-mirror-master/content/working-dir/cluster-resources/idms-*.yaml
ls -la oc-mirror-master/content/working-dir/cluster-resources/itms-*.yaml
```

## Cluster Preparation

### 1. Verify Available Release Images

**Check Mirror Registry:**
- Navigate to: `https://bastion.sandbox762.opentlc.com:8443`
- Search for: `openshift/release-images`
- Verify **4.19.7** release image is available

**Alternative CLI Method:**
```bash
# List available release images
oc image info --filter-by-os linux/amd64 \
  bastion.sandbox762.opentlc.com:8443/openshift/release-images:4.19.7-x86_64
```

### 2. Validate Upgrade Path

**Using Upgrade Graph:**
1. Visit: [OCP Upgrade Graph Tool](https://access.redhat.com/labs/ocpupgradegraph/update_path/)
2. Enter: **Source Version**: `4.19.2`, **Target Version**: `4.19.7`
3. Verify: Direct upgrade path is supported

### 3. Apply Updated Mirror Configuration

```bash
# Apply updated IDMS/ITMS resources
cd ~/oc-mirror-hackathon/oc-mirror-master

# Apply all cluster resources
oc apply -f content/working-dir/cluster-resources/
```

**Verify Resources:**
```bash
# Check image digest mirror sets
oc get imageDigestMirrorSet

# Check image tag mirror sets  
oc get imageTagMirrorSet

# Verify catalog sources
oc get catalogsource -n openshift-marketplace
```

## Execute Upgrade

### 1. Pause Machine Health Checks

**⚠️ Important:** # READ THE UPGRADE DOCS if, Pause MachineHealthCheck during upgrade to prevent node replacement.

```bash
# List machine health checks
oc get machinehealthcheck -n openshift-machine-api

# Pause all machine health checks
oc patch machinehealthcheck -n openshift-machine-api \
  --type merge --patch '{"spec":{"maxUnhealthy":"100%"}}'
```

### 2. Get Target Release Image Digest

```bash
# Get the exact image digest for 4.19.7
TARGET_IMAGE="bastion.sandbox762.opentlc.com:8443/openshift/release-images:4.19.7-x86_64"

# Get image digest
IMAGE_DIGEST=$(oc image info "$TARGET_IMAGE" -o json | jq -r '.digest')
FULL_IMAGE="$TARGET_IMAGE@$IMAGE_DIGEST"

echo "Target image: $FULL_IMAGE"
```

### 3. Execute Cluster Upgrade

```bash
# Start the cluster upgrade
echo "🚀 Starting cluster upgrade to 4.19.7..."

oc adm upgrade \
  --allow-explicit-upgrade \
  --force=true \
  --to-image="$FULL_IMAGE"
```

**Expected Output:**
```
Updating to 4.19.7

Requested update to 4.19.7
```

### 4. Monitor Upgrade Progress

```bash
# Monitor cluster version status
watch -n 30 "oc get clusterversion"

# Monitor cluster operators
watch -n 30 "oc get co"

# Check upgrade progress details
oc describe clusterversion
watch -n 5 "oc describe clusterversion | grep '^ *Message:'"
```

**Monitor for:**
- `PROGRESSING: True` during upgrade
- `AVAILABLE: True` when complete
- All cluster operators should be `AVAILABLE: True`

## Post-Upgrade Verification

### 1. Verify Cluster Version

```bash
# Confirm new cluster version
oc get clusterversion

# Expected output shows 4.19.7
```

### 2. # READ THE UPGRADE DOCS if, Resume Machine Health Checks

```bash
# Resume normal machine health check behavior
oc patch machinehealthcheck -n openshift-machine-api \
  --type merge --patch '{"spec":{"maxUnhealthy":"40%"}}'
```

### 3. Verify Cluster Operators

```bash
# Check all cluster operators are healthy
oc get co

# All operators should show:
# AVAILABLE: True, PROGRESSING: False, DEGRADED: False
```

### 4. Check Operator Catalog Status

```bash
# Verify operator catalogs are healthy
oc get catalogsource -n openshift-marketplace

# Check for any operator updates needed
```

**Web Console Verification:**
1. Navigate to: **Operators** → **Installed Operators**
2. Verify: All operators show successful upgrade status
3. Update: Any operators requiring manual updates

### 5. Validate Application Workloads

```bash
# Check that applications are running normally
oc get pods --all-namespaces | grep -v Running

# Should show minimal non-Running pods
```

### 6. Update Client Tools

```bash
# Update local OC binaries to match cluster version
cd ~/oc-mirror-hackathon
./collect_ocp

# Verify client version matches cluster
oc version
```

## Troubleshooting

### Common Issues

#### Upgrade Stuck in Progress

**Symptoms:**
- Upgrade shows `PROGRESSING: True` for extended period
- Some cluster operators show `DEGRADED: True`

**Resolution:**
```bash
# Check specific operator issues
oc get co -o wide

# Review operator logs
oc logs -n openshift-cluster-version deployment/cluster-version-operator

# Force operator reconciliation
oc patch clusterversion version --type merge \
  --patch '{"spec":{"overrides":[]}}'
```

#### Image Pull Errors

**Symptoms:**
- Pods failing with `ImagePullBackOff`
- Missing images in mirror registry

**Resolution:**
```bash
# Verify IDMS/ITMS configuration
oc get imageDigestMirrorSet -o yaml

# Re-apply mirror configuration
oc apply -f content/working-dir/cluster-resources/

# Restart affected pods
oc delete pods -l <selector> -n <namespace>
```

#### Node Issues During Upgrade

**Symptoms:**
- Nodes showing `NotReady`
- Machine health checks replacing nodes

**Resolution:**
```bash
# Check node status
oc get nodes

# Verify machine health check pause
oc get machinehealthcheck -n openshift-machine-api -o yaml

# Manually drain and uncordon problematic nodes
oc drain <node-name> --ignore-daemonsets --delete-emptydir-data
oc uncordon <node-name>
```

### Emergency Rollback

**⚠️ Use only in critical situations:**

```bash
# Check available rollback targets
oc adm upgrade

# Rollback to previous version (if available)
oc adm upgrade --to-image=<previous-release-image>
```

## References

### Documentation Links
- [OpenShift Upgrade Graph](https://access.redhat.com/labs/ocpupgradegraph/update_path/)
- [Updating Clusters Guide](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/updating_clusters/)
- [Disconnected Environment Updates](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html-single/disconnected_environments/index#updating-disconnected-cluster)

### Related Guides
- [oc-mirror Workflow Guide](../reference/oc-mirror-workflow.md)
- [Cache Management Guide](../reference/cache-management.md)
- [Collect OCP Tools Guide](collect-ocp.md)

### Support Resources
- Red Hat Customer Portal: [Access Portal](https://access.redhat.com/)
- OpenShift Documentation: [docs.openshift.com](https://docs.openshift.com/)
- Community Support: [OpenShift Commons](https://commons.openshift.org/)

## Next Steps

🎉 **Cluster Upgrade Complete!**

Your OpenShift cluster has been successfully upgraded using mirrored content. You now have old content (4.19.2) that can be safely cleaned up.

### **🗑️ Clean Up Old Content**

**➡️ [Image Deletion Flow](../flows/delete.md)** - Remove old versions (4.19.2) now that 4.19.7 is confirmed working

This completes the full oc-mirror lifecycle: **Mirror → Deploy → Upgrade → Clean Up**

---

**📝 Note:** This guide is specifically tailored for our standardized `oc-mirror` workflow. Adjust paths and registry URLs as needed for your specific environment.
