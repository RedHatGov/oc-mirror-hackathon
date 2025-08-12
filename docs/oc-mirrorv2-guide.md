# oc-mirror v2 Complete Command Reference Guide

A comprehensive guide to all `oc-mirror --v2` command options, flags, and usage patterns for OpenShift disconnected installations.

## Table of Contents

1. [Overview](#overview)
2. [Command Structure](#command-structure)
3. [Subcommands](#subcommands)
4. [Global Flags Reference](#global-flags-reference)
5. [Destination Types](#destination-types)
6. [Usage Examples](#usage-examples)
7. [Advanced Scenarios](#advanced-scenarios)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)
10. [Migration from v1](#migration-from-v1)

## Overview

The `oc-mirror` plugin version 2 (`--v2`) provides enhanced capabilities for mirroring OpenShift content in disconnected environments. This guide covers all available command-line options and practical usage patterns.

### Key Features of v2
- **Centralized Mirroring**: Unified method for releases, operators, Helm charts, and images
- **Comprehensive Verification**: Ensures complete image set mirroring regardless of prior status
- **Enhanced Caching**: Prevents restart on failures with intelligent cache management
- **Efficient Archives**: Minimal archive sizes with incremental updates
- **Date-Based Selection**: Content filtering by mirroring date
- **Improved Resources**: Generates IDMS/ITMS instead of deprecated ICSP
- **Controlled Deletion**: Manual deletion control without automatic pruning
- **Multi-Enclave Support**: Supports `registries.conf` for multiple destinations

## Command Structure

### Basic Syntax
```bash
oc-mirror [GLOBAL_FLAGS] --v2 [SUBCOMMAND] [FLAGS] [SOURCE] [DESTINATION]
```

### Required Components
- **`--v2`**: Enable version 2 functionality (required)
- **`--config`**: Path to ImageSetConfiguration file (required for most operations)
- **DESTINATION**: Target location (file:// or docker://)

## Subcommands

| Subcommand | Description | Usage |
|------------|-------------|-------|
| `help` | Display help information for any command | `oc-mirror --v2 help [command]` |
| `version` | Show oc-mirror version information | `oc-mirror --v2 version` |
| `delete` | Delete images from registry and local cache | `oc-mirror --v2 delete [options]` |

### Subcommand Examples
```bash
# Show general help
oc-mirror --v2 help

# Show help for delete command
oc-mirror --v2 help delete

# Display version
oc-mirror --v2 version

# Delete operation with config
oc-mirror --v2 delete --config delete-config.yaml
```

## Global Flags Reference

### Configuration & Input Flags

| Flag | Type | Description | Default | Example |
|------|------|-------------|---------|---------|
| `-c, --config` | string | Path to ImageSetConfiguration file | - | `--config isc.yaml` |
| `--authfile` | string | Path to authentication file | `${XDG_RUNTIME_DIR}/containers/auth.json` | `--authfile ~/.docker/config.json` |
| `--from` | string | Path to image set archive for upload | - | `--from file://./mirror-archive` |

#### Configuration Examples
```bash
# Basic configuration
oc-mirror --config imageset-config.yaml --v2 file://./output

# Custom auth file
oc-mirror --config isc.yaml --authfile ~/.config/containers/auth.json --v2 file://./output

# Upload from archive
oc-mirror --config isc.yaml --from file://./archive --v2 docker://registry.example.com:5000
```

### Execution Control Flags

| Flag | Type | Description | Default | Example |
|------|------|-------------|---------|---------|
| `--dry-run` | boolean | Print actions without executing mirroring | `false` | `--dry-run` |
| `--v2` | boolean | Use oc-mirror plugin version 2 | `false` | `--v2` |

#### Execution Examples
```bash
# Validate configuration without mirroring
oc-mirror --config isc.yaml --dry-run --v2 file://./test

# Normal execution
oc-mirror --config isc.yaml --v2 file://./output
```

### Directory & Workspace Flags

| Flag | Type | Description | Default | Example |
|------|------|-------------|---------|---------|
| `--cache-dir` | string | Cache directory location | `$HOME/.oc-mirror` | `--cache-dir ./custom-cache` |
| `--workspace` | string | Workspace for resources and artifacts | Current directory | `--workspace ./work` |

#### Directory Examples
```bash
# Custom cache directory
oc-mirror --config isc.yaml --cache-dir /data/cache --v2 file://./output

# Custom workspace
oc-mirror --config isc.yaml --workspace /tmp/work --v2 file://./output

# Both custom directories
oc-mirror --config isc.yaml --cache-dir ./cache --workspace ./work --v2 file://./output
```

### Network & Security Flags

| Flag | Type | Description | Default | Example |
|------|------|-------------|---------|---------|
| `--dest-tls-verify` | boolean | Verify TLS certificates for destination | `true` | `--dest-tls-verify=false` |
| `--src-tls-verify` | boolean | Verify TLS certificates for source | `true` | `--src-tls-verify=false` |
| `--secure-policy` | boolean | Enable signature verification | `false` | `--secure-policy` |

#### Security Examples
```bash
# Skip TLS verification (testing only)
oc-mirror --config isc.yaml --dest-tls-verify=false --v2 docker://insecure-registry:5000

# Enable signature verification
oc-mirror --config isc.yaml --secure-policy --v2 file://./output

# Skip both source and destination TLS
oc-mirror --config isc.yaml --src-tls-verify=false --dest-tls-verify=false --v2 file://./output
```

### Performance & Limits Flags

| Flag | Type | Description | Default | Example |
|------|------|-------------|---------|---------|
| `--image-timeout` | duration | Timeout for mirroring each image | System default | `--image-timeout=10m` |
| `-p, --port` | int | HTTP port for local storage instance | `55000` | `--port 8080` |
| `--max-nested-paths` | int | Maximum nested paths for registries | `0` (unlimited) | `--max-nested-paths 3` |

#### Performance Examples
```bash
# Set image timeout to 30 minutes
oc-mirror --config isc.yaml --image-timeout=30m --v2 file://./output

# Use custom port for local storage
oc-mirror --config isc.yaml --port 8080 --v2 file://./output

# Limit nested paths for registry constraints
oc-mirror --config isc.yaml --max-nested-paths 2 --v2 docker://registry.example.com:5000
```

### Archive Management Flags

| Flag | Type | Description | Default | Example |
|------|------|-------------|---------|---------|
| `--strict-archive` | boolean | Generate archives strictly under archiveSize | `false` | `--strict-archive` |
| `--since` | string | Include content since date (yyyy-mm-dd) | - | `--since 2024-01-01` |

#### Archive Examples
```bash
# Generate strict archives (fail if exceeding size)
oc-mirror --config isc.yaml --strict-archive --v2 file://./output

# Mirror content since specific date
oc-mirror --config isc.yaml --since 2024-01-01 --v2 file://./output

# Incremental mirror (new content since last run)
oc-mirror --config isc.yaml --v2 file://./output
```

### Logging & Debug Flags

| Flag | Type | Description | Default | Example |
|------|------|-------------|---------|---------|
| `--loglevel` | string | Set log level (info, debug, trace, error) | `info` | `--loglevel debug` |
| `-h, --help` | boolean | Show help information | `false` | `--help` |
| `-v, --version` | boolean | Show version information | `false` | `--version` |

#### Logging Examples
```bash
# Debug level logging
oc-mirror --config isc.yaml --loglevel debug --v2 file://./output

# Trace level (most verbose)
oc-mirror --config isc.yaml --loglevel trace --v2 file://./output

# Error level only
oc-mirror --config isc.yaml --loglevel error --v2 file://./output
```

## Destination Types

### File System Destinations
```bash
# Relative path
file://./mirror-output

# Absolute path
file:///data/mirror-archives

# Current directory
file://.
```

### Registry Destinations
```bash
# Standard registry
docker://registry.example.com:5000

# Registry with namespace
docker://registry.example.com:5000/openshift

# Registry with custom port
docker://mirror-registry.company.com:8443

# Localhost registry
docker://localhost:5000
```

## Usage Examples

### Basic Operations

#### 1. First-Time Mirror to Filesystem
```bash
# Basic mirror operation
oc-mirror --config imageset-config.yaml --v2 file://./mirror-output

# With custom cache location
oc-mirror \
  --config imageset-config.yaml \
  --cache-dir ./custom-cache \
  --v2 \
  file://./mirror-output
```

#### 2. Validate Configuration
```bash
# Dry run to validate configuration
oc-mirror --config imageset-config.yaml --dry-run --v2 file://./test-output

# Dry run with debug logging
oc-mirror \
  --config imageset-config.yaml \
  --dry-run \
  --loglevel debug \
  --v2 \
  file://./test-output
```

#### 3. Mirror to Registry
```bash
# Direct mirror to registry
oc-mirror --config imageset-config.yaml --v2 docker://registry.example.com:5000

# Mirror to registry with authentication
oc-mirror \
  --config imageset-config.yaml \
  --authfile ~/.docker/config.json \
  --v2 \
  docker://registry.example.com:5000
```

#### 4. Upload Archive to Registry
```bash
# Upload from filesystem archive to registry
oc-mirror \
  --config imageset-config.yaml \
  --from file://./mirror-output \
  --v2 \
  docker://registry.example.com:5000

# Upload with custom authentication
oc-mirror \
  --config imageset-config.yaml \
  --from file://./mirror-output \
  --authfile ~/.config/containers/auth.json \
  --v2 \
  docker://registry.example.com:5000/openshift
```

### Intermediate Operations

#### 5. Incremental Updates
```bash
# Mirror new content since specific date
oc-mirror \
  --config imageset-config.yaml \
  --since 2024-01-15 \
  --v2 \
  file://./incremental-mirror

# Regular incremental update (since last run)
oc-mirror \
  --config imageset-config.yaml \
  --cache-dir ./persistent-cache \
  --v2 \
  file://./daily-mirror
```

#### 6. Performance Optimized
```bash
# Large deployment with optimizations
oc-mirror \
  --config large-imageset.yaml \
  --cache-dir /fast-storage/cache \
  --image-timeout=45m \
  --loglevel info \
  --v2 \
  file:///bulk-storage/mirror
```

#### 7. Multi-Registry Support
```bash
# Mirror to multiple registries using same cache
oc-mirror --config isc.yaml --cache-dir ./shared-cache --v2 docker://registry1.example.com:5000
oc-mirror --config isc.yaml --cache-dir ./shared-cache --v2 docker://registry2.example.com:5000
```

## Advanced Scenarios

### Production Environment Setup

#### Enterprise Mirror Operation
```bash
#!/bin/bash
# Production mirroring script

# Configuration
CONFIG_FILE="/etc/oc-mirror/production-imageset.yaml"
CACHE_DIR="/data/oc-mirror-cache"
WORKSPACE="/data/oc-mirror-workspace"
AUTH_FILE="/etc/containers/auth.json"
OUTPUT_DIR="/data/mirror-archives"
LOG_LEVEL="info"

# Create directories
mkdir -p "$CACHE_DIR" "$WORKSPACE" "$OUTPUT_DIR"

# Execute mirror operation
oc-mirror \
  --config "$CONFIG_FILE" \
  --cache-dir "$CACHE_DIR" \
  --workspace "$WORKSPACE" \
  --authfile "$AUTH_FILE" \
  --image-timeout 60m \
  --loglevel "$LOG_LEVEL" \
  --v2 \
  "file://$OUTPUT_DIR"

echo "Mirror operation completed. Archives stored in: $OUTPUT_DIR"
```

#### Registry Upload with Validation
```bash
#!/bin/bash
# Upload script with comprehensive validation

CONFIG_FILE="production-imageset.yaml"
ARCHIVE_DIR="/data/mirror-archives"
REGISTRY_URL="docker://mirror-registry.company.com:5000/openshift"
AUTH_FILE="/etc/containers/auth.json"

# Validate archive exists
if [[ ! -d "$ARCHIVE_DIR" ]]; then
  echo "Error: Archive directory not found: $ARCHIVE_DIR"
  exit 1
fi

# Dry run first
echo "Performing dry run validation..."
oc-mirror \
  --config "$CONFIG_FILE" \
  --from "file://$ARCHIVE_DIR" \
  --authfile "$AUTH_FILE" \
  --dry-run \
  --loglevel debug \
  --v2 \
  "$REGISTRY_URL"

# If dry run succeeds, perform actual upload
if [[ $? -eq 0 ]]; then
  echo "Dry run successful. Proceeding with upload..."
  oc-mirror \
    --config "$CONFIG_FILE" \
    --from "file://$ARCHIVE_DIR" \
    --authfile "$AUTH_FILE" \
    --dest-tls-verify \
    --max-nested-paths 3 \
    --loglevel info \
    --v2 \
    "$REGISTRY_URL"
else
  echo "Dry run failed. Please check configuration."
  exit 1
fi
```

### Air-Gapped Environment Workflow

#### 1. Internet-Connected System (Mirror Creation)
```bash
# Create mirror archive on internet-connected system
oc-mirror \
  --config disconnected-imageset.yaml \
  --cache-dir ./cache \
  --workspace ./workspace \
  --authfile ~/.docker/config.json \
  --strict-archive \
  --loglevel info \
  --v2 \
  file://./airgap-mirror

# Package for transfer
tar -czf airgap-mirror-$(date +%Y%m%d).tar.gz airgap-mirror/
```

#### 2. Air-Gapped System (Mirror Upload)
```bash
# Extract mirror archive
tar -xzf airgap-mirror-20241201.tar.gz

# Upload to internal registry
oc-mirror \
  --config disconnected-imageset.yaml \
  --from file://./airgap-mirror \
  --authfile /etc/containers/auth.json \
  --dest-tls-verify=false \
  --loglevel debug \
  --v2 \
  docker://internal-registry.company.local:5000
```

### Automated CI/CD Integration

#### GitLab CI Pipeline Example
```yaml
mirror-openshift-content:
  stage: mirror
  script:
    - mkdir -p cache workspace output
    - oc-mirror --config $CONFIG_FILE --cache-dir ./cache --workspace ./workspace --authfile $AUTH_FILE --v2 file://./output
    - tar -czf mirror-archive-$CI_PIPELINE_ID.tar.gz output/
  artifacts:
    paths:
      - mirror-archive-*.tar.gz
    expire_in: 1 week
  only:
    - schedules
```

#### Jenkins Pipeline Example
```groovy
pipeline {
    agent any
    environment {
        CONFIG_FILE = 'imageset-config.yaml'
        CACHE_DIR = 'cache'
        WORKSPACE_DIR = 'workspace'
        OUTPUT_DIR = 'mirror-output'
    }
    stages {
        stage('Mirror Content') {
            steps {
                sh '''
                    mkdir -p $CACHE_DIR $WORKSPACE_DIR $OUTPUT_DIR
                    oc-mirror --config $CONFIG_FILE \
                             --cache-dir $CACHE_DIR \
                             --workspace $WORKSPACE_DIR \
                             --loglevel info \
                             --v2 \
                             file://$OUTPUT_DIR
                '''
            }
        }
        stage('Upload to Registry') {
            steps {
                sh '''
                    oc-mirror --config $CONFIG_FILE \
                             --from file://$OUTPUT_DIR \
                             --authfile /var/lib/jenkins/.docker/config.json \
                             --v2 \
                             docker://registry.company.com:5000
                '''
            }
        }
    }
}
```

## Best Practices

### 1. Configuration Management

#### Use Version Control
```bash
# Store configurations in git
git add imageset-config.yaml
git commit -m "Update operator list for production mirror"
git tag mirror-config-v1.2.0
```

#### Environment-Specific Configs
```bash
# Development environment
oc-mirror --config configs/dev-imageset.yaml --v2 file://./dev-mirror

# Staging environment
oc-mirror --config configs/staging-imageset.yaml --v2 file://./staging-mirror

# Production environment
oc-mirror --config configs/prod-imageset.yaml --v2 file://./prod-mirror
```

### 2. Storage and Performance

#### Cache Management
```bash
# Use persistent cache location
export CACHE_DIR="/persistent/storage/oc-mirror-cache"
oc-mirror --config isc.yaml --cache-dir "$CACHE_DIR" --v2 file://./output

# Monitor cache size
du -sh "$CACHE_DIR"

# Clean old cache entries (carefully!)
find "$CACHE_DIR" -type f -mtime +30 -delete
```

#### Archive Optimization
```bash
# Use appropriate archive sizes
# Small environments: 20-50GB
archiveSize: 20

# Medium environments: 50-100GB
archiveSize: 75

# Large environments: 100GB+
archiveSize: 150
```

### 3. Security Best Practices

#### Authentication Management
```bash
# Use dedicated service account
podman login --authfile /etc/oc-mirror/auth.json registry.redhat.io

# Protect auth files
chmod 600 /etc/oc-mirror/auth.json
chown oc-mirror:oc-mirror /etc/oc-mirror/auth.json
```

#### TLS Configuration
```bash
# Production: Always verify TLS
oc-mirror --config isc.yaml --dest-tls-verify --v2 docker://registry.company.com:5000

# Development: May skip for internal testing
oc-mirror --config isc.yaml --dest-tls-verify=false --v2 docker://dev-registry:5000
```

### 4. Monitoring and Logging

#### Structured Logging
```bash
# Create log directory
mkdir -p /var/log/oc-mirror

# Run with timestamped logs
oc-mirror --config isc.yaml --loglevel info --v2 file://./output 2>&1 | \
  tee /var/log/oc-mirror/mirror-$(date +%Y%m%d-%H%M%S).log
```

#### Health Checks
```bash
#!/bin/bash
# Health check script
EXPECTED_SIZE_GB=100
ACTUAL_SIZE=$(du -sg ./mirror-output | cut -f1)

if [[ $ACTUAL_SIZE -lt $EXPECTED_SIZE_GB ]]; then
  echo "WARNING: Mirror size ($ACTUAL_SIZE GB) less than expected ($EXPECTED_SIZE_GB GB)"
  exit 1
fi

echo "Mirror health check passed: $ACTUAL_SIZE GB"
```

### 5. Disaster Recovery

#### Backup Strategies
```bash
# Backup cache and workspace
tar -czf oc-mirror-backup-$(date +%Y%m%d).tar.gz cache/ workspace/ imageset-config.yaml

# Backup to remote storage
rsync -av mirror-output/ backup-server:/backups/oc-mirror/$(date +%Y%m%d)/
```

#### Recovery Procedures
```bash
# Restore from backup
tar -xzf oc-mirror-backup-20241201.tar.gz

# Resume mirror operation
oc-mirror --config imageset-config.yaml --cache-dir ./cache --workspace ./workspace --v2 file://./output
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Authentication Failures
```bash
# Problem: Authentication failed
# Solution: Verify auth file and credentials
podman login --authfile ~/.docker/config.json registry.redhat.io
oc-mirror --config isc.yaml --authfile ~/.docker/config.json --v2 file://./output
```

#### 2. Network Timeouts
```bash
# Problem: Image download timeouts
# Solution: Increase timeout and use debug logging
oc-mirror --config isc.yaml --image-timeout=60m --loglevel debug --v2 file://./output
```

#### 3. Disk Space Issues
```bash
# Problem: Insufficient disk space
# Solution: Monitor and clean up
df -h
du -sh cache/ workspace/ output/

# Clean cache if needed
rm -rf cache/old-content/
```

#### 4. Registry Path Limitations
```bash
# Problem: Registry doesn't support deep paths
# Solution: Limit nested paths
oc-mirror --config isc.yaml --max-nested-paths 2 --v2 docker://registry.example.com:5000
```

#### 5. SSL/TLS Errors
```bash
# Problem: TLS certificate verification failed
# Solution: Skip verification for testing or fix certificates
oc-mirror --config isc.yaml --dest-tls-verify=false --v2 docker://registry.example.com:5000
```

### Debug Commands

#### Verbose Logging
```bash
# Maximum verbosity
oc-mirror --config isc.yaml --loglevel trace --v2 file://./output

# Debug specific issues
oc-mirror --config isc.yaml --dry-run --loglevel debug --v2 file://./output
```

#### Configuration Validation
```bash
# Validate YAML syntax
yamllint imageset-config.yaml

# Test minimal configuration
cat > test-config.yaml << EOF
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
archiveSize: 4
storageConfig:
  local:
    path: ./metadata
mirror:
  platform:
    channels:
    - name: stable-4.19
      minVersion: 4.19.2
      maxVersion: 4.19.2
      type: ocp
    graph: true
EOF

oc-mirror --config test-config.yaml --dry-run --v2 file://./test
```

### Performance Tuning

#### System Resources
```bash
# Monitor system resources during mirroring
watch 'ps aux | grep oc-mirror; df -h; free -h'

# Limit CPU usage if needed
nice -n 10 oc-mirror --config isc.yaml --v2 file://./output
```

#### Network Optimization
```bash
# Use local mirror for faster downloads
export REGISTRY_MIRROR="registry.local.company.com:5000"
oc-mirror --config isc.yaml --v2 file://./output
```

## Migration from v1

### Key Differences

| Aspect | v1 | v2 |
|--------|----|----|
| **Flag** | Default behavior | Requires `--v2` |
| **Resources** | ICSP | IDMS/ITMS |
| **Caching** | Basic | Enhanced with recovery |
| **Archives** | Fixed size | Efficient incremental |
| **Verification** | Partial | Complete image set |
| **Deletion** | Automatic pruning | Manual control |

### Migration Steps

#### 1. Update Commands
```bash
# v1 command
oc-mirror --config isc.yaml file://./output

# v2 equivalent
oc-mirror --config isc.yaml --v2 file://./output
```

#### 2. Update Configuration Files
```yaml
# v2 requires storageConfig section
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
archiveSize: 20
storageConfig:
  local:
    path: ./metadata
mirror:
  # ... rest of configuration
```

#### 3. Update Scripts and Automation
```bash
# Update all scripts to include --v2 flag
sed -i 's/oc-mirror --config/oc-mirror --config/g; s/file:\/\//--v2 file:\/\//g' mirror-scripts/*.sh
```

### Compatibility Notes
- **Configuration files** are largely compatible
- **Archive formats** may differ between versions
- **Resource generation** changes from ICSP to IDMS/ITMS
- **Cache directories** should be separate for v1 and v2

---

## Quick Reference Card

### Essential Commands
```bash
# Dry run validation
oc-mirror --config isc.yaml --dry-run --v2 file://./test

# Basic mirror to filesystem
oc-mirror --config isc.yaml --v2 file://./output

# Mirror to registry
oc-mirror --config isc.yaml --v2 docker://registry.example.com:5000

# Upload archive to registry
oc-mirror --config isc.yaml --from file://./archive --v2 docker://registry.example.com:5000

# Debug with verbose logging
oc-mirror --config isc.yaml --loglevel debug --v2 file://./output
```

### Most Used Flags
```bash
--config           # Configuration file (required)
--v2              # Enable v2 mode (required)
--cache-dir       # Cache location
--workspace       # Working directory
--authfile        # Authentication file
--dry-run         # Validation mode
--loglevel        # Logging level (info, debug, trace, error)
--from            # Archive source for upload
--since           # Date-based incremental mirroring
```

### Flag Categories
- **Required**: `--v2`, `--config`
- **Authentication**: `--authfile`
- **Directories**: `--cache-dir`, `--workspace`
- **Security**: `--dest-tls-verify`, `--src-tls-verify`, `--secure-policy`
- **Performance**: `--image-timeout`, `--port`, `--max-nested-paths`
- **Archives**: `--from`, `--since`, `--strict-archive`
- **Debug**: `--dry-run`, `--loglevel`, `--help`

---

*Last Updated: December 2024*  
*oc-mirror Version: v2*  
*OpenShift Version: 4.19+*
