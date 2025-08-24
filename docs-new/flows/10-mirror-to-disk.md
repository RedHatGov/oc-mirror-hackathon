# Mirror-to-Disk - Build Portable Archives

## 🎯 **When to Use This Flow**

- ✅ **Fully Airgapped Environments**: No internet access on registry host
- ✅ **Physical Transport**: Moving content via USB, DVD, or tape
- ✅ **Controlled Transfer**: Secure transport between network segments
- ✅ **Backup/Archive**: Creating portable mirror archives for disaster recovery
- ❌ **NOT for Semi-Connected**: Use [Mirror-to-Registry](12-mirror-to-registry.md) instead
- ❌ **NOT for Same-Host Lab**: Direct registry mirroring is more efficient

## 📋 **Prerequisites**

Complete [02-shared-prereqs.md](../02-shared-prereqs.md) and export variables from [04-conventions.md](../04-conventions.md).

**Host Role**: This runs on the **Mirror Node** (connected/semi-connected system).

## 🔍 **Inputs & Artifacts**

### **Required Inputs:**
- **ImageSet Configuration**: `$ISC` with specific version ranges
- **Internet Connectivity**: Access to Red Hat registries  
- **Storage Space**: 200-500GB for typical enterprise mirror
- **Working Directory**: `$WS` for metadata and temporary files

### **Generated Artifacts:**
- **Delivery Archives**: `$WS/mirror_*.tar` - Portable image archives
- **Essential Metadata**: `$WS/working-dir/` - Critical for deployment and operations
- **Configuration Copy**: For transport with archives
- **Checksums & Logs**: Validation and audit trail

## ⚡ **Procedure**

### **Step 1: Environment Setup**
```bash
# Load canonical variables (from 04-conventions.md)
export REGISTRY_FQDN="$(hostname):8443"
export WS="/srv/oc-mirror/workspace"
export CACHE="$WS/.cache"  
export ISC="imageset-config.yaml"

# Create required directories
mkdir -p "$WS" "$(dirname "$CACHE")"

# Validate environment
echo "Using workspace: $WS"
echo "Configuration: $ISC"
echo "Cache location: $CACHE"
```

### **Step 2: Verify Configuration**
```bash
# Check ImageSet configuration
cat "$ISC"

# Validate essential settings:
# - platform.graph: true (required for upgrades/deletes)
# - Specific version ranges (not "latest")
# - Appropriate channels for your OpenShift version
```

**Example Configuration:**
```yaml
apiVersion: mirror.openshift.io/v2alpha1
kind: ImageSetConfiguration
mirror:
  platform:
    channels:
    - name: stable-4.19
      minVersion: 4.19.2
      maxVersion: 4.19.7
    graph: true  # Critical: Required for cluster operations
```

### **Step 3: Execute Mirror-to-Disk**
```bash
# Run the standardized script (recommended)
cd oc-mirror-master/
./oc-mirror-to-disk.sh

# Or execute manually:
oc mirror -c "$ISC" \
    file://"$WS" \
    --v2 \
    --cache-dir "$CACHE"
```

**Expected Output:**
```
📥 Mirroring content from registry to disk...
🎯 Target: file://workspace (local disk storage)
📋 Config: imageset-config.yaml

INFO[0000] Building ImageSetConfiguration from file     
INFO[0005] Successfully pulled metadata              
INFO[0010] Processing platform images...
...
✅ Mirror to disk complete!
```

### **Step 4: Validate Archive Creation**
```bash
# Check for delivery archives
ls -la "$WS"/mirror_*.tar

# Verify essential metadata
ls -la "$WS/working-dir/"

# Check archive sizes and count
echo "Archive Summary:"
echo "Count: $(ls "$WS"/mirror_*.tar 2>/dev/null | wc -l)"
echo "Total Size: $(du -sh "$WS"/mirror_*.tar 2>/dev/null | awk '{total+=$1} END {print total "G"}')"
```

**Success Indicators:**
- ✅ One or more `mirror_*.tar` files created
- ✅ `working-dir/` directory with metadata
- ✅ No error messages in output
- ✅ Archive files have reasonable sizes (not 0 bytes)

### **Step 5: Prepare Delivery Package**
```bash
# Create delivery directory with timestamp
DEL_ID="$(date +%Y%m%d-%H%M)-ocp-platform"
DELIVERY_DIR="$DEL_ROOT/$DEL_ID"
mkdir -p "$DELIVERY_DIR"

# Move archives to delivery directory
mv "$WS"/mirror_*.tar "$DELIVERY_DIR/"

# Copy configuration for deployment reference  
cp "$ISC" "$DELIVERY_DIR/"

# Generate checksums for integrity verification
cd "$DELIVERY_DIR"
sha256sum mirror_*.tar > checksums.sha256
sha256sum imageset-config.yaml >> checksums.sha256

# Create delivery manifest
cat > delivery-manifest.txt << EOF
Delivery ID: $DEL_ID
Created: $(date)
Archives: $(ls mirror_*.tar | wc -l)
Total Size: $(du -sh . | cut -f1)
Source Config: imageset-config.yaml
Checksum File: checksums.sha256
EOF

echo "✅ Delivery prepared at: $DELIVERY_DIR"
```

## ✅ **Validation**

### **Comprehensive Validation:**
```bash
# Validate delivery package
validate_delivery() {
    echo "=== Delivery Validation ==="
    
    # Check delivery directory exists
    [[ -d "$DELIVERY_DIR" ]] && echo "✅ Delivery directory exists" || { echo "❌ Delivery directory missing"; return 1; }
    
    # Check archives present
    local archive_count=$(ls "$DELIVERY_DIR"/mirror_*.tar 2>/dev/null | wc -l)
    [[ $archive_count -gt 0 ]] && echo "✅ $archive_count archives created" || { echo "❌ No archives found"; return 1; }
    
    # Verify checksums
    cd "$DELIVERY_DIR"
    sha256sum -c checksums.sha256 && echo "✅ Checksums verified" || { echo "❌ Checksum verification failed"; return 1; }
    
    # Check configuration file
    [[ -f imageset-config.yaml ]] && echo "✅ Configuration included" || { echo "❌ Configuration missing"; return 1; }
    
    # Check workspace metadata preserved
    [[ -d "$WS/working-dir" ]] && echo "✅ Workspace metadata preserved" || { echo "❌ Workspace metadata missing"; return 1; }
    
    echo "=== Delivery Validation Complete ==="
}

# Run validation
validate_delivery
```

### **Success Criteria:**
- ✅ **Archives Created**: Multiple tar files with container images
- ✅ **Checksums Valid**: SHA256 verification passes
- ✅ **Configuration Present**: ImageSet config included in delivery
- ✅ **Metadata Preserved**: `working-dir/` intact in workspace
- ✅ **Reasonable Size**: Archives match expected content scope

### **Common Issues & Quick Fixes:**
```bash
# Issue: No archives created
# Solution: Check ImageSet configuration and network connectivity
cat "$ISC" | yq '.mirror.platform.channels'

# Issue: Zero-byte archives  
# Solution: Check storage space and permissions
df -h "$WS"
ls -la "$WS"

# Issue: Authentication errors
# Solution: Verify registry login
podman login --get-login registry.redhat.io
```

## 🧹 **Cleanup**

### **Immediate Cleanup (Safe):**
```bash
# Clean cache if storage space needed (will rebuild automatically)
rm -rf "$CACHE"

# Clean temporary files (archives moved to delivery)
rm -f "$WS"/*.log "$WS"/*.tmp
```

### **DO NOT DELETE:**
- ❌ **`$WS/working-dir/`** - Essential metadata for all future operations
- ❌ **`$DELIVERY_DIR`** - Archives needed for transport
- ❌ **Configuration files** - Needed for deployment

## 📦 **Transport Preparation**

### **Physical Media (Airgapped):**
```bash
# Create transportable archive
cd "$DEL_ROOT"
tar -czf "${DEL_ID}.tar.gz" "$DEL_ID"

# Verify final package
ls -la "${DEL_ID}.tar.gz"
echo "Ready for physical transport: ${DEL_ID}.tar.gz"

# Transport checklist:
echo "📋 Transport Package:"
echo "  • Archive: ${DEL_ID}.tar.gz"  
echo "  • Contains: $(ls "$DEL_ID" | wc -l) files"
echo "  • Size: $(du -sh "${DEL_ID}.tar.gz" | cut -f1)"
echo "  • Checksum: $(sha256sum "${DEL_ID}.tar.gz")"
```

### **Network Transfer (Semi-Connected):**
```bash
# Transfer to registry node (example)
scp -r "$DELIVERY_DIR" registry-node:/srv/oc-mirror/deliveries/

# Verify transfer
ssh registry-node "ls -la /srv/oc-mirror/deliveries/$DEL_ID"
```

## 🚀 **Next Steps**

### **Immediate Next Actions:**
1. **Transport Archives**: Move delivery package to Registry Node
2. **Deploy Content**: Follow [From-Disk-to-Registry](11-from-disk-to-registry.md)
3. **Apply Configuration**: Use generated cluster resources

### **Related Workflows:**
- **Deploy Archives**: [flows/11-from-disk-to-registry.md](11-from-disk-to-registry.md)
- **Cluster Configuration**: Apply generated YAML from `working-dir/`
- **Upgrade Workflow**: [flows/20-cluster-upgrade.md](20-cluster-upgrade.md) (if applicable)

### **Maintenance:**
- **Regular Updates**: Re-run this flow for new OpenShift versions
- **Archive Management**: Move old deliveries to long-term storage
- **Cache Management**: Monitor and clean cache directory as needed

## 💡 **Pro Tips**

### **Performance Optimization:**
```bash
# For large mirrors, use performance flags:
oc mirror -c "$ISC" file://"$WS" --v2 \
    --parallel-images 8 \
    --parallel-layers 10 \
    --cache-dir "$CACHE"
```

### **Network-Constrained Environments:**
- **Schedule During Off-Hours**: Large downloads during low-usage periods
- **Monitor Progress**: Use `--log-level debug` for detailed progress
- **Resume Capability**: oc-mirror v2 can resume interrupted downloads

### **Storage Management:**
- **Monitor Space**: Keep 2x archive size free during operations
- **Cache Location**: Consider fast storage (SSD) for cache directory
- **Archive Lifecycle**: Plan retention and cleanup policies

---

**🎉 Success!** Your OpenShift content is now packaged in portable delivery archives, ready for secure transport to disconnected environments. The archives contain everything needed for deployment, and the workspace retains essential metadata for future operations.
