# Mirror-to-Registry - Direct Registry Mirroring

## 🎯 **When to Use This Flow**

- ✅ **Semi-Connected Environment**: Registry host has controlled internet access
- ✅ **Direct Operations**: Fastest path from internet to registry
- ✅ **Lab Environments**: Single-host development and testing
- ✅ **Regular Updates**: Environments with reliable internet connectivity
- ❌ **NOT for Airgapped**: Use [Mirror-to-Disk](10-mirror-to-disk.md) → [From-Disk-to-Registry](11-from-disk-to-registry.md)
- ❌ **NOT for High-Security**: Physical air-gap preferred for maximum security

## 📋 **Prerequisites**

Complete [02-shared-prereqs.md](../02-shared-prereqs.md) and export variables from [04-conventions.md](../04-conventions.md).

**Host Role**: This runs on the **Registry Node** with both internet access and registry service.

## 🔍 **Inputs & Artifacts**

### **Required Inputs:**
- **Internet Connectivity**: HTTPS access to Red Hat registries
- **Registry Service**: Running and accessible at `$REGISTRY_FQDN`
- **ImageSet Configuration**: `$ISC` with specific version ranges
- **Authentication**: Valid credentials for both source and target registries
- **Storage Space**: Adequate space for mirrored content (500GB-2TB typical)

### **Generated Artifacts:**
- **Registry Content**: Images directly uploaded and accessible
- **Local Cache**: Performance cache created at `$CACHE`
- **Essential Metadata**: Workspace metadata for future operations
- **Cluster Configuration**: Generated YAML for OpenShift integration

## ⚡ **Procedure**

### **Step 1: Environment Setup**
```bash
# Load canonical variables (from 04-conventions.md)
export REGISTRY_FQDN="$(hostname):8443"
export REGISTRY_DOCKER="docker://$(hostname):8443"
export WS="/srv/oc-mirror/workspace"
export CACHE="$WS/.cache"
export ISC="imageset-config.yaml"

# Create required directories
mkdir -p "$WS" "$(dirname "$CACHE")"

# Validate environment
echo "Target registry: $REGISTRY_FQDN"
echo "Workspace: $WS"
echo "Cache: $CACHE"
echo "Configuration: $ISC"
```

### **Step 2: Network and Authentication Validation**
```bash
# Test internet connectivity to Red Hat registries
echo "=== Network Connectivity Test ==="
curl -s --max-time 10 https://registry.redhat.io/v2/ && echo "✅ registry.redhat.io accessible" || echo "❌ registry.redhat.io not accessible"
curl -s --max-time 10 https://quay.io/v2/ && echo "✅ quay.io accessible" || echo "❌ quay.io not accessible"

# Test local registry connectivity
curl -sk https://"$REGISTRY_FQDN"/v2/ && echo "✅ Local registry accessible" || { echo "❌ Local registry not accessible"; exit 1; }

# Verify authentication to source registries
echo "=== Authentication Test ==="
podman login --get-login registry.redhat.io && echo "✅ Red Hat registry auth" || echo "❌ Red Hat registry auth needed"
podman login --get-login "$REGISTRY_FQDN" && echo "✅ Local registry auth" || { echo "❌ Local registry auth needed"; exit 1; }
```

### **Step 3: Review Configuration**
```bash
# Display and validate ImageSet configuration
echo "=== ImageSet Configuration ==="
cat "$ISC"

# Key validation points:
echo ""
echo "Configuration Checklist:"
echo "- Platform channels defined: $(grep -c 'name:' "$ISC" || echo '0')"
echo "- Graph data included: $(grep -q 'graph: true' "$ISC" && echo 'Yes' || echo 'No - Add graph: true')"
echo "- Version ranges pinned: $(grep -c 'Version:' "$ISC" || echo '0')"
```

**Example Configuration:**
```yaml
apiVersion: mirror.openshift.io/v2alpha1
kind: ImageSetConfiguration
mirror:
  platform:
    channels:
    - name: stable-4.19
      minVersion: 4.19.2    # Pin specific versions
      maxVersion: 4.19.7    # Control scope
    graph: true             # Required for cluster operations
  
  # Optional: Add operators
  operators:
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.19
    packages:
    - name: aws-load-balancer-operator
      channels:
      - name: stable
        minVersion: 1.0.0
```

### **Step 4: Execute Direct Mirror**
```bash
# Display mirror summary before starting
echo "=== Mirror Operation Summary ==="
echo "Source: Internet (Red Hat registries)"
echo "Target: $REGISTRY_FQDN"
echo "Mode: Direct mirror-to-registry"
echo "Expected duration: 30-90 minutes (depending on content scope)"
echo ""

# Confirmation prompt for production environments
read -p "Proceed with direct mirror operation? (yes/no): " confirm
[[ "$confirm" == "yes" ]] || { echo "Operation cancelled."; exit 1; }

# Execute mirror-to-registry
oc mirror -c "$ISC" \
    "$REGISTRY_DOCKER" \
    --v2 \
    --cache-dir "$CACHE"
```

**Expected Output:**
```
INFO[0000] Building ImageSetConfiguration from file
INFO[0005] Successfully retrieved metadata
INFO[0010] Mirroring platform images to registry...
INFO[0015] Processing stable-4.19 channel...
...
INFO[1800] Mirror operation completed successfully
✅ Direct mirror complete!
```

### **Step 5: Verify Registry Content**
```bash
# Test specific release images
OCP_CURRENT="4.19.7"  # Adjust based on your configuration
echo "=== Registry Content Verification ==="

# Check release image accessibility
oc adm release info "$REGISTRY_DOCKER/openshift/release-images:$OCP_CURRENT-x86_64"

# Display available versions
echo "Available release versions:"
curl -sk https://"$REGISTRY_FQDN"/v2/openshift/release-images/tags/list | jq -r '.tags[]' | grep x86_64 | sort -V

# Test image pull capability
podman pull "$REGISTRY_FQDN/openshift/release-images:$OCP_CURRENT-x86_64" --tls-verify=false && echo "✅ Image pull successful"
```

## ✅ **Validation**

### **Comprehensive Registry Validation:**
```bash
validate_mirror_to_registry() {
    echo "=== Mirror-to-Registry Validation ==="
    
    # Test 1: Registry API accessible
    curl -sk https://"$REGISTRY_FQDN"/v2/ >/dev/null && echo "✅ Registry API accessible" || { echo "❌ Registry API failed"; return 1; }
    
    # Test 2: Authentication working
    podman login --get-login "$REGISTRY_FQDN" >/dev/null && echo "✅ Registry authentication valid" || { echo "❌ Authentication failed"; return 1; }
    
    # Test 3: Release images present and accessible
    oc adm release info "$REGISTRY_DOCKER/openshift/release-images:$OCP_CURRENT-x86_64" >/dev/null 2>&1 && echo "✅ Release images accessible" || { echo "❌ Release images not found"; return 1; }
    
    # Test 4: Metadata workspace created
    [[ -d "$WS/working-dir" ]] && echo "✅ Workspace metadata created" || echo "❌ Workspace metadata missing"
    
    # Test 5: Cache created for performance
    [[ -d "$CACHE" ]] && echo "✅ Cache directory created ($(du -sh "$CACHE" 2>/dev/null | cut -f1))" || echo "⚠️ No cache created"
    
    # Test 6: Multiple versions available (if configured)
    local version_count=$(curl -sk https://"$REGISTRY_FQDN"/v2/openshift/release-images/tags/list | jq -r '.tags[]' | grep -c x86_64 || echo 0)
    [[ $version_count -gt 0 ]] && echo "✅ $version_count release versions available" || echo "❌ No release versions found"
    
    # Test 7: Generated cluster configuration
    [[ -f "$WS/working-dir/cluster-resources/"*.yaml ]] && echo "✅ Cluster configuration generated" || echo "⚠️ Check for generated cluster configs"
    
    echo "=== Mirror-to-Registry Validation Complete ==="
}

# Run validation
validate_mirror_to_registry
```

### **Success Criteria:**
- ✅ **Direct Transfer Complete**: All configured content mirrored successfully
- ✅ **Registry Serving Images**: Can pull and inspect release images
- ✅ **Authentication Working**: Registry credentials validated
- ✅ **Workspace Created**: Essential metadata available for future operations
- ✅ **Cache Optimized**: Performance cache created for subsequent operations
- ✅ **Multiple Versions**: All specified version ranges available

### **Performance Metrics:**
```bash
# Check operation performance
echo "=== Performance Metrics ==="
echo "Registry content size: $(df -h /opt/quay 2>/dev/null | tail -1 | awk '{print $3}' || echo 'Unknown')"
echo "Cache size: $(du -sh "$CACHE" 2>/dev/null | cut -f1 || echo 'Unknown')"
echo "Workspace size: $(du -sh "$WS" 2>/dev/null | cut -f1 || echo 'Unknown')"
echo "Available versions: $(curl -sk https://"$REGISTRY_FQDN"/v2/openshift/release-images/tags/list | jq -r '.tags[]' | grep -c x86_64 || echo 0)"
```

### **Common Issues & Quick Fixes:**
```bash
# Issue: Network connectivity failures
# Solution: Check firewall and proxy settings
echo "Testing specific registries:"
curl -v https://registry.redhat.io/v2/ 
curl -v https://quay.io/v2/

# Issue: Authentication errors to Red Hat registries  
# Solution: Update pull secret and re-login
podman login registry.redhat.io
podman login quay.io

# Issue: Local registry space issues
# Solution: Check registry storage
df -h /opt/quay  # Default mirror-registry location
sudo systemctl status quay-app

# Issue: Slow mirror operations
# Solution: Add performance flags
oc mirror -c "$ISC" "$REGISTRY_DOCKER" --v2 \
    --parallel-images 8 --parallel-layers 10 \
    --cache-dir "$CACHE"
```

## 🧹 **Cleanup & Maintenance**

### **Optional Cache Management:**
```bash
# Check cache size and contents
echo "Cache statistics:"
du -sh "$CACHE"
find "$CACHE" -type f | wc -l

# Cache provides performance benefits for future operations
# Only clean if storage space is critically needed
# rm -rf "$CACHE"  # Will rebuild automatically
```

### **Regular Maintenance Tasks:**
```bash
# Monitor registry storage usage
df -h /opt/quay  # Adjust path for your registry

# Check registry service health
systemctl status quay-app  # For mirror-registry
curl -sk https://"$REGISTRY_FQDN"/health/instance

# Plan regular content updates
echo "Next update: Add to cron or automation platform"
echo "Frequency: Weekly/monthly based on OpenShift release schedule"
```

## 🔧 **OpenShift Cluster Integration**

### **Apply Generated Configuration:**
```bash
# Generated cluster configurations are in workspace
echo "Generated cluster configurations:"
find "$WS/working-dir" -name "*.yaml" -type f

# Apply to OpenShift cluster (run these on cluster)
echo "Run these commands on your OpenShift cluster:"
echo ""
echo "# Apply mirror configuration:"
echo "oc apply -f $WS/working-dir/cluster-resources/"
echo ""
echo "# Update global pull secret (if needed):"
echo "oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=merged-pull-secret.json"
```

### **Cluster Validation:**
```bash
# From OpenShift cluster, verify mirror integration
echo "Validate from OpenShift cluster:"
echo "oc get imagecontentsourcepolicy"  # or imagedigestmirrorset
echo "oc debug node/NODE_NAME -- chroot /host podman pull $REGISTRY_FQDN/openshift/release-images:$OCP_CURRENT-x86_64 --tls-verify=false"
```

## 🚀 **Next Steps**

### **Immediate Next Actions:**
1. **Configure Cluster**: Apply generated YAML to OpenShift cluster
2. **Update Pull Secret**: Merge registry credentials with cluster pull secret  
3. **Test Integration**: Verify cluster can pull images from mirror registry

### **Related Workflows:**
- **Cluster Upgrade**: [flows/20-cluster-upgrade.md](20-cluster-upgrade.md) - Upgrade using mirrored content
- **Content Maintenance**: [flows/13-delete.md](13-delete.md) - Clean up old versions  
- **Backup Strategy**: Consider [flows/10-mirror-to-disk.md](10-mirror-to-disk.md) for archive backups

### **Operational Integration:**
- **Automation**: Integrate with CI/CD or automation platform
- **Monitoring**: Set up alerts for registry health and storage
- **Updates**: Schedule regular content updates based on release schedule

## 💡 **Pro Tips**

### **Performance Optimization:**
```bash
# For large environments, optimize parallel operations:
export PARALLEL_IMAGES=16
export PARALLEL_LAYERS=20

oc mirror -c "$ISC" "$REGISTRY_DOCKER" --v2 \
    --parallel-images $PARALLEL_IMAGES \
    --parallel-layers $PARALLEL_LAYERS \
    --cache-dir "$CACHE"
```

### **Network Optimization:**
- **Bandwidth Management**: Monitor network utilization during operations  
- **Scheduling**: Run during off-peak hours for large updates
- **Proxy Configuration**: Configure proxy settings if required in environment

### **Operational Excellence:**
- **Automation**: Script regular updates with appropriate notifications
- **Monitoring**: Implement registry health monitoring and alerting
- **Documentation**: Maintain operational runbooks for registry management

### **Security Considerations:**
```bash
# Enable TLS verification in production
oc mirror -c "$ISC" "$REGISTRY_DOCKER" --v2 \
    --dest-tls-verify=true \
    --src-tls-verify=true \
    --cache-dir "$CACHE"

# Regular credential rotation
podman logout registry.redhat.io
podman logout "$REGISTRY_FQDN"
# Re-login with updated credentials
```

## 🔄 **Advantages vs Other Flows**

### **Mirror-to-Registry Advantages:**
- ✅ **Speed**: Direct transfer, no intermediate storage
- ✅ **Simplicity**: Single operation, no transport steps
- ✅ **Automation**: Easy to integrate with scheduled updates
- ✅ **Resource Efficiency**: No delivery archive storage required

### **Mirror-to-Registry Considerations:**  
- ⚠️ **Network Dependency**: Requires reliable internet during operation
- ⚠️ **Security**: Some internet connectivity required  
- ⚠️ **Recovery**: No physical backup archives created automatically

### **When to Consider Alternatives:**
- **High Security Requirements**: Use [Mirror-to-Disk](10-mirror-to-disk.md) for air-gapped transport
- **Unreliable Connectivity**: Use disk-based flows for better reliability  
- **Compliance Requirements**: Physical air-gap may be mandatory

---

**🎉 Success!** Your OpenShift content is now directly mirrored to the registry and ready for cluster operations. This semi-connected approach provides operational efficiency while maintaining security through controlled internet access. The registry can now serve installations, upgrades, and day-2 operations for your OpenShift environment.
