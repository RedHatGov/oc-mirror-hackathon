# Delete Workflow - Safe Image Deletion

## 🎯 **When to Use This Flow**

- ✅ **Registry Maintenance**: Remove old OpenShift versions to free storage space
- ✅ **Version Lifecycle**: Clean up versions older than current cluster version
- ✅ **Storage Management**: Reclaim registry storage for new content
- ✅ **Compliance**: Meet retention policies for image content
- ❌ **NOT Before Testing**: Ensure target versions are no longer needed
- ❌ **NOT Without Backup**: Consider [Mirror-to-Disk](10-mirror-to-disk.md) backup first

## 📋 **Prerequisites**

Complete [02-shared-prereqs.md](../02-shared-prereqs.md) and export variables from [04-conventions.md](../04-conventions.md).

**Critical Requirement**: Must have original mirror workspace (`$WS`) from initial mirror operations.

## 🔍 **Inputs & Artifacts**

### **Required Inputs:**
- **Original Workspace**: `$WS/working-dir/` with Cincinnati graph data (essential!)
- **Delete Configuration**: `$DELETE_ISC` specifying versions to delete
- **Registry Access**: Authentication with delete permissions
- **Version Plan**: Clear understanding of what to delete vs preserve

### **Generated Artifacts:**
- **Deletion Plan**: `$WS/working-dir/delete/delete-images.yaml` - Reviewable plan
- **Execution Results**: Registry with old versions removed
- **Audit Trail**: Operation logs and deletion records
- **Storage Savings**: Reclaimed registry storage space

## ⚙️ **Two-Phase Safety Process**

The delete workflow uses a **mandatory two-phase approach** for safety:

1. **Phase 1 - Generate (`--generate`)**: Creates reviewable deletion plan (SAFE - no actual deletion)
2. **Phase 2 - Execute (`--delete-yaml-file`)**: Executes reviewed plan (DESTRUCTIVE)

## ⚡ **Procedure**

### **Step 1: Environment Setup**
```bash
# Load canonical variables (from 04-conventions.md)
export REGISTRY_FQDN="$(hostname):8443"
export REGISTRY_DOCKER="docker://$(hostname):8443"
export WS="/srv/oc-mirror/workspace"
export CACHE="$WS/.cache"
export DELETE_ISC="imageset-delete.yaml"

# Validate critical workspace exists
[[ -d "$WS/working-dir" ]] && echo "✅ Original workspace found" || { echo "❌ Original workspace missing - cannot proceed"; exit 1; }

echo "Registry: $REGISTRY_FQDN"
echo "Workspace: $WS"
echo "Delete config: $DELETE_ISC"
```

### **Step 2: Prepare Delete Configuration**
```bash
# Create/review delete configuration
cat > "$DELETE_ISC" << 'EOF'
apiVersion: mirror.openshift.io/v2alpha1
kind: DeleteImageSetConfiguration
delete:
  platform:
    channels:
    - name: stable-4.19
      minVersion: 4.19.2    # Oldest version to delete
      maxVersion: 4.19.6    # Newest version to delete (preserve 4.19.7+)
    graph: true             # Required for platform deletions
  # Note: Not including operators or additionalImages in this example
  # This focuses deletion on OpenShift platform releases only
EOF

echo "Delete configuration created:"
cat "$DELETE_ISC"
echo ""
```

**Critical Configuration Notes:**
- **Version Range**: Only specify versions to DELETE (not to keep)
- **Current Version**: Never include your cluster's current version
- **Future Versions**: Don't include versions you plan to upgrade to
- **Graph Data**: `graph: true` is required for platform deletions

### **Step 3: Pre-Delete Validation**
```bash
echo "=== Pre-Delete Registry Validation ==="

# Show current registry content
echo "Current OpenShift versions in registry:"
curl -sk https://"$REGISTRY_FQDN"/v2/openshift/release-images/tags/list | jq -r '.tags[]' | grep x86_64 | sort -V

# Test access to versions we plan to delete
echo ""
echo "Testing access to versions marked for deletion:"
for version in 4.19.2 4.19.3 4.19.4 4.19.5 4.19.6; do
    if oc adm release info "$REGISTRY_DOCKER/openshift/release-images:${version}-x86_64" >/dev/null 2>&1; then
        echo "✅ $version - present and accessible"
    else
        echo "⚠️ $version - not found or not accessible"
    fi
done

# Confirm preserved versions
echo ""
echo "Testing versions that should be preserved:"
oc adm release info "$REGISTRY_DOCKER/openshift/release-images:4.19.7-x86_64" >/dev/null 2>&1 && echo "✅ 4.19.7 - present and will be preserved" || echo "❌ 4.19.7 - not found (check configuration)"

echo ""
```

### **Step 4: Phase 1 - Generate Deletion Plan**
```bash
# Execute standardized generate script (recommended)
cd oc-mirror-master/
./oc-mirror-delete-generate.sh

# Or execute manually:
oc mirror delete \
    -c "$DELETE_ISC" \
    --generate \
    --workspace file://"$WS" \
    "$REGISTRY_DOCKER" \
    --v2 \
    --cache-dir "$CACHE"
```

**Expected Output:**
```
🗑️ Generating deletion plan for old images...
🎯 Target registry: hostname:8443
📋 Config: imageset-delete.yaml
📁 Workspace: file://workspace (original mirror workspace)
⚠️ SAFE MODE: No deletions will be executed

INFO[0000] Building DeleteImageSetConfiguration from file
INFO[0005] Generating deletion plan...
INFO[0010] Plan generation complete

✅ Deletion plan generated successfully!
📄 Plan saved to: workspace/working-dir/delete/delete-images.yaml
```

### **Step 5: Review Generated Deletion Plan**
```bash
echo "=== DELETION PLAN REVIEW (CRITICAL STEP) ==="

# Display deletion plan summary
DELETION_PLAN="$WS/working-dir/delete/delete-images.yaml"
[[ -f "$DELETION_PLAN" ]] && echo "✅ Deletion plan found" || { echo "❌ Deletion plan not found"; exit 1; }

echo ""
echo "Deletion plan summary:"
echo "📄 Plan file: $DELETION_PLAN"
echo "📊 Images to delete: $(grep -c 'imageName:' "$DELETION_PLAN" || echo 'Unable to count')"
echo "💾 Plan size: $(du -sh "$DELETION_PLAN" 2>/dev/null | cut -f1)"

echo ""
echo "🔍 MANUAL REVIEW REQUIRED:"
echo "Please carefully review the deletion plan:"
echo "less $DELETION_PLAN"
echo ""
echo "Look for:"
echo "- Only intended versions are listed"
echo "- No current/future versions included"
echo "- Reasonable number of images to delete"
echo ""

# Pause for manual review
read -p "Have you reviewed the deletion plan and confirmed it's correct? (yes/no): " plan_reviewed
[[ "$plan_reviewed" == "yes" ]] || { echo "Please review the plan before proceeding."; exit 1; }
```

### **Step 6: Phase 2 - Execute Deletion**
```bash
# Execute standardized deletion script (recommended)
cd oc-mirror-master/
./oc-mirror-delete-execute.sh

# Or execute manually:
oc mirror delete \
    --delete-yaml-file "$DELETION_PLAN" \
    "$REGISTRY_DOCKER" \
    --v2 \
    --cache-dir "$CACHE"
```

**Expected Output:**
```
🚨 DANGER: About to execute image deletion!
🎯 Target registry: hostname:8443
📄 Deletion plan: workspace/working-dir/delete/delete-images.yaml
⚠️ WARNING: This will PERMANENTLY DELETE images from registry!

⏰ FINAL CONFIRMATION REQUIRED
[Interactive confirmation prompt]

🗑️ Executing deletion plan...
📊 This may take several minutes depending on registry size

INFO[0000] Executing deletion plan
INFO[0030] Deleted platform image: 4.19.2-x86_64
INFO[0060] Deleted platform image: 4.19.3-x86_64
...
INFO[0300] Deletion execution completed

✅ Deletion execution completed!
```

## ✅ **Validation**

### **Comprehensive Deletion Validation:**
```bash
validate_deletion() {
    echo "=== DELETION SUCCESS VALIDATION ==="
    
    # Test deleted versions are gone
    echo "🔍 Checking deleted versions:"
    DELETED_VERSIONS="4.19.2 4.19.3 4.19.4 4.19.5 4.19.6"
    for version in $DELETED_VERSIONS; do
        if oc adm release info "$REGISTRY_DOCKER/openshift/release-images:${version}-x86_64" 2>&1 | grep -q "deleted or has expired"; then
            echo "✅ ${version} successfully deleted"
        else
            echo "❌ ${version} still present - deletion may have failed"
        fi
    done
    
    # Test preserved versions still work
    echo ""
    echo "🔍 Checking preserved versions:"
    PRESERVED_VERSIONS="4.19.7"
    for version in $PRESERVED_VERSIONS; do
        if oc adm release info "$REGISTRY_DOCKER/openshift/release-images:${version}-x86_64" >/dev/null 2>&1; then
            echo "✅ ${version} correctly preserved"
        else
            echo "❌ ${version} accidentally deleted or not accessible"
        fi
    done
    
    # Registry still functional
    echo ""
    echo "🔍 Registry functionality check:"
    curl -sk https://"$REGISTRY_FQDN"/v2/ >/dev/null && echo "✅ Registry API functional" || echo "❌ Registry API issues"
    
    # Current version count
    local current_count=$(curl -sk https://"$REGISTRY_FQDN"/v2/openshift/release-images/tags/list | jq -r '.tags[]' | grep -c x86_64 || echo 0)
    echo "📊 Current OpenShift versions in registry: $current_count"
    
    echo "=== Deletion Validation Complete ==="
}

# Run validation
validate_deletion
```

### **Success Criteria:**
- ✅ **Target Versions Deleted**: Specified versions return "deleted or has expired"
- ✅ **Preserved Versions Work**: Non-target versions still accessible
- ✅ **Registry Functional**: API continues to respond correctly
- ✅ **Reasonable Version Count**: Expected number of versions remain
- ✅ **No Accidental Deletion**: Current/future versions preserved

## 🧹 **Post-Deletion Tasks**

### **Registry Garbage Collection (Required):**
```bash
echo "=== REGISTRY GARBAGE COLLECTION ==="
echo "⚠️ IMPORTANT: Run registry garbage collection to reclaim storage space"
echo ""

# For mirror-registry (adjust command for your registry type):
echo "For mirror-registry:"
echo "sudo podman exec -it quay-app registry-garbage-collect"
echo ""

# For Quay Enterprise:
echo "For Quay Enterprise:"
echo "• Log into Quay admin interface"
echo "• Go to Repository Management"
echo "• Run garbage collection from admin panel"
echo ""

# Generic registry:
echo "For other registries:"
echo "• Consult registry documentation for GC procedures"
echo "• GC is required to actually reclaim disk space"
echo ""

# Storage monitoring
echo "Monitor storage reclamation:"
echo "df -h /opt/quay"  # Adjust path for your registry
```

### **Cache Management:**
```bash
echo "=== CACHE MANAGEMENT ==="

# Cache is NOT automatically cleaned during delete operations
CACHE_SIZE=$(du -sh "$CACHE" 2>/dev/null | cut -f1 || echo "Unknown")
echo "Current cache size: $CACHE_SIZE"
echo ""

echo "Cache management options:"
echo "1. Keep cache for performance (recommended for frequent operations)"
echo "2. Clean cache to reclaim space: rm -rf '$CACHE'"
echo "3. Use --force-cache-delete flag in future operations"
echo ""

# Optional cache cleanup
read -p "Clean cache directory now? (yes/no): " clean_cache
if [[ "$clean_cache" == "yes" ]]; then
    rm -rf "$CACHE"
    echo "✅ Cache cleaned - will rebuild automatically on next operation"
fi
```

## 🚀 **Next Steps**

### **Immediate Post-Deletion:**
1. **Registry GC**: Run garbage collection to reclaim storage
2. **Monitor Registry**: Check registry performance and storage usage
3. **Verify Cluster**: Ensure OpenShift cluster operations still work
4. **Document Changes**: Record what was deleted and when

### **Related Workflows:**
- **Add New Content**: [flows/10-mirror-to-disk.md](10-mirror-to-disk.md) - Mirror new versions
- **Cluster Upgrade**: [flows/20-cluster-upgrade.md](20-cluster-upgrade.md) - Upgrade to newer versions
- **Registry Maintenance**: Monitor and optimize registry performance

### **Operational Tasks:**
- **Regular Cleanup**: Schedule periodic old version cleanup
- **Storage Monitoring**: Set up alerts for registry storage usage
- **Backup Strategy**: Consider backup before major deletions

## 💡 **Pro Tips**

### **Safe Deletion Practices:**
```bash
# Always backup critical versions before deletion
oc mirror -c backup-imageset-config.yaml file://backup-workspace --v2

# Test deletion in lab environment first
# Use small version ranges initially
# Always review the generated deletion plan carefully
```

### **Storage Optimization:**
```bash
# Monitor storage before and after
echo "Before deletion: $(df -h /opt/quay | tail -1 | awk '{print $3}')"
# [run deletion and GC]
echo "After deletion: $(df -h /opt/quay | tail -1 | awk '{print $3}')"

# Set up regular cleanup schedules
# Clean versions older than N months
# Coordinate with cluster upgrade schedules
```

### **Troubleshooting Common Issues:**
```bash
# Issue: NoGraphData error during generation
# Solution: Ensure you're using original mirror workspace
[[ -f "$WS/working-dir/hold-release/cincinnati-graph-data.json" ]] && echo "Graph data found" || echo "Graph data missing - use original workspace"

# Issue: Deletion plan is empty
# Solution: Check version ranges in delete configuration
yq eval '.delete.platform.channels[] | .minVersion + " to " + .maxVersion' "$DELETE_ISC"

# Issue: Registry space not reclaimed
# Solution: Run registry garbage collection
sudo podman exec -it quay-app registry-garbage-collect
```

## ⚠️ **Critical Safety Reminders**

### **Before Deletion:**
- ✅ **Backup Strategy**: Consider creating backup archives of content to delete
- ✅ **Cluster Validation**: Ensure cluster doesn't need deleted versions
- ✅ **Team Coordination**: Communicate planned deletions to team members
- ✅ **Lab Testing**: Test deletion process in non-production environment first

### **During Deletion:**
- ✅ **Plan Review**: Always manually review generated deletion plan
- ✅ **Staged Approach**: Delete small batches initially, not everything at once
- ✅ **Monitor Progress**: Watch for errors during execution
- ✅ **Network Stability**: Ensure reliable network during deletion

### **After Deletion:**
- ✅ **Validation**: Verify deleted versions are gone and preserved versions work
- ✅ **Garbage Collection**: Run registry GC to reclaim storage space
- ✅ **Cluster Testing**: Verify cluster operations still function correctly
- ✅ **Documentation**: Record what was deleted for audit trail

---

**🎉 Success!** Old OpenShift versions have been safely removed from your registry, storage space has been reclaimed, and your registry is optimized for current and future operations. The two-phase approach ensures you had full control and visibility over what was deleted.
