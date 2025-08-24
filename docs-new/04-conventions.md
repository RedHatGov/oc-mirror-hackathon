# Conventions & Canonical Variables

## 🎯 **Single Source of Truth for Standards**

All workflow guides, scripts, and examples use these canonical variables and conventions. Define once, use everywhere.

## 📂 **Canonical Directory Structure**

### **Standard Paths (Copy-Paste Ready):**
```bash
# Export these variables at the start of each session
export REGISTRY_FQDN="$(hostname):8443"           # Dynamic hostname + standard port
export WS="/srv/oc-mirror/workspace"              # Persistent workspace
export DEL_ROOT="/srv/oc-mirror/deliveries"       # Immutable delivery archives
export ARCHIVE_ROOT="/srv/oc-mirror/archive"      # Long-term retention
export CACHE="$WS/.cache"                         # Performance cache
export DELETE_WS="/var/mirror/delete-workspace"   # Delete operations (optional)
export ISC="imageset-config.yaml"                 # Configuration file
export DELETE_ISC="imageset-delete.yaml"          # Delete configuration
```

### **Directory Purposes & Lifecycle:**
| Directory | Purpose | Lifecycle | Can Delete? |
|-----------|---------|-----------|-------------|
| `$WS/working-dir/` | Essential metadata | Persistent | ❌ Never |
| `$CACHE` | Performance optimization | Rebuildable | ✅ Yes, will rebuild |
| `$DEL_ROOT/` | Transport archives | Temporary | ✅ After successful deployment |
| `$ARCHIVE_ROOT/` | Audit trail | Long-term | ✅ After retention period |

## 🗂️ **File Naming Conventions**

### **Delivery Archives:**
```bash
# Format: YYYYMMDD-HHMM-<description>
DEL_ID="$(date +%Y%m%d-%H%M)-ocp419-operators"
DELIVERY_DIR="$DEL_ROOT/$DEL_ID"

# Examples:
# 20250824-1530-ocp419-platform
# 20250824-1545-ocp419-operators
# 20250824-1600-delete-cleanup
```

### **Configuration Files:**
```bash
# Standard configuration file names
ISC="imageset-config.yaml"              # Primary mirror configuration
DELETE_ISC="imageset-delete.yaml"       # Deletion configuration
ISC_PLATFORM="isc-platform-only.yaml"   # Platform-only configuration
ISC_FULL="isc-platform-ops-addl.yaml"   # Full configuration with operators
```

### **Log Files:**
```bash
# Standard log file naming
RUN_LOG="run-$(date +%Y%m%d-%H%M).log"
ERROR_LOG="errors-$(date +%Y%m%d-%H%M).log"
VALIDATION_LOG="validation-$(date +%Y%m%d-%H%M).log"
```

## 🏗️ **Host Role Conventions**

### **Role Identification:**
```bash
# Define role at start of each session
export HOST_ROLE="mirror-node"     # Options: mirror-node, registry-node, combined
export ENV_TYPE="airgapped"        # Options: airgapped, semi-connected, lab

# Conditional logic example:
if [[ "$HOST_ROLE" == "mirror-node" ]]; then
    echo "Configuring for content preparation..."
elif [[ "$HOST_ROLE" == "registry-node" ]]; then  
    echo "Configuring for content serving..."
fi
```

### **Network Conventions:**
```bash
# Registry access patterns
export REGISTRY_FQDN="$(hostname):8443"                    # Dynamic, matches certs
export REGISTRY_HTTP="http://$(hostname):8080"             # Insecure (lab only)
export REGISTRY_DOCKER="docker://$(hostname):8443"         # Docker protocol URL

# External registries (for reference)
export RH_REGISTRY="registry.redhat.io"
export QUAY_REGISTRY="quay.io"
export OCP_REGISTRY="quay.io/openshift-release-dev"
```

## ⚙️ **oc-mirror Command Patterns**

### **Standard Command Structure:**
```bash
# Mirror to Disk (m2d)
oc mirror -c "$ISC" \
    file://"$WS" \
    --v2 \
    --cache-dir "$CACHE" \
    [additional-flags]

# From Disk to Registry (d2r)  
oc mirror -c "$ISC" \
    --from file://"$DELIVERY_DIR" \
    "$REGISTRY_DOCKER" \
    --v2 \
    --cache-dir "$CACHE" \
    [additional-flags]

# Mirror to Registry (m2r)
oc mirror -c "$ISC" \
    "$REGISTRY_DOCKER" \
    --v2 \
    --cache-dir "$CACHE" \
    [additional-flags]

# Delete Generate
oc mirror delete \
    -c "$DELETE_ISC" \
    --generate \
    --workspace file://"$WS" \
    "$REGISTRY_DOCKER" \
    --v2

# Delete Execute  
oc mirror delete \
    --delete-yaml-file "$DELETE_PLAN" \
    "$REGISTRY_DOCKER" \
    --v2
```

### **Common Flag Patterns:**
```bash
# Performance flags (adjust based on environment)
PERF_FLAGS="--parallel-images 8 --parallel-layers 10"

# Security flags (production environments)
SEC_FLAGS="--dest-tls-verify=true --src-tls-verify=true"

# Debug flags (troubleshooting)
DEBUG_FLAGS="--log-level debug"

# Combined example:
oc mirror -c "$ISC" "$REGISTRY_DOCKER" --v2 $PERF_FLAGS $SEC_FLAGS
```

## 📋 **ImageSet Configuration Patterns**

### **Platform Configuration (Standard):**
```yaml
# Standard platform configuration
apiVersion: mirror.openshift.io/v2alpha1
kind: ImageSetConfiguration
mirror:
  platform:
    channels:
    - name: stable-4.19
      minVersion: 4.19.2          # Always pin versions
      maxVersion: 4.19.7          # Specific range
    graph: true                   # Required for upgrades/deletes
```

### **Version Pinning Strategy:**
```bash
# Define version ranges as variables for consistency
export OCP_CHANNEL="stable-4.19"
export OCP_MIN_VERSION="4.19.2"
export OCP_MAX_VERSION="4.19.7"  
export OCP_CURRENT="4.19.7"      # Current cluster version

# Use in imageset-config.yaml generation:
envsubst < isc-template.yaml > "$ISC"
```

## 🔐 **Security Conventions**

### **Authentication Patterns:**
```bash
# Standard authentication locations
export AUTH_FILE="${XDG_RUNTIME_DIR}/containers/auth.json"
export PULL_SECRET="$HOME/pull-secret.json"

# Registry login pattern:
podman login --authfile "$AUTH_FILE" "$REGISTRY_FQDN"

# Validation:
podman login --get-login "$REGISTRY_FQDN"
```

### **TLS Certificate Handling:**
```bash
# Standard certificate locations (if custom CA)
export CA_CERT_DIR="/etc/pki/ca-trust/source/anchors"
export REGISTRY_CA="$CA_CERT_DIR/registry-ca.crt"

# Trust configuration:
sudo cp registry-ca.crt "$CA_CERT_DIR/"
sudo update-ca-trust
```

## 📊 **Validation Conventions**

### **Standard Validation Commands:**
```bash
# Registry connectivity test
curl -sk https://"$REGISTRY_FQDN"/v2/ | jq '.' || echo "Registry not accessible"

# Authentication test  
podman login --get-login "$REGISTRY_FQDN" || echo "Authentication failed"

# Cluster access test
oc whoami --show-console || echo "Cluster access failed"

# Storage space check
df -h "$WS" "$DEL_ROOT" "$CACHE" || echo "Storage check failed"
```

### **Success Criteria Patterns:**
```bash
# Standard success validation
validate_success() {
    local operation=$1
    echo "Validating $operation success..."
    
    case $operation in
        "mirror-to-disk")
            # Check for delivery archives
            ls -la "$WS"/mirror_*.tar && echo "✅ Archives created" || echo "❌ No archives found"
            ;;
        "disk-to-registry")
            # Check registry content
            oc adm release info "$REGISTRY_DOCKER/openshift/release-images:$OCP_CURRENT-x86_64" && echo "✅ Images in registry" || echo "❌ Images not accessible"
            ;;
        "delete")
            # Check deletion success  
            oc adm release info "$REGISTRY_DOCKER/openshift/release-images:$DELETE_VERSION-x86_64" 2>&1 | grep -q "deleted or has expired" && echo "✅ Deletion successful" || echo "❌ Deletion failed"
            ;;
    esac
}
```

## 🎯 **Safety Gate Conventions**

### **Confirmation Patterns:**
```bash
# Standard confirmation function
confirm_action() {
    local action=$1
    echo "⚠️ About to: $action"
    echo "Registry: $REGISTRY_FQDN"
    echo "Workspace: $WS"
    echo ""
    read -p "Continue? (yes/no): " confirm
    [[ "$confirm" == "yes" ]] || { echo "Operation cancelled."; exit 1; }
}

# Usage example:
confirm_action "delete OpenShift versions 4.19.2-4.19.6 from registry"
```

### **Environment Checks:**
```bash
# Standard environment validation
check_prerequisites() {
    echo "=== Environment Check ==="
    
    # Required variables
    [[ -n "$REGISTRY_FQDN" ]] && echo "✅ REGISTRY_FQDN set" || { echo "❌ REGISTRY_FQDN not set"; exit 1; }
    [[ -n "$WS" ]] && echo "✅ WS set" || { echo "❌ WS not set"; exit 1; }
    
    # Required directories
    [[ -d "$WS" ]] && echo "✅ Workspace exists" || { echo "❌ Workspace missing"; exit 1; }
    
    # Required tools
    command -v oc-mirror >/dev/null && echo "✅ oc-mirror available" || { echo "❌ oc-mirror not found"; exit 1; }
    
    echo "=== Environment Check Complete ==="
}
```

## 🚀 **Quick Setup (Copy-Paste Block)**

### **Session Initialization:**
```bash
#!/bin/bash
# Standard session setup - copy/paste at start of each workflow

# Core variables (adjust REGISTRY_FQDN if needed)
export REGISTRY_FQDN="$(hostname):8443"
export WS="/srv/oc-mirror/workspace" 
export DEL_ROOT="/srv/oc-mirror/deliveries"
export CACHE="$WS/.cache"
export ISC="imageset-config.yaml"
export DELETE_ISC="imageset-delete.yaml"

# Version control
export OCP_CHANNEL="stable-4.19"
export OCP_MIN_VERSION="4.19.2"
export OCP_MAX_VERSION="4.19.7"

# Create directories if needed
mkdir -p "$WS" "$DEL_ROOT" "$(dirname "$CACHE")"

# Validate environment
echo "Using registry: $REGISTRY_FQDN"
echo "Workspace: $WS"
echo "Deliveries: $DEL_ROOT"

# Quick validation
curl -sk https://"$REGISTRY_FQDN"/v2/ >/dev/null && echo "✅ Registry accessible" || echo "❌ Registry not accessible"
```

## 💡 **Why These Conventions Matter**

### **Benefits:**
- ✅ **Consistency**: Same variables/patterns across all flows
- ✅ **Maintainability**: Change in one place, works everywhere  
- ✅ **Reduced Errors**: Copy-paste friendly, tested patterns
- ✅ **Portability**: Works across different environments with minimal changes

### **Usage:**
- **Flow Guides**: Reference these conventions, don't redefine
- **Scripts**: Source these variables at the beginning
- **Examples**: Always use canonical variable names
- **Documentation**: Link to this file rather than duplicating

---

**💡 Pro Tip**: Bookmark this conventions file and reference it frequently. It's the foundation for all operational workflows in this hackathon repo.
