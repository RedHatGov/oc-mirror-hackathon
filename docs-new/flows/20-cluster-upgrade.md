# Cluster Upgrade - OpenShift Disconnected Upgrades

## 🎯 **When to Use This Flow**

- ✅ **Disconnected Cluster**: OpenShift cluster with no internet access
- ✅ **Mirrored Content Available**: Target versions already mirrored to registry
- ✅ **Planned Upgrade**: Moving from older to newer OpenShift version
- ✅ **Maintenance Window**: Scheduled time for cluster maintenance
- ❌ **NOT for Connected Clusters**: Use standard connected upgrade process
- ❌ **NOT Before Mirroring**: Must have target version mirrored first

## 📋 **Prerequisites**

Complete [02-shared-prereqs.md](../02-shared-prereqs.md) and export variables from [04-conventions.md](../04-conventions.md).

**Essential Requirements:**
- Mirror registry contains target OpenShift version
- Cluster admin access to OpenShift cluster
- Mirror configuration applied to cluster (ICSP/IDMS)

## 🔍 **Inputs & Artifacts**

### **Required Inputs:**
- **Current Cluster**: Running OpenShift cluster at source version
- **Target Version**: Available in mirror registry
- **Mirror Configuration**: ICSP/IDMS applied and working
- **Maintenance Window**: Sufficient time for upgrade process
- **Backup Strategy**: Cluster backup completed if required

### **Generated Artifacts:**
- **Upgraded Cluster**: OpenShift cluster at target version
- **Updated Manifests**: New cluster configuration matching target version
- **Upgrade History**: Documentation of upgrade process and timing
- **Validation Results**: Proof of successful upgrade completion

## 📊 **Example Upgrade Scenario**

This guide demonstrates upgrading from **OpenShift 4.19.2 to 4.19.7** using mirrored content.

**Upgrade Path:** `4.19.2` → `4.19.7`

## ⚡ **Procedure**

### **Step 1: Pre-Upgrade Validation**
```bash
# Load canonical variables
export REGISTRY_FQDN="$(hostname):8443"
export SOURCE_VERSION="4.19.2"
export TARGET_VERSION="4.19.7"

echo "=== Pre-Upgrade Validation ==="
echo "Source version: $SOURCE_VERSION"
echo "Target version: $TARGET_VERSION"
echo "Mirror registry: $REGISTRY_FQDN"
echo ""

# Verify cluster access and current version
oc whoami --show-console
echo "Current cluster version: $(oc get clusterversion -o jsonpath='{.items[0].status.desired.version}')"

# Verify target version available in registry
echo ""
echo "🔍 Verifying target version in registry:"
oc adm release info "$REGISTRY_FQDN/openshift/release-images:$TARGET_VERSION-x86_64" && echo "✅ Target version accessible" || { echo "❌ Target version not available"; exit 1; }

# Check upgrade path validity
echo ""
echo "🔍 Checking upgrade path:"
echo "Use OpenShift upgrade graph to verify path: https://access.redhat.com/labs/ocpupgradegraph/"
echo "Verify: $SOURCE_VERSION → $TARGET_VERSION is supported"
```

### **Step 2: Cluster Health Check**
```bash
echo "=== Cluster Health Validation ==="

# Check cluster operator status
echo "Cluster operator status:"
oc get co --no-headers | awk '{print $1 ": " $3 " " $4 " " $5}' | grep -v "True False False" && echo "⚠️ Some operators not healthy" || echo "✅ All operators healthy"

# Check node status
echo ""
echo "Node status:"
oc get nodes --no-headers | awk '{print $1 ": " $2}' | grep -v "Ready" && echo "⚠️ Some nodes not ready" || echo "✅ All nodes ready"

# Check cluster version status
echo ""
echo "Cluster version status:"
oc get clusterversion -o jsonpath='{.items[0].status.conditions[?(@.type=="Progressing")].status}' | grep -q "False" && echo "✅ No upgrade in progress" || echo "⚠️ Upgrade may be in progress"

# Verify mirror configuration
echo ""
echo "Mirror configuration check:"
ICSP_COUNT=$(oc get imagecontentsourcepolicy --no-headers 2>/dev/null | wc -l)
IDMS_COUNT=$(oc get imagedigestmirrorset --no-headers 2>/dev/null | wc -l)
echo "ImageContentSourcePolicy: $ICSP_COUNT"
echo "ImageDigestMirrorSet: $IDMS_COUNT"
[[ $((ICSP_COUNT + IDMS_COUNT)) -gt 0 ]] && echo "✅ Mirror configuration applied" || echo "❌ No mirror configuration found"
```

### **Step 3: Handle MachineHealthCheck (Critical)**
```bash
echo "=== MachineHealthCheck Management ==="

# List existing MachineHealthChecks
echo "Current MachineHealthChecks:"
oc get machinehealthcheck -A

# Pause MachineHealthChecks during upgrade (prevents node replacement during upgrade)
echo ""
echo "🔧 Pausing MachineHealthChecks during upgrade..."

# Get all MachineHealthChecks and pause them
oc get machinehealthcheck -A -o json | \
  jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name)"' | \
  while read namespace name; do
    echo "Pausing MachineHealthCheck: $namespace/$name"
    oc patch machinehealthcheck "$name" -n "$namespace" \
      -p '{"spec":{"maxUnhealthy":"100%"}}' --type merge
  done

echo "✅ MachineHealthChecks paused (maxUnhealthy set to 100%)"
echo ""
```

### **Step 4: Set Release Image Override**
```bash
echo "=== Release Image Override Configuration ==="

# Configure cluster to use mirror registry for release images
RELEASE_IMAGE="$REGISTRY_FQDN/openshift/release-images:$TARGET_VERSION-x86_64"
echo "Target release image: $RELEASE_IMAGE"

# Apply release image override
oc patch clusterversion version \
  --type merge \
  -p "{\"spec\":{\"overrides\":[{\"kind\":\"Release\",\"group\":\"config.openshift.io\",\"name\":\"cluster\",\"namespace\":\"\",\"unmanaged\":false}]}}"

echo "✅ Release image override configured"
```

### **Step 5: Execute Upgrade**
```bash
echo "=== OpenShift Cluster Upgrade Execution ==="

# Final confirmation
echo "About to upgrade OpenShift cluster:"
echo "  From: $SOURCE_VERSION"
echo "  To: $TARGET_VERSION"
echo "  Registry: $REGISTRY_FQDN"
echo "  Release image: $RELEASE_IMAGE"
echo ""
read -p "Proceed with cluster upgrade? (yes/no): " confirm_upgrade
[[ "$confirm_upgrade" == "yes" ]] || { echo "Upgrade cancelled."; exit 1; }

# Start the upgrade
echo ""
echo "🚀 Starting cluster upgrade..."
oc adm upgrade --to-image="$RELEASE_IMAGE" --allow-explicit-upgrade

echo ""
echo "✅ Upgrade initiated!"
echo "⏳ Upgrade will take 60-120 minutes depending on cluster size"
echo ""
echo "Monitor progress with:"
echo "  oc get clusterversion"
echo "  oc get co"
echo "  oc get nodes"
```

### **Step 6: Monitor Upgrade Progress**
```bash
echo "=== Upgrade Progress Monitoring ==="

# Function to check upgrade status
monitor_upgrade() {
    echo "🔍 Monitoring cluster upgrade progress..."
    echo ""
    
    while true; do
        # Get current version info
        CURRENT_VERSION=$(oc get clusterversion -o jsonpath='{.items[0].status.history[0].version}')
        UPGRADE_STATUS=$(oc get clusterversion -o jsonpath='{.items[0].status.conditions[?(@.type=="Progressing")].status}')
        
        echo "Current version: $CURRENT_VERSION"
        echo "Upgrade status: $UPGRADE_STATUS"
        echo ""
        
        # Check if upgrade is complete
        if [[ "$CURRENT_VERSION" == "$TARGET_VERSION" ]] && [[ "$UPGRADE_STATUS" == "False" ]]; then
            echo "🎉 Upgrade completed successfully!"
            break
        fi
        
        # Show cluster operators status
        echo "Cluster operator status:"
        oc get co --no-headers | awk '{print $1 ": " $3 " " $4 " " $5}' | head -10
        
        # Wait before next check
        echo ""
        echo "⏳ Waiting 5 minutes before next check..."
        sleep 300
    done
}

# Start monitoring (run this in background or separate terminal)
echo "Run this command to monitor upgrade progress:"
echo "bash -c 'monitor_upgrade'"
echo ""
echo "Or manually check status with:"
echo "  oc get clusterversion"
echo "  oc adm upgrade"
```

### **Step 7: Post-Upgrade Validation**
```bash
echo "=== Post-Upgrade Validation ==="

# Verify upgrade completion
echo "🔍 Validating upgrade completion..."

# Check final cluster version
FINAL_VERSION=$(oc get clusterversion -o jsonpath='{.items[0].status.desired.version}')
echo "Final cluster version: $FINAL_VERSION"

[[ "$FINAL_VERSION" == "$TARGET_VERSION" ]] && echo "✅ Version upgrade successful" || echo "❌ Version upgrade incomplete"

# Check all cluster operators
echo ""
echo "Cluster operator validation:"
FAILED_OPERATORS=$(oc get co --no-headers | grep -v "True False False" | wc -l)
[[ $FAILED_OPERATORS -eq 0 ]] && echo "✅ All cluster operators healthy" || echo "❌ $FAILED_OPERATORS operators not healthy"

# Check node status
echo ""
echo "Node status validation:"
NOT_READY_NODES=$(oc get nodes --no-headers | grep -v "Ready" | wc -l)
[[ $NOT_READY_NODES -eq 0 ]] && echo "✅ All nodes ready" || echo "❌ $NOT_READY_NODES nodes not ready"

# Check cluster version conditions
echo ""
echo "Cluster version conditions:"
oc get clusterversion -o jsonpath='{.items[0].status.conditions[?(@.type=="Available")].status}' | grep -q "True" && echo "✅ Cluster available" || echo "❌ Cluster not available"
oc get clusterversion -o jsonpath='{.items[0].status.conditions[?(@.type=="Progressing")].status}' | grep -q "False" && echo "✅ No upgrade in progress" || echo "⚠️ Upgrade still progressing"
```

### **Step 8: Restore MachineHealthCheck**
```bash
echo "=== MachineHealthCheck Restoration ==="

# Restore MachineHealthChecks to normal operation
echo "🔧 Restoring MachineHealthChecks to normal operation..."

# Reset MachineHealthChecks to default behavior
oc get machinehealthcheck -A -o json | \
  jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name)"' | \
  while read namespace name; do
    echo "Restoring MachineHealthCheck: $namespace/$name"
    oc patch machinehealthcheck "$name" -n "$namespace" \
      -p '{"spec":{"maxUnhealthy":"40%"}}' --type merge
  done

echo "✅ MachineHealthChecks restored to normal operation"

# Verify MachineHealthCheck status
echo ""
echo "MachineHealthCheck status:"
oc get machinehealthcheck -A
```

## ✅ **Validation**

### **Comprehensive Upgrade Validation:**
```bash
validate_upgrade() {
    echo "=== COMPREHENSIVE UPGRADE VALIDATION ==="
    
    local validation_passed=0
    local validation_failed=0
    
    # Test 1: Version validation
    local final_version=$(oc get clusterversion -o jsonpath='{.items[0].status.desired.version}')
    if [[ "$final_version" == "$TARGET_VERSION" ]]; then
        echo "✅ Cluster version: $final_version (target achieved)"
        ((validation_passed++))
    else
        echo "❌ Cluster version: $final_version (expected $TARGET_VERSION)"
        ((validation_failed++))
    fi
    
    # Test 2: Cluster operators
    local failed_operators=$(oc get co --no-headers | grep -v "True False False" | wc -l)
    if [[ $failed_operators -eq 0 ]]; then
        echo "✅ Cluster operators: All healthy"
        ((validation_passed++))
    else
        echo "❌ Cluster operators: $failed_operators not healthy"
        ((validation_failed++))
    fi
    
    # Test 3: Node status
    local not_ready_nodes=$(oc get nodes --no-headers | grep -v "Ready" | wc -l)
    if [[ $not_ready_nodes -eq 0 ]]; then
        echo "✅ Nodes: All ready"
        ((validation_passed++))
    else
        echo "❌ Nodes: $not_ready_nodes not ready"
        ((validation_failed++))
    fi
    
    # Test 4: Cluster availability
    if oc get clusterversion -o jsonpath='{.items[0].status.conditions[?(@.type=="Available")].status}' | grep -q "True"; then
        echo "✅ Cluster: Available"
        ((validation_passed++))
    else
        echo "❌ Cluster: Not available"
        ((validation_failed++))
    fi
    
    # Test 5: No upgrade in progress
    if oc get clusterversion -o jsonpath='{.items[0].status.conditions[?(@.type=="Progressing")].status}' | grep -q "False"; then
        echo "✅ Upgrade: Complete (not progressing)"
        ((validation_passed++))
    else
        echo "⚠️ Upgrade: Still in progress"
    fi
    
    # Test 6: Console accessibility
    local console_url=$(oc whoami --show-console)
    if curl -sk "$console_url" >/dev/null 2>&1; then
        echo "✅ Console: Accessible at $console_url"
        ((validation_passed++))
    else
        echo "⚠️ Console: Connectivity check skipped"
    fi
    
    # Test 7: Sample workload functionality
    echo "✅ Sample workload test: Run 'oc new-app --name=test-app registry.access.redhat.com/ubi8/httpd-24' to verify"
    
    echo ""
    echo "📊 VALIDATION SUMMARY:"
    echo "✅ Passed: $validation_passed"
    echo "❌ Failed: $validation_failed"
    
    if [[ $validation_failed -eq 0 ]]; then
        echo ""
        echo "🎉 UPGRADE VALIDATION SUCCESSFUL!"
        echo "OpenShift cluster successfully upgraded to $TARGET_VERSION"
    else
        echo ""
        echo "🚨 UPGRADE VALIDATION ISSUES DETECTED"
        echo "Please investigate failed validation items"
    fi
}

# Run validation
validate_upgrade
```

### **Success Criteria:**
- ✅ **Cluster Version**: Matches target version exactly
- ✅ **All Operators Healthy**: No degraded or unavailable operators
- ✅ **All Nodes Ready**: No nodes in NotReady state
- ✅ **Cluster Available**: Available condition is True
- ✅ **Upgrade Complete**: Progressing condition is False
- ✅ **Console Accessible**: Web console responds correctly
- ✅ **Workloads Function**: Sample applications can be deployed

## 🧹 **Post-Upgrade Tasks**

### **Cleanup and Documentation:**
```bash
echo "=== Post-Upgrade Documentation ==="

# Document successful upgrade
cat > "upgrade-$(date +%Y%m%d).log" << EOF
OpenShift Cluster Upgrade Complete
==================================
Date: $(date)
Source Version: $SOURCE_VERSION
Target Version: $TARGET_VERSION
Registry: $REGISTRY_FQDN
Duration: [Record actual duration]
Issues: [Record any issues encountered]
Resolution: [Record how issues were resolved]

Final Validation:
- Cluster Version: $(oc get clusterversion -o jsonpath='{.items[0].status.desired.version}')
- Node Count: $(oc get nodes --no-headers | wc -l)
- Healthy Operators: $(oc get co --no-headers | grep "True False False" | wc -l)
- Console URL: $(oc whoami --show-console)
EOF

echo "✅ Upgrade documentation saved to upgrade-$(date +%Y%m%d).log"

# Plan next steps
echo ""
echo "📋 Recommended next steps:"
echo "1. Monitor cluster performance for 24-48 hours"
echo "2. Test critical workloads and applications"
echo "3. Update cluster backup (if applicable)"
echo "4. Plan cleanup of old OpenShift versions from registry"
echo "5. Update team documentation and runbooks"
```

## 🚀 **Next Steps**

### **Immediate Post-Upgrade:**
1. **Monitor Cluster**: Watch for any post-upgrade issues or performance problems
2. **Test Applications**: Validate that critical workloads function correctly
3. **Update Documentation**: Record successful upgrade and any lessons learned
4. **Plan Cleanup**: Consider [Delete Workflow](13-delete.md) to remove old versions

### **Related Workflows:**
- **Clean Old Versions**: [flows/13-delete.md](13-delete.md) - Remove old OpenShift versions
- **Mirror New Content**: [flows/10-mirror-to-disk.md](10-mirror-to-disk.md) - Get newer versions
- **Backup Strategy**: Plan regular cluster backups after major upgrades

### **Operational Excellence:**
- **Upgrade Schedule**: Plan regular upgrade cycles aligned with OpenShift releases
- **Testing Strategy**: Develop automated testing for post-upgrade validation
- **Rollback Planning**: Document rollback procedures for future upgrades

## 💡 **Pro Tips**

### **Upgrade Planning:**
```bash
# Always check upgrade paths first
echo "Verify upgrade path at: https://access.redhat.com/labs/ocpupgradegraph/"

# Test in lab environment first
echo "Practice upgrade process in non-production cluster"

# Plan for adequate time
echo "Allow 2-4 hours for complete upgrade process"
```

### **Troubleshooting Common Issues:**
```bash
# Issue: Upgrade stalls or fails
# Solution: Check cluster operator logs
oc logs -n openshift-cluster-version deployment/cluster-version-operator

# Issue: Nodes not ready after upgrade
# Solution: Check node logs and machine config
oc debug node/NODE_NAME
oc get mcp

# Issue: Operators degraded
# Solution: Check specific operator logs
oc get co OPERATOR_NAME -o yaml
oc logs -n OPERATOR_NAMESPACE deployment/OPERATOR_NAME
```

### **Performance Optimization:**
- **Maintenance Window**: Schedule during low-usage periods
- **Network Stability**: Ensure reliable network throughout upgrade
- **Resource Monitoring**: Watch CPU, memory, and storage during upgrade

### **Security Considerations:**
```bash
# Verify security updates included
oc adm release info --commits "$REGISTRY_FQDN/openshift/release-images:$TARGET_VERSION-x86_64"

# Check for security-related operator updates
oc get co -o wide | grep -i security
```

---

**🎉 Success!** Your OpenShift cluster has been successfully upgraded using mirrored content. The cluster is now running the target version with all operators healthy and nodes ready. The disconnected upgrade process ensures your air-gapped environment stays current with OpenShift releases while maintaining security isolation.
