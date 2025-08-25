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
      maxVersion: 4.19.10 
    graph: true
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.19
      packages:
        - name: web-terminal
        - name: cluster-logging
        - name: compliance-operator
  additionalImages: 
    - name: registry.redhat.io/ubi9/ubi:latest
```

**Key Configuration Options:**
- **archiveSize: 8** - Creates 8GB archive chunks for easier transfer
- **platform.graph: true** - Includes Cincinnati graph data (required for upgrades)
- **minVersion/maxVersion** - Controls which OpenShift versions to mirror
- **operators** - Optional operator content to include
- **additionalImages** - Extra container images to mirror

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

## Troubleshooting

### Common Issues

**"Failed to pull image" errors:**
```bash
# Verify Red Hat authentication
podman login registry.redhat.io
# Re-run with explicit authentication
```

**"Insufficient disk space" errors:**
```bash
# Check available space
df -h /
# Clean up unnecessary files or increase storage
```

**Network timeout issues:**
```bash
# Add retry options to oc-mirror command
oc-mirror -c imageset-config.yaml file://content --v2 --max-retry 3
```

### Performance Optimization

**Large environments:**
- Increase `archiveSize` in imageset-config.yaml for faster transfers
- Use `--parallel` flag for concurrent operations
- Run during off-peak hours for better network performance

## Next Steps

After successful mirror-to-disk completion:

1. **Transfer archive** to disconnected environment via approved methods
2. **Use [from-disk-to-registry.md](from-disk-to-registry.md)** to deploy content to target registry
3. **Proceed with OpenShift installation** using mirrored content

## References

- **Related Scripts:** `oc-mirror-master/oc-mirror-to-disk.sh` (tested implementation)
- **Configuration:** `oc-mirror-master/imageset-config.yaml` (working configuration)
- **Complementary Flow:** [from-disk-to-registry.md](from-disk-to-registry.md)
- **Complete Workflow:** [../setup/oc-mirror-workflow.md](../setup/oc-mirror-workflow.md)
