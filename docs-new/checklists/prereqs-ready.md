# Prerequisites Ready Checklist

## 🎯 **Environment Validation Before Starting Workflows**

Complete this checklist to ensure your environment is ready for any oc-mirror workflow. This is your "Ready Gate" before proceeding.

## ✅ **System Requirements Validation**

### **Hardware & OS:**
```bash
# System information
echo "=== System Validation ==="
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Kernel: $(uname -r)"
echo "CPU: $(nproc) cores"
echo "Memory: $(free -h | grep 'Mem:' | awk '{print $2}')"
echo "Architecture: $(uname -m)"
echo ""

# Storage validation
echo "=== Storage Validation ==="
df -h /srv/oc-mirror/ 2>/dev/null || df -h ~/oc-mirror/
echo "Required: 500GB+ available for enterprise mirror"
echo ""
```

**Requirements Check:**
- [ ] **OS**: RHEL 9.x, RHEL 8.x, or Fedora 38+ 
- [ ] **CPU**: 4+ cores
- [ ] **Memory**: 16GB+ RAM
- [ ] **Storage**: 500GB+ available (adjust based on mirror scope)
- [ ] **Architecture**: x86_64

## ✅ **Required Tools Installation**

### **Tool Availability Check:**
```bash
echo "=== Tool Availability ==="

# Core tools
command -v oc-mirror >/dev/null && echo "✅ oc-mirror: $(oc-mirror --v2 version 2>/dev/null | head -1)" || echo "❌ oc-mirror not found"
command -v oc >/dev/null && echo "✅ oc: $(oc version --client -o yaml | grep gitVersion | head -1 | awk '{print $2}')" || echo "❌ oc not found"
command -v openshift-install >/dev/null && echo "✅ openshift-install: $(openshift-install version | grep 'openshift-install' | awk '{print $2}')" || echo "❌ openshift-install not found"

# Container tools  
command -v podman >/dev/null && echo "✅ podman: $(podman --version)" || echo "❌ podman not found"
command -v docker >/dev/null && echo "✅ docker: $(docker --version)" || echo "⚠️ docker not found (podman preferred)"

# Utilities
command -v jq >/dev/null && echo "✅ jq: $(jq --version)" || echo "❌ jq not found"
command -v yq >/dev/null && echo "✅ yq: $(yq --version)" || echo "⚠️ yq not found (optional)"
command -v sha256sum >/dev/null && echo "✅ sha256sum available" || echo "❌ sha256sum not found"
command -v curl >/dev/null && echo "✅ curl: $(curl --version | head -1 | awk '{print $2}')" || echo "❌ curl not found"

echo ""
```

**Installation Check:**
- [ ] **oc-mirror v2**: Available and v2 version confirmed
- [ ] **oc client**: Version 4.19+ compatible with your cluster
- [ ] **openshift-install**: Matches your target OpenShift version
- [ ] **podman**: Version 4.0+ for container operations
- [ ] **jq**: For JSON processing and validation
- [ ] **sha256sum**: For checksum verification
- [ ] **curl**: For API testing and downloads

### **Quick Installation (if needed):**
```bash
# Use our simplified collection script
./collect_ocp

# Or install individually:
# curl -L -o oc-mirror.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/oc-mirror.tar.gz
# tar -xf oc-mirror.tar.gz && sudo cp oc-mirror /usr/local/bin/
```

## ✅ **Network Connectivity Validation**

### **Internet Connectivity (Mirror Node):**
```bash
echo "=== Network Connectivity Test ==="

# Red Hat registries
curl -s --max-time 10 https://registry.redhat.io/v2/ >/dev/null && echo "✅ registry.redhat.io accessible" || echo "❌ registry.redhat.io not accessible"
curl -s --max-time 10 https://quay.io/v2/ >/dev/null && echo "✅ quay.io accessible" || echo "❌ quay.io not accessible"

# OpenShift release info
curl -s --max-time 10 https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/release.txt >/dev/null && echo "✅ mirror.openshift.com accessible" || echo "❌ mirror.openshift.com not accessible"

# DNS resolution
nslookup registry.redhat.io >/dev/null 2>&1 && echo "✅ DNS resolution working" || echo "❌ DNS resolution issues"

# Time synchronization
timedatectl status | grep -q "NTP service: active" && echo "✅ NTP synchronized" || echo "⚠️ Check NTP configuration"

echo ""
```

**Network Requirements:**
- [ ] **HTTPS (443)** to registry.redhat.io
- [ ] **HTTPS (443)** to quay.io  
- [ ] **HTTPS (443)** to mirror.openshift.com
- [ ] **DNS Resolution** working for external domains
- [ ] **NTP Synchronization** active and working
- [ ] **Proxy Configuration** (if required in environment)

## ✅ **Registry Service Validation**

### **Registry Connectivity & Health:**
```bash
echo "=== Registry Service Validation ==="

# Set registry from canonical variables
export REGISTRY_FQDN="${REGISTRY_FQDN:-$(hostname):8443}"

# Registry API test
curl -sk https://"$REGISTRY_FQDN"/v2/ >/dev/null 2>&1 && echo "✅ Registry API accessible at $REGISTRY_FQDN" || echo "❌ Registry not accessible at $REGISTRY_FQDN"

# Registry health (if supported)
curl -sk https://"$REGISTRY_FQDN"/health/instance 2>/dev/null | grep -q "database" && echo "✅ Registry health check passed" || echo "⚠️ Registry health check not available"

# Registry service status (for mirror-registry)
systemctl is-active quay-app >/dev/null 2>&1 && echo "✅ Quay service active" || echo "⚠️ Quay service status unknown"

# Storage space check
REGISTRY_PATH="/opt/quay"  # Adjust for your registry
[[ -d "$REGISTRY_PATH" ]] && echo "Registry storage: $(df -h "$REGISTRY_PATH" | tail -1 | awk '{print $4}')" || echo "⚠️ Registry path not found at $REGISTRY_PATH"

echo ""
```

**Registry Requirements:**
- [ ] **Registry Service**: Running and accessible
- [ ] **API Endpoint**: `/v2/` responds with `{}`
- [ ] **TLS Certificate**: Valid and trusted (or insecure mode configured)
- [ ] **Storage Space**: Adequate for mirror content (500GB-2TB)
- [ ] **Network Access**: Accessible from intended hosts/networks

## ✅ **Authentication Validation** 

### **Registry Authentication:**
```bash
echo "=== Authentication Validation ==="

# Red Hat registry authentication
podman login --get-login registry.redhat.io >/dev/null 2>&1 && echo "✅ Red Hat registry authenticated" || echo "❌ Red Hat registry authentication needed"

# Local registry authentication
podman login --get-login "$REGISTRY_FQDN" >/dev/null 2>&1 && echo "✅ Local registry authenticated" || echo "❌ Local registry authentication needed"

# Pull secret validation
[[ -f ~/.config/containers/auth.json ]] && echo "✅ Container auth file exists" || echo "❌ Container auth file not found"

# Registry permissions test (push capability)
echo "test" | podman run --rm -i --authfile ~/.config/containers/auth.json registry.redhat.io/ubi8/ubi:latest echo "permissions test" >/dev/null 2>&1 && echo "✅ Registry permissions validated" || echo "⚠️ Registry permissions test skipped"

echo ""
```

**Authentication Setup:**
```bash
# Login to Red Hat registries (if needed)
podman login registry.redhat.io
podman login quay.io

# Login to local registry (if needed)  
podman login "$REGISTRY_FQDN"
```

**Authentication Requirements:**
- [ ] **Red Hat Registry**: Authenticated with valid Red Hat account
- [ ] **Local Registry**: Authenticated with push/pull permissions
- [ ] **Pull Secret**: Downloaded from Red Hat Console (for cluster integration)
- [ ] **Auth File**: Located at `~/.config/containers/auth.json`

## ✅ **OpenShift Cluster Access**

### **Cluster Connectivity (if applicable):**
```bash
echo "=== OpenShift Cluster Validation ==="

# Cluster access test
oc whoami >/dev/null 2>&1 && echo "✅ Cluster access: $(oc whoami)" || echo "❌ No cluster access"

# Cluster admin privileges
oc auth can-i '*' '*' --all-namespaces >/dev/null 2>&1 && echo "✅ Cluster admin privileges" || echo "❌ Insufficient cluster privileges"

# Cluster version
oc get clusterversion >/dev/null 2>&1 && echo "Cluster version: $(oc get clusterversion -o jsonpath='{.items[0].status.desired.version}')" || echo "⚠️ Cannot get cluster version"

# Cluster console URL
oc whoami --show-console 2>/dev/null && echo "" || echo "⚠️ Console URL not available"

echo ""
```

**Cluster Requirements:**
- [ ] **Authenticated Access**: `oc whoami` succeeds
- [ ] **Admin Privileges**: Can perform cluster-admin operations
- [ ] **Version Compatibility**: Cluster version matches mirror content
- [ ] **Network Access**: Can reach cluster API endpoint

## ✅ **Directory Structure & Permissions**

### **Standard Directory Setup:**
```bash
echo "=== Directory Structure Validation ==="

# Canonical directories from conventions
export WS="${WS:-/srv/oc-mirror/workspace}"
export DEL_ROOT="${DEL_ROOT:-/srv/oc-mirror/deliveries}"
export ARCHIVE_ROOT="${ARCHIVE_ROOT:-/srv/oc-mirror/archive}"

# Create and validate directories
mkdir -p "$WS" "$DEL_ROOT" "$ARCHIVE_ROOT" 2>/dev/null

# Check permissions and space
for dir in "$WS" "$DEL_ROOT" "$ARCHIVE_ROOT"; do
    [[ -w "$dir" ]] && echo "✅ $dir (writable, $(df -h "$dir" | tail -1 | awk '{print $4}'))" || echo "❌ $dir not writable"
done

# Cache directory
export CACHE="$WS/.cache"
mkdir -p "$(dirname "$CACHE")" 2>/dev/null
[[ -w "$(dirname "$CACHE")" ]] && echo "✅ Cache directory $(dirname "$CACHE") writable" || echo "❌ Cache directory not writable"

echo ""
```

**Directory Requirements:**
- [ ] **Workspace**: `/srv/oc-mirror/workspace` (or `~/oc-mirror/workspace`)
- [ ] **Deliveries**: `/srv/oc-mirror/deliveries` (or `~/oc-mirror/deliveries`)
- [ ] **Archive**: `/srv/oc-mirror/archive` (optional, for long-term retention)
- [ ] **Permissions**: All directories writable by current user
- [ ] **Storage Space**: Adequate for all directory usage patterns

## ✅ **Configuration Files**

### **ImageSet Configuration Validation:**
```bash
echo "=== Configuration Validation ==="

# Check for ImageSet configuration file
export ISC="${ISC:-imageset-config.yaml}"
[[ -f "$ISC" ]] && echo "✅ ImageSet config: $ISC" || echo "❌ ImageSet config not found: $ISC"

# Validate configuration structure (if file exists)
if [[ -f "$ISC" ]]; then
    yq eval '.mirror.platform.channels' "$ISC" >/dev/null 2>&1 && echo "✅ Platform channels defined" || echo "⚠️ Platform channels not found"
    yq eval '.mirror.platform.graph' "$ISC" | grep -q true && echo "✅ Graph data enabled" || echo "❌ Graph data not enabled (required for upgrades/deletes)"
    
    # Version pinning check
    yq eval '.mirror.platform.channels[].minVersion' "$ISC" >/dev/null 2>&1 && echo "✅ Version ranges pinned" || echo "⚠️ Consider pinning version ranges"
fi

echo ""
```

**Configuration Requirements:**
- [ ] **ImageSet Config**: Present and valid YAML
- [ ] **Platform Channels**: Defined with appropriate OpenShift versions
- [ ] **Graph Data**: `graph: true` enabled (required for cluster operations)
- [ ] **Version Pinning**: Specific version ranges rather than "latest"

## 🚀 **Final Readiness Summary**

### **Run Complete Environment Check:**
```bash
#!/bin/bash
# Complete prerequisites validation script

echo "🔍 PREREQUISITES READINESS CHECK"
echo "================================"

# Count passed/failed checks
PASSED=0
FAILED=0
WARNINGS=0

# Function to check and count
check_item() {
    local test_cmd="$1"
    local success_msg="$2"  
    local fail_msg="$3"
    
    if eval "$test_cmd" >/dev/null 2>&1; then
        echo "✅ $success_msg"
        ((PASSED++))
    else
        echo "❌ $fail_msg"
        ((FAILED++))
    fi
}

warning_item() {
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

# Critical checks
check_item "command -v oc-mirror" "oc-mirror v2 available" "oc-mirror not found"
check_item "command -v oc" "oc client available" "oc client not found"  
check_item "command -v podman" "podman available" "podman not found"
check_item "curl -s --max-time 5 https://registry.redhat.io/v2/" "Red Hat registry accessible" "Red Hat registry not accessible"
check_item "podman login --get-login registry.redhat.io" "Red Hat registry authenticated" "Red Hat registry authentication needed"

# Set registry FQDN
export REGISTRY_FQDN="${REGISTRY_FQDN:-$(hostname):8443}"
check_item "curl -sk --max-time 5 https://$REGISTRY_FQDN/v2/" "Local registry accessible" "Local registry not accessible"
check_item "podman login --get-login $REGISTRY_FQDN" "Local registry authenticated" "Local registry authentication needed"

# Directory checks  
export WS="${WS:-/srv/oc-mirror/workspace}"
check_item "[[ -w $WS ]] || mkdir -p $WS" "Workspace directory ready" "Cannot create workspace directory"

# Configuration check
export ISC="${ISC:-imageset-config.yaml}"
warning_item "[[ -f $ISC ]]" "ImageSet configuration found" "ImageSet configuration not found (create before proceeding)"

echo ""
echo "📊 READINESS SUMMARY"  
echo "=================="
echo "✅ Passed: $PASSED"
echo "❌ Failed: $FAILED"
echo "⚠️ Warnings: $WARNINGS"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo "🎉 PREREQUISITES READY!"
    echo "You can proceed with any oc-mirror workflow."
    echo ""
    echo "Next steps:"
    echo "1. Review [04-conventions.md] for standard variables"  
    echo "2. Choose your workflow from [00-overview.md]"
    echo "3. Run [checklists/run-go.md] before executing"
else
    echo "🚨 PREREQUISITES NOT READY"
    echo "Please resolve the failed items before proceeding."
    echo ""
    echo "Common solutions:"
    echo "• Install missing tools: ./collect_ocp"
    echo "• Authenticate to registries: podman login"
    echo "• Check network connectivity and firewall rules"
    echo "• Verify registry service is running"
fi
```

**Ready Gate Decision:**
- [ ] **All Critical Items Pass**: No ❌ items in validation
- [ ] **Warnings Addressed**: Understanding of all ⚠️ items
- [ ] **Documentation Reviewed**: [04-conventions.md](../04-conventions.md) for variables
- [ ] **Workflow Selected**: Choice made from [00-overview.md](../00-overview.md)

---

**🎉 Ready to Proceed?** If all critical checks pass, you're ready to execute any oc-mirror workflow with confidence. Warnings should be understood but don't block progression.

**⚠️ Issues Found?** Resolve failed items using [02-shared-prereqs.md](../02-shared-prereqs.md) and [references/troubleshooting.md](../references/troubleshooting.md)

**Next Step**: Proceed to [checklists/run-go.md](run-go.md) before executing your chosen workflow.
