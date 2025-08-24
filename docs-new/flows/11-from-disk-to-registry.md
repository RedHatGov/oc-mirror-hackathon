# From-Disk-to-Registry - Deploy Archives to Registry

## 🎯 **When to Use This Flow**

- ✅ **Deployment Phase**: After [Mirror-to-Disk](10-mirror-to-disk.md) on disconnected Registry Node
- ✅ **Airgapped Registry**: Registry host has no internet connectivity  
- ✅ **Archive Upload**: Deploying portable delivery archives
- ✅ **Disaster Recovery**: Restoring mirror content from backup archives
- ❌ **NOT for First Step**: Must have delivery archives from mirror-to-disk
- ❌ **NOT for Semi-Connected**: Use [Mirror-to-Registry](12-mirror-to-registry.md) instead

## 📋 **Prerequisites**

Complete [02-shared-prereqs.md](../02-shared-prereqs.md) and export variables from [04-conventions.md](../04-conventions.md).

**Host Role**: This runs on the **Registry Node** (disconnected system with registry service).

## 🔍 **Inputs & Artifacts**

### **Required Inputs:**
- **Delivery Archives**: From [Mirror-to-Disk](10-mirror-to-disk.md) workflow
- **Registry Service**: Running and accessible at `$REGISTRY_FQDN`
- **Authentication**: Valid registry credentials with push permissions
- **Storage Space**: 2x archive size free space during upload

### **Generated Artifacts:**
- **Registry Content**: Images uploaded and accessible
- **Fresh Cache**: Local cache created as needed
- **Applied Configuration**: Cluster resources ready for deployment
- **Upload Logs**: Operation audit trail

## ⚡ **Procedure**

### **Step 1: Environment Setup**
```bash
# Load canonical variables (from 04-conventions.md)
export REGISTRY_FQDN="$(hostname):8443"
export REGISTRY_DOCKER="docker://$(hostname):8443"
export DEL_ROOT="/srv/oc-mirror/deliveries"
export CACHE="/srv/oc-mirror/workspace/.cache"

# Validate registry accessibility  
curl -sk https://"$REGISTRY_FQDN"/v2/ && echo "✅ Registry accessible" || { echo "❌ Registry not accessible"; exit 1; }

# Check authentication
podman login --get-login "$REGISTRY_FQDN" && echo "✅ Registry authentication valid" || { echo "❌ Registry authentication failed"; exit 1; }
```

### **Step 2: Locate and Validate Delivery**
```bash
# List available deliveries
echo "Available deliveries:"
ls -la "$DEL_ROOT"

# Set delivery to use (adjust timestamp as needed)
DELIVERY_DIR="$DEL_ROOT/$(ls -t $DEL_ROOT | head -1)"  # Latest delivery
# Or specify exact delivery:
# DELIVERY_DIR="$DEL_ROOT/20250824-1530-ocp-platform"

echo "Using delivery: $DELIVERY_DIR"

# Validate delivery package
cd "$DELIVERY_DIR"
echo "Delivery contents:"
ls -la

# Verify checksums
sha256sum -c checksums.sha256 && echo "✅ Delivery integrity verified" || { echo "❌ Checksum verification failed"; exit 1; }
```

### **Step 3: Prepare Upload Environment**
```bash
# Ensure required directories exist
mkdir -p "$(dirname "$CACHE")"

# Display upload summary
echo "=== Upload Summary ==="
echo "Source: $DELIVERY_DIR"
echo "Target Registry: $REGISTRY_FQDN"
echo "Archives to upload: $(ls mirror_*.tar 2>/dev/null | wc -l)"
echo "Total size: $(du -sh mirror_*.tar 2>/dev/null | awk '{sum+=$1} END {print sum "B" }')"
echo "Cache location: $CACHE"
echo ""
```

### **Step 4: Execute From-Disk Upload**
```bash
# Run the standardized script (recommended)  
cd oc-mirror-master/
./oc-mirror-from-disk-to-registry.sh

# Or execute manually:
oc mirror -c "$DELIVERY_DIR/imageset-config.yaml" \
    --from file://"$DELIVERY_DIR" \
    "$REGISTRY_DOCKER" \
    --v2 \
    --cache-dir "$CACHE"
```

**Expected Output:**
```
🚀 Uploading mirrored content to registry...
📊 Content size: 150GB
📋 All necessary metadata is in content/working-dir/
🏷️  Target registry: hostname:8443

INFO[0000] Building ImageSetConfiguration from file
INFO[0005] Successfully extracted metadata
INFO[0010] Uploading platform images...
...
✅ Upload complete!
✨ Fresh cache created locally for future operations
```

### **Step 5: Validate Registry Content**
```bash
# Check specific release images are accessible
OCP_CURRENT="4.19.7"  # Adjust based on your configuration
oc adm release info "$REGISTRY_DOCKER/openshift/release-images:$OCP_CURRENT-x86_64"

# Verify release image details
echo "=== Registry Validation ==="
echo "Release info for $OCP_CURRENT:"
oc adm release info "$REGISTRY_DOCKER/openshift/release-images:$OCP_CURRENT-x86_64" --output=json | jq -r '.metadata.version'

# Test image pull capability (optional - requires podman/docker)
podman pull "$REGISTRY_FQDN/openshift/release-images:$OCP_CURRENT-x86_64" --tls-verify=false
```

## ✅ **Validation**

### **Comprehensive Registry Validation:**
```bash
validate_registry_content() {
    echo "=== Registry Content Validation ==="
    
    # Test 1: Registry API accessible
    curl -sk https://"$REGISTRY_FQDN"/v2/ >/dev/null && echo "✅ Registry API accessible" || { echo "❌ Registry API failed"; return 1; }
    
    # Test 2: Authentication working
    podman login --get-login "$REGISTRY_FQDN" >/dev/null && echo "✅ Authentication valid" || { echo "❌ Authentication failed"; return 1; }
    
    # Test 3: Release images present
    oc adm release info "$REGISTRY_DOCKER/openshift/release-images:$OCP_CURRENT-x86_64" >/dev/null 2>&1 && echo "✅ Release images accessible" || { echo "❌ Release images not found"; return 1; }
    
    # Test 4: Image pull test
    podman pull "$REGISTRY_FQDN/openshift/release-images:$OCP_CURRENT-x86_64" --tls-verify=false >/dev/null 2>&1 && echo "✅ Image pull successful" || echo "⚠️ Image pull test skipped"
    
    # Test 5: Check multiple versions if mirrored
    echo "Available release versions:"
    curl -sk https://"$REGISTRY_FQDN"/v2/openshift/release-images/tags/list | jq -r '.tags[]' | grep x86_64 | sort -V | tail -5
    
    echo "=== Registry Content Validation Complete ==="
}

# Run validation
validate_registry_content
```

### **Success Criteria:**
- ✅ **Registry API Responds**: HTTP 200 from `/v2/` endpoint
- ✅ **Authentication Working**: Can query registry with credentials
- ✅ **Images Accessible**: Can pull release info for expected versions
- ✅ **Complete Upload**: All archives processed successfully
- ✅ **Cache Created**: Local cache directory created for future operations

### **Common Issues & Quick Fixes:**
```bash
# Issue: Registry not accessible
# Solution: Check registry service and firewall
systemctl status quay-app  # For mirror-registry
curl -sk https://"$REGISTRY_FQDN"/health/instance

# Issue: Authentication failures
# Solution: Re-login to registry
podman login "$REGISTRY_FQDN"

# Issue: Disk space errors
# Solution: Check available space
df -h /opt/quay  # Default mirror-registry location
df -h "$CACHE"

# Issue: Image not found after upload
# Solution: Check exact image names and tags
curl -sk https://"$REGISTRY_FQDN"/v2/_catalog | jq '.'
```

## 🧹 **Cleanup**

### **Post-Upload Cleanup:**
```bash
# Archive the successful delivery (don't delete immediately)
ARCHIVE_DIR="$ARCHIVE_ROOT/$(basename "$DELIVERY_DIR")"
mkdir -p "$ARCHIVE_ROOT"
mv "$DELIVERY_DIR" "$ARCHIVE_DIR"

echo "Delivery archived at: $ARCHIVE_DIR"

# Clean temporary files
rm -f /tmp/oc-mirror-*.log

# Optional: Clean cache if space needed (will rebuild automatically)
# rm -rf "$CACHE"
```

### **DO NOT DELETE:**
- ❌ **Registry Content** - Images now serving OpenShift cluster
- ❌ **Cache Directory** - Performance optimization for future operations
- ❌ **Archived Deliveries** - Keep for audit trail and disaster recovery

## 🔧 **Post-Deployment Configuration**

### **OpenShift Cluster Configuration:**
```bash
# Apply mirror configuration to OpenShift cluster (run on cluster)
# These files were generated during the mirror-to-disk phase

echo "Apply these configurations to your OpenShift cluster:"
echo ""
echo "# ImageContentSourcePolicy (ICSP) or ImageDigestMirrorSet (IDMS):"
echo "oc apply -f path-to-generated-mirror-config.yaml"
echo ""
echo "# CatalogSource for operators (if applicable):"  
echo "oc apply -f path-to-generated-catalogsource.yaml"
echo ""
echo "# Update global pull secret if needed:"
echo "oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=merged-pull-secret.json"
```

### **Verify Cluster Integration:**
```bash
# From OpenShift cluster, verify it can pull from mirror registry
oc debug node/worker-node-name -- chroot /host podman pull "$REGISTRY_FQDN/openshift/release-images:$OCP_CURRENT-x86_64" --tls-verify=false
```

## 🚀 **Next Steps**

### **Immediate Next Actions:**
1. **Apply Cluster Configuration**: Use generated YAML files on OpenShift cluster
2. **Update Pull Secrets**: Merge registry credentials with cluster pull secret
3. **Test Cluster Integration**: Verify cluster can pull images from mirror registry

### **Related Workflows:**
- **Cluster Upgrade**: [flows/20-cluster-upgrade.md](20-cluster-upgrade.md) - Upgrade using mirrored content  
- **Content Maintenance**: [flows/13-delete.md](13-delete.md) - Clean up old versions
- **New Content**: [flows/10-mirror-to-disk.md](10-mirror-to-disk.md) - Mirror additional content

### **Operational Tasks:**
- **Monitor Registry**: Check storage usage and performance
- **Plan Updates**: Schedule regular content updates
- **Backup Strategy**: Plan registry backup and disaster recovery

## 💡 **Pro Tips**

### **Performance Optimization:**
```bash
# For large uploads, use performance flags:
oc mirror --from file://"$DELIVERY_DIR" "$REGISTRY_DOCKER" --v2 \
    --parallel-images 8 \
    --parallel-layers 10 \
    --cache-dir "$CACHE"
```

### **Network-Optimized Upload:**
- **Bandwidth Management**: Monitor network utilization during upload
- **Resume Capability**: oc-mirror v2 can resume interrupted uploads
- **Parallel Operations**: Adjust parallelism based on registry capacity

### **Registry Management:**
- **Storage Monitoring**: Set up alerts for registry storage usage
- **Garbage Collection**: Plan regular cleanup of unreferenced images
- **Backup Strategy**: Regular backups of registry content and configuration

### **Cache Management:**
```bash
# Check cache size and contents
du -sh "$CACHE"
ls -la "$CACHE"

# Cache provides performance benefits for future operations
# Keep cache unless storage space is critically needed
# Cache will rebuild automatically if deleted
```

## 🔄 **Integration with Cluster**

### **Required Cluster Configuration Steps:**
1. **Trust Registry**: Add registry CA certificate to cluster trust
2. **Update Pull Secret**: Include registry authentication
3. **Apply Mirror Configuration**: ImageContentSourcePolicy or ImageDigestMirrorSet
4. **Verify Integration**: Test image pulls from cluster nodes

### **Validation from Cluster:**
```bash
# Run these commands from OpenShift cluster
oc get imagecontentsourcepolicy  # or imagedigestmirrorset
oc get nodes -o wide
oc debug node/NODE_NAME -- chroot /host podman images | grep "$REGISTRY_FQDN"
```

---

**🎉 Success!** Your mirrored OpenShift content is now deployed and serving from the registry. The OpenShift cluster can pull images for installations, upgrades, and day-2 operations. The registry is ready for production workloads in your disconnected environment.
