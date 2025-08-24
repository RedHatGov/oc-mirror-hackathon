# Post-Done Validation Checklist

## 🎯 **Success Validation After Workflow Completion**

Use this checklist to confirm successful completion of any oc-mirror workflow. This is your "Done Gate" to verify operations worked correctly.

## ✅ **Universal Success Criteria (All Workflows)**

### **Basic Operation Validation:**
```bash
echo "🔍 UNIVERSAL SUCCESS VALIDATION"
echo "================================"

# Load canonical variables
export REGISTRY_FQDN="${REGISTRY_FQDN:-$(hostname):8443}"
export WS="${WS:-/srv/oc-mirror/workspace}"

# Registry accessibility
curl -sk https://"$REGISTRY_FQDN"/v2/ >/dev/null && echo "✅ Registry API accessible" || echo "❌ Registry API failed"

# Authentication still valid
podman login --get-login "$REGISTRY_FQDN" >/dev/null 2>&1 && echo "✅ Registry authentication valid" || echo "❌ Registry authentication expired"

# Workspace metadata preserved
[[ -d "$WS/working-dir" ]] && echo "✅ Workspace metadata preserved" || echo "❌ Workspace metadata missing"

echo ""
```

**Universal Requirements:**
- [ ] **Registry Accessible**: API endpoint responds correctly
- [ ] **Authentication Valid**: Registry credentials still working
- [ ] **Essential Metadata**: Workspace `working-dir/` preserved
- [ ] **No Critical Errors**: Operation logs show successful completion

## ✅ **Mirror-to-Disk Validation**

### **Delivery Package Validation:**
```bash
if [[ "$WORKFLOW" == "mirror-to-disk" ]]; then
    echo "📦 MIRROR-TO-DISK SUCCESS VALIDATION"
    echo "===================================="
    
    export DEL_ROOT="${DEL_ROOT:-/srv/oc-mirror/deliveries}"
    LATEST_DELIVERY=$(ls -t "$DEL_ROOT" | head -1)
    DELIVERY_DIR="$DEL_ROOT/$LATEST_DELIVERY"
    
    echo "Latest delivery: $LATEST_DELIVERY"
    
    # Archives created
    ARCHIVE_COUNT=$(ls "$DELIVERY_DIR"/mirror_*.tar 2>/dev/null | wc -l)
    [[ $ARCHIVE_COUNT -gt 0 ]] && echo "✅ $ARCHIVE_COUNT delivery archives created" || echo "❌ No delivery archives found"
    
    # Checksums valid
    cd "$DELIVERY_DIR"
    sha256sum -c checksums.sha256 >/dev/null 2>&1 && echo "✅ Archive checksums validated" || echo "❌ Checksum validation failed"
    
    # Configuration included
    [[ -f imageset-config.yaml ]] && echo "✅ Configuration included in delivery" || echo "❌ Configuration missing from delivery"
    
    # Reasonable sizes
    TOTAL_SIZE=$(du -sh mirror_*.tar 2>/dev/null | awk '{sum+=$1} END {print sum}')
    [[ -n "$TOTAL_SIZE" ]] && echo "✅ Total archive size: ${TOTAL_SIZE}B" || echo "⚠️ Cannot determine archive size"
    
    echo ""
fi
```

**Mirror-to-Disk Success Criteria:**
- [ ] **Archives Created**: Multiple `mirror_*.tar` files in delivery directory
- [ ] **Checksums Valid**: SHA256 verification passes for all archives
- [ ] **Configuration Present**: `imageset-config.yaml` included in delivery
- [ ] **Reasonable Size**: Archives have expected size (not zero bytes)
- [ ] **Ready for Transport**: Delivery package complete and validated

## ✅ **From-Disk-to-Registry / Mirror-to-Registry Validation**

### **Registry Content Validation:**
```bash
if [[ "$WORKFLOW" =~ "registry" ]]; then
    echo "🏭 REGISTRY CONTENT SUCCESS VALIDATION"  
    echo "====================================="
    
    # Set expected version (adjust based on your configuration)
    export OCP_CURRENT="${OCP_CURRENT:-4.19.7}"
    
    # Release images accessible
    oc adm release info "$REGISTRY_FQDN/openshift/release-images:$OCP_CURRENT-x86_64" >/dev/null 2>&1 && echo "✅ Release images accessible" || echo "❌ Release images not accessible"
    
    # Multiple versions available
    VERSION_COUNT=$(curl -sk https://"$REGISTRY_FQDN"/v2/openshift/release-images/tags/list 2>/dev/null | jq -r '.tags[]' 2>/dev/null | grep -c x86_64 2>/dev/null || echo 0)
    [[ $VERSION_COUNT -gt 0 ]] && echo "✅ $VERSION_COUNT release versions available" || echo "❌ No release versions found"
    
    # Image pull test
    podman pull "$REGISTRY_FQDN/openshift/release-images:$OCP_CURRENT-x86_64" --tls-verify=false >/dev/null 2>&1 && echo "✅ Image pull test successful" || echo "❌ Image pull test failed"
    
    # Generated cluster configuration
    [[ -f "$WS/working-dir/cluster-resources/"*.yaml ]] && echo "✅ Cluster configuration generated" || echo "⚠️ Check for cluster configuration files"
    
    # Display available versions
    echo "Available OpenShift versions:"
    curl -sk https://"$REGISTRY_FQDN"/v2/openshift/release-images/tags/list 2>/dev/null | jq -r '.tags[]' 2>/dev/null | grep x86_64 | sort -V | tail -5
    
    echo ""
fi
```

**Registry Success Criteria:**
- [ ] **Release Images Accessible**: Can query and inspect release images
- [ ] **Multiple Versions**: All configured version ranges available
- [ ] **Image Pull Works**: Can successfully pull images from registry
- [ ] **Cluster Config Generated**: YAML files available for cluster application
- [ ] **Expected Versions Present**: All specified versions in registry

## ✅ **Delete Workflow Validation**

### **Deletion Success Validation:**
```bash
if [[ "$WORKFLOW" == "delete" ]]; then
    echo "🗑️ DELETE WORKFLOW SUCCESS VALIDATION"
    echo "===================================="
    
    # Set versions that should be deleted (adjust based on your delete config)
    DELETED_VERSIONS="4.19.2 4.19.3 4.19.4 4.19.5 4.19.6"
    PRESERVED_VERSION="4.19.7"
    
    echo "Testing deletion of versions: $DELETED_VERSIONS"
    echo "Testing preservation of version: $PRESERVED_VERSION"
    echo ""
    
    # Check deleted versions are gone
    for version in $DELETED_VERSIONS; do
        if oc adm release info "$REGISTRY_FQDN/openshift/release-images:${version}-x86_64" 2>&1 | grep -q "deleted or has expired"; then
            echo "✅ $version successfully deleted"
        else
            echo "❌ $version still present (deletion failed)"
        fi
    done
    
    # Check preserved versions still work
    oc adm release info "$REGISTRY_FQDN/openshift/release-images:${PRESERVED_VERSION}-x86_64" >/dev/null 2>&1 && echo "✅ $PRESERVED_VERSION preserved correctly" || echo "❌ $PRESERVED_VERSION accidentally deleted"
    
    # Check deletion plan was generated
    [[ -f "$WS/working-dir/delete/delete-images.yaml" ]] && echo "✅ Deletion plan preserved" || echo "⚠️ Deletion plan not found"
    
    echo ""
fi
```

**Delete Success Criteria:**
- [ ] **Target Versions Deleted**: Specified versions return "deleted or has expired"
- [ ] **Preserved Versions Work**: Non-target versions still accessible
- [ ] **Deletion Plan Preserved**: Generated deletion YAML available for audit
- [ ] **Registry Functional**: Registry continues to serve remaining content

## ✅ **OpenShift Cluster Integration Validation**

### **Cluster Configuration Applied:**
```bash
echo "🔗 OPENSHIFT CLUSTER INTEGRATION VALIDATION"
echo "==========================================="

# Check cluster access
oc whoami >/dev/null 2>&1 && echo "✅ OpenShift cluster access" || echo "❌ No OpenShift cluster access"

# Check mirror configuration applied (ICSP or IDMS)
ICSP_COUNT=$(oc get imagecontentsourcepolicy 2>/dev/null | grep -v NAME | wc -l)
IDMS_COUNT=$(oc get imagedigestmirrorset 2>/dev/null | grep -v NAME | wc -l)
MIRROR_CONFIG_COUNT=$((ICSP_COUNT + IDMS_COUNT))

[[ $MIRROR_CONFIG_COUNT -gt 0 ]] && echo "✅ Mirror configuration applied ($ICSP_COUNT ICSP, $IDMS_COUNT IDMS)" || echo "⚠️ No mirror configuration found (may need manual application)"

# Test cluster can resolve mirror registry
oc debug node/$(oc get nodes -o jsonpath='{.items[0].metadata.name}') -- chroot /host nslookup "$REGISTRY_FQDN" >/dev/null 2>&1 && echo "✅ Cluster can resolve mirror registry" || echo "⚠️ Cluster DNS resolution check skipped"

# Check global pull secret includes registry
oc get secret/pull-secret -n openshift-config -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq -r '.auths | keys[]' | grep -q "$REGISTRY_FQDN" && echo "✅ Registry in global pull secret" || echo "⚠️ Registry not in global pull secret (may need manual update)"

echo ""
```

**Cluster Integration Success Criteria:**
- [ ] **Mirror Config Applied**: ICSP or IDMS resources present in cluster
- [ ] **Pull Secret Updated**: Registry credentials in global pull secret
- [ ] **DNS Resolution**: Cluster can resolve registry hostname
- [ ] **Node Access**: Cluster nodes can reach registry service

## ✅ **Performance & Resource Validation**

### **System Resource Check:**
```bash
echo "📊 PERFORMANCE & RESOURCE VALIDATION"
echo "===================================="

# Registry storage usage
REGISTRY_PATH="/opt/quay"  # Adjust for your registry
[[ -d "$REGISTRY_PATH" ]] && echo "Registry storage used: $(du -sh "$REGISTRY_PATH" 2>/dev/null | cut -f1)" || echo "⚠️ Registry path not found"

# Cache statistics
CACHE_PATH="$WS/.cache"
[[ -d "$CACHE_PATH" ]] && echo "Cache size: $(du -sh "$CACHE_PATH" 2>/dev/null | cut -f1)" || echo "⚠️ No cache directory found"

# Workspace usage
[[ -d "$WS" ]] && echo "Workspace size: $(du -sh "$WS" 2>/dev/null | cut -f1)" || echo "⚠️ Workspace not found"

# Available space
echo "Available space:"
df -h "$WS" "$REGISTRY_PATH" 2>/dev/null | grep -v Filesystem

# Registry service health
systemctl is-active quay-app >/dev/null 2>&1 && echo "✅ Registry service healthy" || echo "⚠️ Registry service status unknown"

echo ""
```

**Resource Success Criteria:**
- [ ] **Registry Storage**: Adequate space remaining (20%+ free recommended)
- [ ] **Cache Size**: Reasonable cache size created (performance optimization)  
- [ ] **Service Health**: Registry service running and responsive
- [ ] **System Performance**: No resource exhaustion or performance issues

## 🚀 **Complete Success Validation Script**

### **Run All Validations:**
```bash
#!/bin/bash
# Complete post-operation validation

echo "🎉 COMPLETE WORKFLOW SUCCESS VALIDATION"
echo "======================================="

# Set workflow type (adjust based on what you just completed)
export WORKFLOW="${WORKFLOW:-registry}"  # Options: mirror-to-disk, registry, delete

# Load canonical variables
export REGISTRY_FQDN="${REGISTRY_FQDN:-$(hostname):8443}"
export WS="${WS:-/srv/oc-mirror/workspace}"
export OCP_CURRENT="${OCP_CURRENT:-4.19.7}"

# Count validation results
PASSED=0
FAILED=0
WARNINGS=0

check_result() {
    local result=$?
    local success_msg="$1"
    local fail_msg="$2"
    
    if [[ $result -eq 0 ]]; then
        echo "✅ $success_msg"
        ((PASSED++))
    else
        echo "❌ $fail_msg"
        ((FAILED++))
    fi
}

warning_check() {
    local test_cmd="$1"
    local success_msg="$2"
    local warn_msg="$3"
    
    if eval "$test_cmd" >/dev/null 2>&1; then
        echo "✅ $success_msg"
        ((PASSED++))
    else
        echo "⚠️ $warn_msg"
        ((WARNINGS++))
    fi
}

echo "Validating workflow: $WORKFLOW"
echo "Registry: $REGISTRY_FQDN"
echo "Workspace: $WS"
echo ""

# Universal checks
curl -sk https://"$REGISTRY_FQDN"/v2/ >/dev/null
check_result "Registry API accessible" "Registry API not responding"

podman login --get-login "$REGISTRY_FQDN" >/dev/null 2>&1
check_result "Registry authentication valid" "Registry authentication failed"

[[ -d "$WS/working-dir" ]]
check_result "Workspace metadata preserved" "Workspace metadata missing"

# Workflow-specific checks
if [[ "$WORKFLOW" =~ "registry" ]]; then
    oc adm release info "$REGISTRY_FQDN/openshift/release-images:$OCP_CURRENT-x86_64" >/dev/null 2>&1
    check_result "Release images accessible" "Release images not accessible"
fi

echo ""
echo "📊 VALIDATION SUMMARY"
echo "===================="
echo "✅ Passed: $PASSED"
echo "❌ Failed: $FAILED"  
echo "⚠️ Warnings: $WARNINGS"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo "🎉 WORKFLOW SUCCESSFULLY COMPLETED!"
    echo ""
    echo "Your oc-mirror operation completed successfully."
    echo "All critical validations passed."
    if [[ $WARNINGS -gt 0 ]]; then
        echo "Review warnings above - they don't block success but may need attention."
    fi
    echo ""
    echo "Next steps:"
    echo "• Apply generated cluster configurations (if applicable)"
    echo "• Plan maintenance and cleanup operations"
    echo "• Document successful completion"
else
    echo "🚨 WORKFLOW COMPLETION ISSUES DETECTED"
    echo ""
    echo "Please investigate and resolve the failed items."
    echo "The operation may not have completed successfully."
    echo ""
    echo "Troubleshooting:"
    echo "• Check operation logs for specific errors"
    echo "• Verify network connectivity and authentication"
    echo "• Consult [references/troubleshooting.md] for common issues"
fi
```

## 💡 **Workflow-Specific Next Steps**

### **After Mirror-to-Disk Success:**
1. **Transport Archives**: Securely move delivery package to Registry Node
2. **Verify Transport**: Validate checksums after transport
3. **Deploy Content**: Run [From-Disk-to-Registry](../flows/11-from-disk-to-registry.md)

### **After Registry Upload Success:**  
1. **Apply Cluster Config**: Use generated YAML on OpenShift cluster
2. **Update Pull Secret**: Merge registry credentials with cluster pull secret
3. **Test Cluster Integration**: Verify cluster can pull from mirror registry
4. **Plan Maintenance**: Schedule regular content updates and cleanup

### **After Delete Success:**
1. **Registry Cleanup**: Run registry garbage collection to reclaim storage
2. **Verify Cluster**: Ensure cluster operations still work with remaining images
3. **Update Documentation**: Record what was deleted and when
4. **Monitor Performance**: Check that registry performance improved

### **After Any Success:**
1. **Archive Logs**: Save operation logs for audit and troubleshooting
2. **Update Inventory**: Document current state of mirrored content
3. **Plan Next Operation**: Schedule regular maintenance and updates
4. **Share Success**: Document lessons learned for team knowledge

## 🧹 **Post-Success Cleanup**

### **Safe Cleanup Operations:**
```bash
# Clean temporary files (safe)
rm -f /tmp/oc-mirror-*.log
rm -f "$WS"/*.tmp

# Archive successful delivery (mirror-to-disk only)
# mv "$DELIVERY_DIR" "$ARCHIVE_ROOT/"

# Optional: Clean cache if space needed (will rebuild automatically)
# rm -rf "$WS/.cache"

# Clean old archives (after retention period)
# find "$ARCHIVE_ROOT" -type d -mtime +90 -exec rm -rf {} \;
```

### **DO NOT DELETE:**
- ❌ **`$WS/working-dir/`** - Essential metadata for all future operations
- ❌ **Registry Content** - Images serving OpenShift clusters  
- ❌ **Current Delivery** - Until successfully deployed to registry
- ❌ **Configuration Files** - Needed for audit and repeatability

---

**🎉 Validation Complete!** If all critical checks pass, your oc-mirror workflow completed successfully and your environment is ready for the next phase of operations.

**Issues Found?** Use [references/troubleshooting.md](../references/troubleshooting.md) to diagnose and resolve any problems before proceeding.
