# oc-mirror v2 Image Deletion Guide

A comprehensive guide for safely removing old OpenShift images from mirror registries using oc-mirror v2 deletion capabilities.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Deletion Process](#deletion-process)
4. [Configuration Examples](#configuration-examples)
5. [Safety Considerations](#safety-considerations)
6. [Troubleshooting](#troubleshooting)
7. [Best Practices](#best-practices)

## Overview

oc-mirror v2 provides controlled deletion capabilities to remove outdated images from mirror registries, helping manage storage space and maintain operational efficiency. The deletion process operates in two phases for maximum safety:

1. **Generate Phase**: Create a reviewable deletion plan (safe preview - no actual deletion)
2. **Execute Phase**: Perform actual deletion using the reviewed plan

### Key Features
- 🎯 **Selective Deletion**: Target specific OpenShift versions or operators
- 🔒 **Two-Phase Safety**: Generate plan first, review, then execute
- 📊 **Registry and Cache Cleanup**: Remove from both registry and local cache
- 🏷️ **Signature Support**: Option to delete container signatures
- 🔄 **Version Control**: Use delete-id for tracking deletion operations

## Prerequisites

### Required Tools
- `oc-mirror` v2 (4.19.0 or later)
- Access to target mirror registry
- Valid authentication for registry operations

### Required Permissions
- **Registry**: Push/delete permissions on target registry
- **Local**: Write access to workspace and cache directories
- **Authentication**: Valid auth.json with registry credentials

### Environment Setup
```bash
# Verify oc-mirror v2
oc-mirror --v2 version

# Verify registry access
podman login your-registry.com:8443

# Check authentication file
ls -la ~/.config/containers/auth.json
```

## Deletion Process

### Phase 1: Generate Deletion Plan (Safe Preview)

Create a DeleteImageSetConfiguration file targeting content to delete:

```bash
# Generate deletion plan (safe preview - no actual deletion occurs)
oc mirror delete \
  -c imageset-delete.yaml \
  --generate \
  --workspace file://./delete-workspace \
  docker://your-registry.com:8443 \
  --v2
```

**Required Parameters:**
- `-c`: Path to DeleteImageSetConfiguration file
- `--generate`: Generate deletion plan without executing (this IS the safety mechanism)
- `--workspace`: Workspace directory for generated files (must use file:// prefix)
- `docker://registry`: Target registry URL

### Phase 2: Review Generated Plan

Examine the generated deletion YAML (this is your safety check):

```bash
# Generated deletion plan is located at:
cat ./delete-workspace/working-dir/delete/delete-images.yaml
```

The generated file contains:
- **Manifests to delete**: Specific image manifests with SHA256 digests
- **Blob references**: Image layer blobs to remove from registry storage
- **Registry targets**: Exact registry locations for deletion
- **Cache locations**: Local cache paths to clean

### Phase 3: Execute Deletion

After thoroughly reviewing the generated plan, execute the deletion:

```bash
# Execute deletion using the generated plan
oc mirror delete \
  --delete-yaml-file ./delete-workspace/working-dir/delete/delete-images.yaml \
  docker://your-registry.com:8443 \
  --v2
```

**Optional Flags:**
- `--force-cache-delete`: Force delete local cache contents
- `--delete-signatures`: Remove container image signatures

## Configuration Examples

### Example 1: Remove Old OpenShift Versions

Remove OpenShift versions older than current cluster version:

```yaml
# imageset-delete-old-versions.yaml
apiVersion: mirror.openshift.io/v2alpha1
kind: DeleteImageSetConfiguration
delete:
  platform:
    channels:
    - name: stable-4.19
      minVersion: 4.19.2
      maxVersion: 4.19.6  # Keep 4.19.7+ (current cluster version)
    graph: true
```

### Example 2: Remove Specific Operators

Remove outdated operator versions:

```yaml
# imageset-delete-operators.yaml
apiVersion: mirror.openshift.io/v2alpha1
kind: DeleteImageSetConfiguration
delete:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.18
      packages:
        - name: cluster-logging
        - name: elasticsearch-operator
```

### Example 3: Remove Additional Images

Remove specific additional images:

```yaml
# imageset-delete-additional.yaml
apiVersion: mirror.openshift.io/v2alpha1
kind: DeleteImageSetConfiguration
delete:
  additionalImages:
    - name: registry.redhat.io/ubi8/ubi:8.6
    - name: registry.redhat.io/ubi8/ubi:8.7
```

## Safety Considerations

### ✅ Built-in Safety: Two-Phase Deletion Process

**oc-mirror v2 delete provides excellent safety through its two-phase design:**

- ✅ **Generate phase provides preview** - The `--generate` flag creates a detailed deletion plan WITHOUT executing
- ✅ **Reviewable deletion plan** - All deletions are documented in `delete-images.yaml` before execution  
- ✅ **Forced review step** - You must explicitly use `--delete-yaml-file` to execute
- ✅ **Persistent audit trail** - Generated plans serve as rollback reference
- ✅ **Precise control** - You can review and even modify the deletion plan before execution

**Safety Best Practices:**
1. **Always review the generated plan** before executing deletion
2. **Test deletion configs** in non-production environments first  
3. **Backup critical registries** before major deletions
4. **Save generated plans** for rollback reference and audit compliance

### Pre-Deletion Checklist

Before executing deletions:

- [ ] **Verify cluster compatibility**: Ensure no running clusters need deleted content
- [ ] **Check upgrade paths**: Don't delete versions needed for future upgrades  
- [ ] **Backup registries**: Consider registry backup for rollback capability
- [ ] **Test in staging**: Validate deletion process in non-production environment
- [ ] **Review generated plan**: Carefully examine generated deletion YAML
- [ ] **Coordinate with teams**: Inform relevant teams of deletion plans

### Cluster Impact Assessment

**Before deleting OpenShift versions:**
```bash
# Check current cluster version
oc get clusterversion

# Check upgrade history
oc adm upgrade history

# Verify no clusters using target versions
# (Manual verification required)
```

**Before deleting operators:**
```bash
# Check installed operators
oc get packagemanifests

# Check operator dependencies
oc describe subscription <operator-name> -n openshift-operators
```

## Troubleshooting

### Common Issues

#### 1. Workspace Path Errors
**Error:** `when --workspace is used, it must have file:// prefix`
**Solution:** Always use `file://` prefix for workspace path
```bash
# Correct
--workspace file://./delete-workspace
# Incorrect
--workspace ./delete-workspace
```

#### 2. Missing Delete Files
**Error:** Generated delete files not found
**Solution:** Check workspace directory and delete-id
```bash
# Find generated files
find ./delete-workspace -name "*your-delete-id*" -type f
```

#### 3. Registry Authentication Failures
**Error:** Authentication errors during deletion
**Solution:** Verify registry login and auth file
```bash
# Test registry access
podman login your-registry.com:8443
# Verify auth file
cat ~/.config/containers/auth.json
```

#### 4. Permission Denied Errors
**Error:** Cannot delete from registry
**Solution:** Verify account has delete permissions
```bash
# Test with registry admin account
# Check registry configuration for delete policies
```

### Diagnostic Commands

```bash
# Verify oc-mirror version
oc-mirror --v2 version

# Check workspace contents
ls -la ./delete-workspace/

# Verify registry connectivity
curl -k https://your-registry.com:8443/v2/

# Check local cache
ls -la ~/.oc-mirror/
```

## Best Practices

### 1. Deletion Planning

**Development Workflow:**
1. **Inventory current content** before planning deletions
2. **Plan deletion phases** rather than bulk operations
3. **Test deletion configs** in development first
4. **Document deletion decisions** for audit trail

### 2. Production Safety

**Production Workflow:**
1. **Schedule deletions** during maintenance windows
2. **Coordinate with operations** teams
3. **Backup registries** before major deletions
4. **Monitor cluster health** after deletions
5. **Keep rollback plans** ready

### 3. Storage Management

**Regular Maintenance:**
```bash
# Monthly cleanup workflow
# 1. Remove versions older than N-2 releases
# 2. Remove unused operators
# 3. Clean additional images not in use
# 4. Update deletion configurations
```

### 4. Automation Considerations

**Scripted Deletions:**
```bash
#!/bin/bash
# deletion-workflow.sh

# Step 1: Generate deletion plan
oc-mirror --v2 delete \
  --config imageset-delete.yaml \
  --generate \
  --delete-id "automated-$(date +%Y%m%d)" \
  --workspace file://./delete-workspace

# Step 2: Review (manual checkpoint)
echo "Review generated plan before continuing..."
read -p "Press enter to continue with deletion..."

# Step 3: Execute deletion
oc-mirror --v2 delete \
  --delete-yaml-file ./delete-workspace/delete-automated-*.yaml
```

### 5. Monitoring and Validation

**Post-Deletion Verification:**
```bash
# Verify registry content
podman search your-registry.com:8443/

# Check available images
oc adm release info your-registry.com:8443/openshift/release-images:4.19.7-x86_64

# Validate cluster operations
oc get nodes
oc get co
```

## Command Reference

### Essential Commands

```bash
# Generate deletion plan (safe preview)
oc mirror delete -c <config> --generate --workspace file://<path> docker://<registry> --v2

# Execute deletion using generated plan
oc mirror delete --delete-yaml-file <workspace>/working-dir/delete/delete-images.yaml docker://<registry> --v2

# Force cache deletion
oc mirror delete --delete-yaml-file <workspace>/working-dir/delete/delete-images.yaml --force-cache-delete docker://<registry> --v2

# Delete with signatures
oc mirror delete --delete-yaml-file <workspace>/working-dir/delete/delete-images.yaml --delete-signatures docker://<registry> --v2
```

### Advanced Options

```bash
# Custom cache directory
oc-mirror --v2 delete --cache-dir /custom/cache --config <config> --generate

# Custom authentication
oc-mirror --v2 delete --authfile /custom/auth.json --config <config> --generate

# Verbose logging
oc-mirror --v2 delete --log-level debug --config <config> --generate
```

---

## Quick Start Example

Ready to delete old OpenShift versions? Here's a complete workflow:

```bash
# 1. Create configuration
cat > imageset-delete.yaml << EOF
apiVersion: mirror.openshift.io/v2alpha1
kind: DeleteImageSetConfiguration
delete:
  platform:
    channels:
    - name: stable-4.19
      minVersion: 4.19.2
      maxVersion: 4.19.6  # Delete versions older than 4.19.7
    graph: true
EOF

# 2. Generate deletion plan (safe preview)
oc mirror delete \
  -c imageset-delete.yaml \
  --generate \
  --workspace file://./delete-workspace \
  docker://your-registry.com:8443 \
  --v2

# 3. Review generated plan (IMPORTANT SAFETY STEP)
cat ./delete-workspace/working-dir/delete/delete-images.yaml

# 4. Execute deletion (only after thorough review)
oc mirror delete \
  --delete-yaml-file ./delete-workspace/working-dir/delete/delete-images.yaml \
  docker://your-registry.com:8443 \
  --v2

echo "✅ Deletion completed successfully!"
```

---

**⚠️ Remember**: Always test deletion operations in non-production environments first and ensure you have proper backups and rollback procedures in place.

**✅ Safety Design**: oc-mirror v2 delete provides excellent safety through its two-phase approach - the `--generate` phase serves as a comprehensive preview mechanism.
