# Troubleshooting Reference

## 🎯 **oc-mirror v2 Error Diagnosis & Resolution**

Comprehensive troubleshooting guide mapping specific error messages to root causes and proven solutions. Based on real-world validation and testing.

## 🔍 **Error Diagnostic Framework**

### **Error Pattern Format**
Each troubleshooting entry follows this structure:
```
ERROR MESSAGE → ROOT CAUSE → SOLUTION → PREVENTION
```

### **Error Categories**
- **[Authentication & Permissions](#authentication--permissions)**
- **[Network & Connectivity](#network--connectivity)**  
- **[Storage & Space](#storage--space)**
- **[Configuration Issues](#configuration-issues)**
- **[Cache Problems](#cache-problems)**
- **[Deletion Errors](#deletion-errors)**
- **[Registry Issues](#registry-issues)**

## 🔐 **Authentication & Permissions**

### **Registry Authentication Failed**
```
ERROR: authentication required
ERROR: denied: requested access to the resource is denied
```
**ROOT CAUSE**: Invalid or missing registry authentication credentials

**SOLUTION**:
```bash
# Re-authenticate to registry
podman login "$REGISTRY_FQDN"

# Verify authentication
podman login --get-login "$REGISTRY_FQDN"

# Check auth file exists
ls -la ~/.config/containers/auth.json
```

**PREVENTION**: 
- Use canonical `$REGISTRY_FQDN` variable consistently
- Set up credential refresh automation for long-running environments
- Document registry authentication requirements in runbooks

### **Pull Secret Not Found**
```
ERROR: pull secret not found
ERROR: unable to read pull secret
```
**ROOT CAUSE**: Missing or corrupted Red Hat pull secret

**SOLUTION**:
```bash
# Download fresh pull secret from Red Hat Console
# https://console.redhat.com/openshift/install/pull-secret

# Verify pull secret format
jq . pull-secret.json

# Merge with local registry credentials if needed
jq -s '.[0] * .[1]' pull-secret.json ~/.config/containers/auth.json > merged-pull-secret.json
```

**PREVENTION**:
- Keep pull secret backup in secure location
- Document pull secret update procedures
- Monitor pull secret expiration if applicable

### **Registry Push Permission Denied**
```
ERROR: denied: push access to the resource is denied
ERROR: authorization failed
```
**ROOT CAUSE**: Account lacks push/delete permissions on target registry

**SOLUTION**:
```bash
# Verify account permissions with registry admin
# For mirror-registry, check quay configuration:
sudo cat /opt/quay/config/config.yaml | grep -A 10 FEATURE_USER_CREATION

# Test permissions with simple push
echo "test" | podman run --rm -i --authfile ~/.config/containers/auth.json \
  registry.access.redhat.com/ubi8/ubi:latest echo "permission test"
```

**PREVENTION**:
- Document registry permission requirements
- Use service accounts with appropriate permissions
- Implement permission validation in automation scripts

## 🌐 **Network & Connectivity**

### **Registry Not Accessible**
```
ERROR: Get "https://registry:8443/v2/": dial tcp: connection refused
ERROR: registry not reachable
```
**ROOT CAUSE**: Registry service not running or network connectivity issues

**SOLUTION**:
```bash
# Test registry connectivity
curl -sk https://"$REGISTRY_FQDN"/v2/

# Check registry service status
systemctl status quay-app  # For mirror-registry

# Verify network connectivity
telnet "$REGISTRY_FQDN" 8443

# Check firewall rules
sudo firewall-cmd --list-ports | grep 8443
```

**PREVENTION**:
- Implement registry health monitoring
- Document firewall requirements
- Set up automated service restart procedures

### **DNS Resolution Failed**
```
ERROR: no such host
ERROR: cannot resolve hostname
```
**ROOT CAUSE**: DNS resolution failure for registry hostname

**SOLUTION**:
```bash
# Test DNS resolution
nslookup "$REGISTRY_FQDN"

# Add to /etc/hosts if needed (temporary)
echo "192.168.1.100 registry.example.com" | sudo tee -a /etc/hosts

# Use IP address as workaround
export REGISTRY_FQDN="192.168.1.100:8443"
```

**PREVENTION**:
- Use IP addresses in environments without DNS
- Configure proper DNS entries for production
- Document hostname resolution requirements

### **Internet Connectivity Issues**
```
ERROR: Get "https://registry.redhat.io/v2/": dial tcp: i/o timeout
ERROR: network is unreachable
```
**ROOT CAUSE**: No internet connectivity or proxy issues

**SOLUTION**:
```bash
# Test internet connectivity
curl -s https://registry.redhat.io/v2/

# Configure proxy if required
export HTTP_PROXY="http://proxy.example.com:8080"
export HTTPS_PROXY="http://proxy.example.com:8080"
export NO_PROXY="localhost,127.0.0.1,$REGISTRY_FQDN"

# Test with proxy
curl --proxy "$HTTP_PROXY" https://registry.redhat.io/v2/
```

**PREVENTION**:
- Document proxy requirements for disconnected environments
- Test connectivity before mirror operations
- Plan for network outages in automation scripts

## 💾 **Storage & Space**

### **No Space Left on Device**
```
ERROR: no space left on device
ERROR: write: no space left on device  
```
**ROOT CAUSE**: Insufficient disk space for mirror operations

**SOLUTION**:
```bash
# Check available space
df -h "$WS"
df -h "$CACHE"
df -h /tmp

# Clean cache if space needed
rm -rf "$CACHE"

# Move operations to larger storage
export WS="/opt/large-storage/workspace"
export CACHE="/opt/large-storage/.cache"

# Clean temporary files
sudo rm -rf /tmp/oc-mirror-*
```

**PREVENTION**:
- Monitor disk space before operations: `df -h`
- Plan storage requirements: Platform (50GB), Operators (+100GB), Cache (+200GB)
- Implement automated space monitoring and cleanup

### **Permission Denied on Storage**
```
ERROR: open /path/to/file: permission denied
ERROR: cannot create directory: permission denied
```
**ROOT CAUSE**: Insufficient permissions on storage directories

**SOLUTION**:
```bash
# Fix ownership
sudo chown -R "$(whoami):$(whoami)" "$WS" "$CACHE"

# Fix permissions
chmod -R u+rwX "$WS" "$CACHE"

# Create directories if needed
mkdir -p "$WS" "$(dirname "$CACHE")"
```

**PREVENTION**:
- Use dedicated directories outside user home for shared environments
- Document permission requirements in setup procedures
- Include permission checks in validation scripts

## ⚙️ **Configuration Issues**

### **Invalid ImageSet Configuration**
```
ERROR: error unmarshaling JSON: invalid character
ERROR: yaml: line N: mapping values are not allowed
```
**ROOT CAUSE**: Syntax errors in ImageSet configuration file

**SOLUTION**:
```bash
# Validate YAML syntax
yq eval . "$ISC" >/dev/null && echo "✅ Valid YAML" || echo "❌ Invalid YAML"

# Check required fields
yq eval '.mirror.platform.channels[].name' "$ISC"
yq eval '.mirror.platform.graph' "$ISC"

# Use validated configuration sample
cp docs-new/config-samples/isc-platform-only.yaml "$ISC"
```

**PREVENTION**:
- Use validated configuration samples from `config-samples/`
- Implement configuration validation in automation
- Use consistent indentation (spaces, not tabs)

### **Missing Graph Data**
```
ERROR: platform images require graph data, but graph field is false
```
**ROOT CAUSE**: `graph: true` not set in platform configuration

**SOLUTION**:
```bash
# Add graph data to configuration
yq eval '.mirror.platform.graph = true' -i "$ISC"

# Verify configuration
yq eval '.mirror.platform.graph' "$ISC"
```

**PREVENTION**:
- Always include `graph: true` for platform mirrors
- Use configuration templates that include required fields
- Document graph data requirements

### **Version Range Errors**
```
ERROR: no releases found matching version criteria
ERROR: minVersion greater than maxVersion
```
**ROOT CAUSE**: Invalid version ranges or non-existent versions

**SOLUTION**:
```bash
# Check available versions
curl -s "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/release.txt"

# Verify version format (must be exact)
# Use: 4.19.2 (not 4.19 or v4.19.2)

# Fix configuration
yq eval '.mirror.platform.channels[0].minVersion = "4.19.2"' -i "$ISC"
yq eval '.mirror.platform.channels[0].maxVersion = "4.19.7"' -i "$ISC"
```

**PREVENTION**:
- Use specific version numbers, not ranges like "stable" or "latest"
- Verify version availability before configuring
- Document version selection strategy

## 🗂️ **Cache Problems**

### **Cache Corruption**
```
ERROR: failed to read cache
ERROR: cache directory is corrupted
ERROR: invalid JSON in cache
```
**ROOT CAUSE**: Corrupted cache files from interrupted operations

**SOLUTION**:
```bash
# Remove corrupted cache (safe - will rebuild)
rm -rf "$CACHE"

# Verify cache directory recreated on next operation
ls -la "$(dirname "$CACHE")"
```

**PREVENTION**:
- Don't interrupt oc-mirror operations
- Use dedicated storage for cache (avoid shared/networked storage)
- Monitor cache integrity: `find "$CACHE" -name "*.json" -exec jq . {} \; >/dev/null`

### **Cache Directory Not Found**
```
ERROR: cache directory does not exist
ERROR: cannot access cache directory
```
**ROOT CAUSE**: Cache directory doesn't exist or wrong path specified

**SOLUTION**:
```bash
# Create cache directory
mkdir -p "$(dirname "$CACHE")"

# Use canonical cache location
export CACHE="$WS/.cache"  # From 04-conventions.md

# Verify cache directory writable
touch "$CACHE/test" && rm "$CACHE/test" && echo "✅ Cache writable"
```

**PREVENTION**:
- Use canonical `$CACHE` variable from [04-conventions.md](../04-conventions.md)
- Create cache directory in setup scripts
- Document cache location requirements

## 🗑️ **Deletion Errors**

### **NoGraphData Error**
```
ERROR: NoGraphData: No graph data found on disk
ERROR: graph data required for delete operation
```
**ROOT CAUSE**: Using separate workspace instead of original mirror workspace

**SOLUTION**:
```bash
# Use ORIGINAL mirror workspace (not separate delete workspace)
oc mirror delete \
    --workspace file://"$WS" \    # Original workspace with graph data
    -c "$DELETE_ISC" \
    --generate

# Verify graph data exists
ls -la "$WS/working-dir/hold-release/cincinnati-graph-data.json"
```

**PREVENTION**:
- Always use original mirror workspace for delete operations  
- Document workspace requirements in deletion procedures
- Validate graph data exists before deletion attempts

### **Delete Plan Not Found**
```
ERROR: delete plan file not found
ERROR: cannot open delete-images.yaml
```
**ROOT CAUSE**: Deletion plan not generated or wrong path specified

**SOLUTION**:
```bash
# Generate deletion plan first
oc mirror delete -c "$DELETE_ISC" --generate --workspace file://"$WS" "$REGISTRY_DOCKER" --v2

# Verify plan exists
DELETION_PLAN="$WS/working-dir/delete/delete-images.yaml"
ls -la "$DELETION_PLAN"

# Use correct path in execution
oc mirror delete --delete-yaml-file "$DELETION_PLAN" "$REGISTRY_DOCKER" --v2
```

**PREVENTION**:
- Always generate deletion plan before execution
- Use canonical variables for plan paths
- Implement plan existence validation in scripts

### **Registry Content Still Present**
```
ERROR: Images still accessible after deletion
WARNING: Deletion completed but images remain
```
**ROOT CAUSE**: Registry garbage collection not run, or deletion didn't complete

**SOLUTION**:
```bash
# Run registry garbage collection (required for space reclamation)
sudo podman exec -it quay-app registry-garbage-collect

# Verify deletion
oc adm release info "$REGISTRY_DOCKER/openshift/release-images:$DELETED_VERSION-x86_64" 2>&1 | \
  grep -q "deleted or has expired" && echo "✅ Deleted" || echo "❌ Still present"

# Check deletion logs for errors
journalctl -u quay-app | grep -i delete
```

**PREVENTION**:
- Always run registry GC after deletions
- Implement deletion verification in automation
- Monitor registry storage usage before/after operations

## 🏭 **Registry Issues**

### **Registry Service Errors**
```
ERROR: registry service unavailable
ERROR: 500 Internal Server Error
```
**ROOT CAUSE**: Registry service problems or misconfigurations

**SOLUTION**:
```bash
# Check registry service
systemctl status quay-app

# Check registry logs
journalctl -u quay-app --since "10 minutes ago"

# Restart registry if needed
sudo systemctl restart quay-app

# Wait for registry to be ready
sleep 30
curl -sk https://"$REGISTRY_FQDN"/v2/
```

**PREVENTION**:
- Implement registry health monitoring
- Set up automated service restart procedures
- Monitor registry logs for early warning signs

### **TLS Certificate Issues**
```
ERROR: x509: certificate signed by unknown authority
ERROR: tls: handshake failure
```
**ROOT CAUSE**: TLS certificate not trusted or expired

**SOLUTION**:
```bash
# Add registry CA to system trust (if custom CA)
sudo cp registry-ca.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust

# Use insecure connection (test environments only)
oc mirror --dest-use-http "$REGISTRY_HTTP" [other-options]

# Skip TLS verification (not recommended for production)
oc mirror --dest-tls-verify=false docker://"$REGISTRY_FQDN" [other-options]
```

**PREVENTION**:
- Use proper TLS certificates in production
- Document certificate installation procedures
- Plan for certificate renewal processes

## 🛠️ **Diagnostic Commands**

### **Environment Health Check**
```bash
#!/bin/bash
# Comprehensive environment diagnostic script

echo "=== oc-mirror Environment Diagnostics ==="

# Tool availability
command -v oc-mirror >/dev/null && echo "✅ oc-mirror available" || echo "❌ oc-mirror not found"
command -v oc >/dev/null && echo "✅ oc available" || echo "❌ oc not found"
command -v podman >/dev/null && echo "✅ podman available" || echo "❌ podman not found"

# Registry connectivity
curl -sk https://"$REGISTRY_FQDN"/v2/ >/dev/null && echo "✅ Registry accessible" || echo "❌ Registry not accessible"

# Authentication
podman login --get-login "$REGISTRY_FQDN" >/dev/null && echo "✅ Registry authentication valid" || echo "❌ Registry authentication failed"

# Storage space
echo "Storage availability:"
df -h "$WS" 2>/dev/null | tail -1 | awk '{print "  Workspace: " $4 " available"}'
df -h "$CACHE" 2>/dev/null | tail -1 | awk '{print "  Cache: " $4 " available"}' || echo "  Cache: Not created yet"

# Configuration validation
[[ -f "$ISC" ]] && echo "✅ ImageSet configuration exists" || echo "❌ ImageSet configuration not found"
[[ -f "$ISC" ]] && yq eval . "$ISC" >/dev/null && echo "✅ Configuration syntax valid" || echo "❌ Configuration syntax invalid"

echo "=== Diagnostics Complete ==="
```

### **Performance Monitoring**
```bash
#!/bin/bash
# Monitor oc-mirror operation performance

echo "=== Performance Monitoring ==="

# Resource usage
echo "System resources:"
echo "  CPU usage: $(top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | sed 's/%us,//')"
echo "  Memory usage: $(free -h | grep 'Mem:' | awk '{print $3 "/" $2}')"
echo "  Disk I/O: $(iostat -x 1 1 | tail -1 | awk '{print $10}' || echo 'iostat not available')"

# Network activity
echo "Network connections:"
netstat -an | grep ":8443" | wc -l | awk '{print "  Registry connections: " $1}'

# Storage usage during operation
echo "Storage usage:"
df -h "$WS" | tail -1 | awk '{print "  Workspace: " $3 " used, " $4 " available"}'
[[ -d "$CACHE" ]] && du -sh "$CACHE" | awk '{print "  Cache size: " $1}' || echo "  Cache: Not created"

echo "=== Monitoring Active ==="
```

## 📋 **Quick Error Reference**

### **Most Common Errors & Fast Fixes**
```bash
# Authentication failed
podman login "$REGISTRY_FQDN"

# Registry not accessible  
curl -sk https://"$REGISTRY_FQDN"/v2/ || systemctl restart quay-app

# No space left
df -h && rm -rf "$CACHE"

# NoGraphData in delete
oc mirror delete --workspace file://"$WS" [other-options]  # Use original workspace

# Configuration invalid
yq eval . "$ISC" || cp config-samples/isc-platform-only.yaml "$ISC"

# Cache corruption
rm -rf "$CACHE"  # Safe - will rebuild

# Network timeout
export HTTP_PROXY="http://proxy:8080" && export HTTPS_PROXY="http://proxy:8080"
```

### **Emergency Recovery Procedures**
```bash
# Complete environment reset
rm -rf "$CACHE"                    # Clean cache
podman login "$REGISTRY_FQDN"      # Re-authenticate
systemctl restart quay-app         # Restart registry
curl -sk https://"$REGISTRY_FQDN"/v2/  # Verify connectivity

# Workspace corruption recovery  
# Backup: tar -czf workspace-backup.tar.gz "$WS"
# Restore: Re-run original mirror operation to rebuild workspace
```

---

## 🤝 **Contributing to Troubleshooting**

Found a new error pattern? Contributing is easy:

1. **Format**: `ERROR MESSAGE → ROOT CAUSE → SOLUTION → PREVENTION`
2. **Test**: Verify solution works in real environment
3. **Document**: Include exact error text and tested commands
4. **Submit**: Add to appropriate category in this reference

See [contributors-guide.md](../contributors-guide.md) for detailed contribution standards.

---

**💡 Pro Tip**: When reporting issues, always include:
- Exact error message
- oc-mirror version: `oc-mirror --v2 version`
- Environment details: OS, registry type, network configuration
- Commands that led to the error
- Current directory and environment variables

**⚡ Quick Diagnostic**: Run the environment health check script above for comprehensive system validation before reporting issues.
