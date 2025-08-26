# Air-Gapped OpenShift Mirror Testing Scenario

This document outlines a testing scenario to simulate a true air-gapped environment where you have:

- **Internet-connected system**: Can download files and containers (simulated as `ec2-user`)
- **Disconnected system**: Only receives one tar file and must complete mirror setup (simulated as dedicated user)

## Overview

This setup tests the realistic scenario where:
1. Content is downloaded on an internet-connected bastion
2. Content is packaged into a single transferable archive
3. Archive is transferred to a completely isolated system
4. Isolated system completes mirror registry population without internet access

## Prerequisites

- Completed Mirror Registry Setup from main directions.md
- Mirror registry running on bastion host at `$(hostname):8443`
- Registry accessible via DNS (e.g., `bastion.sandboxXXX.opentlc.com:8443`)

## Step 1: Create Dedicated Air-Gapped User

Create a new user that simulates a completely isolated system administrator.

```bash
# Create dedicated user for air-gapped testing
sudo useradd -m -s /bin/bash airgap-admin
sudo passwd airgap-admin

# Verify user creation
sudo su - airgap-admin -c "whoami && pwd"
```

### Restrict Access to ec2-user Files

```bash
# Remove world and group read permissions from ec2-user home
sudo chmod 750 /home/ec2-user

# Verify airgap-admin cannot access ec2-user files
sudo su - airgap-admin -c "ls /home/ec2-user 2>&1"
# Should show "Permission denied"
```

## Step 2: Prepare Transfer Bundle (Internet-Connected System)

As `ec2-user`, create the air-gapped transfer bundle.

### Create Transfer Bundle Directory

```bash
# Create staging directory for transfer bundle
cd ~/oc-mirror-hackathon
mkdir -p transfer-bundle

# Create info file for bundle documentation
cat > transfer-bundle/bundle-info.md << 'EOF'
# Air-Gapped Transfer Bundle

**Created:** $(date)
**Source System:** $(hostname)
**Bundle Contents:**
- downloads/ - OpenShift client tools and mirror-registry
- oc-mirror-master/ - Mirror configuration and scripts (excluding .cache)
- registry-certs/ - SSL certificates for mirror registry trust
- README.md - Setup instructions for air-gapped system

**Registry Information:**
- Registry URL: $(hostname):8443
- DNS Name: $(hostname -f)
EOF
```

### Copy Required Tools and Configuration

```bash
# Copy downloads directory (contains OpenShift tools)
cp -r downloads transfer-bundle/

# Copy oc-mirror configuration (excluding cache)
rsync -av --exclude='.cache' oc-mirror-master/ transfer-bundle/oc-mirror-master/

# IMPORTANT: Exclude tar files from content directory for separate transfer
# This handles scenarios where customers use archiveSize: for DVD burning
echo "📦 Excluding tar files from bundle for separate transfer..."
find transfer-bundle/oc-mirror-master/content/ -name "*.tar" -delete 2>/dev/null || true

# List any tar files that were excluded (for customer reference)
echo "🔍 Tar files to transfer separately:"
find oc-mirror-master/content/ -name "*.tar" -exec ls -lh {} \; 2>/dev/null || echo "No tar files found"

# Copy registry certificates
mkdir -p transfer-bundle/registry-certs
cp ~/quay-install/quay-rootCA/rootCA.pem transfer-bundle/registry-certs/

# Copy registry connection info if available
if [ -f ~/quay-install/quay-config.yaml ]; then
    cp ~/quay-install/quay-config.yaml transfer-bundle/registry-certs/
fi
```

### Create Setup Script for Air-Gapped System

```bash
cat > transfer-bundle/setup-airgapped.sh << 'EOF'
#!/bin/bash

# Air-Gapped System Setup Script
# Run this script as the air-gapped user after extracting the bundle

set -euo pipefail

echo "🚀 Setting up air-gapped mirror environment..."

# Variables
BUNDLE_DIR="$(pwd)"
TOOLS_DIR="$HOME/tools"
REGISTRY_URL="$(hostname):8443"

# Create tools directory
mkdir -p "$TOOLS_DIR"

echo "📦 Installing OpenShift tools..."

# Install oc-mirror
if [ -f "downloads/oc-mirror" ]; then
    cp downloads/oc-mirror "$TOOLS_DIR/"
    chmod +x "$TOOLS_DIR/oc-mirror"
    echo "✅ oc-mirror installed"
else
    echo "❌ oc-mirror not found in bundle"
    exit 1
fi

# Install oc client
if [ -f "downloads/oc" ]; then
    cp downloads/oc "$TOOLS_DIR/"
    chmod +x "$TOOLS_DIR/oc"
    echo "✅ oc client installed"
else
    echo "❌ oc client not found in bundle"
fi

# Add tools to PATH
echo "export PATH=\$HOME/tools:\$PATH" >> ~/.bashrc
export PATH="$HOME/tools:$PATH"

echo "🔐 Setting up registry certificates..."

# Install registry certificate
if [ -f "registry-certs/rootCA.pem" ]; then
    sudo cp registry-certs/rootCA.pem /etc/pki/ca-trust/source/anchors/
    sudo update-ca-trust
    echo "✅ Registry certificate trusted"
else
    echo "❌ Registry certificate not found"
fi

echo "🗂️ Setting up container authentication..."

# Create container config directory
mkdir -p ~/.config/containers

# Prompt for registry credentials
echo "Please provide mirror registry credentials:"
read -p "Registry Username: " REGISTRY_USER
read -s -p "Registry Password: " REGISTRY_PASS
echo

# Create basic auth.json (user will need to add Red Hat pull secret)
cat > ~/.config/containers/auth.json << JSON_EOF
{
  "auths": {
    "$REGISTRY_URL": {
      "auth": "$(echo -n "$REGISTRY_USER:$REGISTRY_PASS" | base64 -w 0)"
    }
  }
}
JSON_EOF

echo "✅ Registry authentication configured"

echo ""
echo "🎯 Air-gapped setup complete!"
echo ""
echo "⚠️  IMPORTANT: Content Tar Files"
echo "If you have separate tar files (from archiveSize: configuration):"
echo "1. Copy all *.tar files to: ~/oc-mirror-master/content/"
echo "2. Ensure file ownership: chown \$USER:\$USER ~/oc-mirror-master/content/*.tar"
echo ""
echo "Next steps:"
echo "1. Add Red Hat pull secret to ~/.config/containers/auth.json"
echo "2. If using separate tar files, copy them to ~/oc-mirror-master/content/"
echo "3. Verify registry connectivity: curl -I https://$REGISTRY_URL"
echo "4. Run mirror-to-mirror operation: cd oc-mirror-master && ./oc-mirror-to-mirror.sh"
echo ""
echo "Tools installed in: $TOOLS_DIR"
echo "Add to current session: export PATH=\$HOME/tools:\$PATH"
EOF

chmod +x transfer-bundle/setup-airgapped.sh
```

### Create Transfer Archive

```bash
# Create dated archive
ARCHIVE_NAME="airgap-bundle-$(date +%Y%m%d-%H%M).tar.gz"

echo "📦 Creating transfer archive: $ARCHIVE_NAME"
tar -czf "$ARCHIVE_NAME" -C transfer-bundle .

# Verify archive contents
echo "📋 Archive contents:"
tar -tzf "$ARCHIVE_NAME" | head -20

# Show archive size
echo "📏 Archive size: $(du -h $ARCHIVE_NAME | cut -f1)"

echo "✅ Transfer bundle created: $ARCHIVE_NAME"
```

## Step 3: Transfer to Air-Gapped Environment

### Option A: Single Bundle Transfer (Default)

Simulate transferring the bundle to the isolated system.

```bash
# Move archive to airgap-admin home directory
sudo mv airgap-bundle-*.tar.gz /home/airgap-admin/
sudo chown airgap-admin:airgap-admin /home/airgap-admin/airgap-bundle-*.tar.gz

# Verify transfer
sudo su - airgap-admin -c "ls -la airgap-bundle-*.tar.gz"
```

### Option B: Separate Content Transfer (DVD/Media Scenario)

If you created the bundle excluding tar files (for DVD burning scenarios):

```bash
# Transfer the main bundle (tools, configs, metadata)
sudo mv airgap-bundle-*.tar.gz /home/airgap-admin/
sudo chown airgap-admin:airgap-admin /home/airgap-admin/airgap-bundle-*.tar.gz

# Separately transfer the content tar files (simulate DVD/media transfer)
echo "📀 Simulating separate content media transfer..."
sudo mkdir -p /home/airgap-admin/content-media/
sudo cp oc-mirror-master/content/*.tar /home/airgap-admin/content-media/ 2>/dev/null || echo "No tar files to transfer separately"
sudo chown -R airgap-admin:airgap-admin /home/airgap-admin/content-media/

# Verify both transfers
echo "📋 Main bundle:"
sudo su - airgap-admin -c "ls -la airgap-bundle-*.tar.gz"
echo "📋 Content media:"
sudo su - airgap-admin -c "ls -la content-media/"
```

### Customer DVD Burning Workflow

For real-world customers using `archiveSize:`:

```bash
# Example: Customer burns multiple DVDs
# DVD 1: airgap-bundle-YYYYMMDD-HHMM.tar.gz (tools, configs, metadata)
# DVD 2: mirror_000001.tar (content part 1)  
# DVD 3: mirror_000002.tar (content part 2)
# DVD N: mirror_00000N.tar (content part N)

# Air-gapped system receives:
# 1. Main bundle from DVD 1
# 2. Content tar files from DVDs 2-N
# 3. Copies content tars to ~/oc-mirror-master/content/
# 4. Runs oc-mirror-to-mirror.sh
```

## Step 4: Air-Gapped System Setup

Switch to the air-gapped user and set up the environment.

```bash
# Switch to air-gapped user
sudo su - airgap-admin

# Extract the bundle
tar -xzf airgap-bundle-*.tar.gz

# If using separate content transfer (DVD scenario), restore content files
if [ -d "content-media" ]; then
    echo "📀 Restoring content files from separate media..."
    cp content-media/*.tar oc-mirror-master/content/
    echo "✅ Content files restored to oc-mirror-master/content/"
fi

# Run setup script
./setup-airgapped.sh
```

### Complete Authentication Setup

As the `airgap-admin` user, complete the authentication configuration:

```bash
# First, you need to add the Red Hat pull secret to your auth.json
# The setup script created a basic auth.json with registry credentials
# You need to merge in the Red Hat pull secret

# View current auth.json
cat ~/.config/containers/auth.json

# Edit to add Red Hat pull secret
# You'll need to manually merge the auths sections
vi ~/.config/containers/auth.json
```

**Expected auth.json format:**
```json
{
  "auths": {
    "bastion.sandboxXXX.opentlc.com:8443": {
      "auth": "aW5pdDpZT1VSX1JFR0lTVFJZX1BBU1NXT1JE"
    },
    "cloud.openshift.com": {
      "auth": "YOUR_RED_HAT_AUTH_STRING",
      "email": "your-email@example.com"
    },
    "quay.io": {
      "auth": "YOUR_QUAY_AUTH_STRING",
      "email": "your-email@example.com"  
    },
    "registry.redhat.io": {
      "auth": "YOUR_REDHAT_AUTH_STRING",
      "email": "your-email@example.com"
    },
    "registry.connect.redhat.com": {
      "auth": "YOUR_CONNECT_AUTH_STRING",
      "email": "your-email@example.com"
    }
  }
}
```

### Test Registry Connectivity

```bash
# Test registry certificate trust
curl -I https://$(hostname):8443

# Test registry authentication  
podman login $(hostname):8443
```

## Step 5: Execute Mirror-to-Registry (Air-Gapped)

Now perform the final mirror operation as the air-gapped user.

### Run the Mirror-to-Registry Operation

```bash
# Navigate to oc-mirror directory
cd ~/oc-mirror-master

# Verify we have the necessary configuration
ls -la imageset-config.yaml oc-mirror-to-mirror.sh

# Execute the mirror-to-mirror operation
./oc-mirror-to-mirror.sh
```

### Monitor the Upload Process

The script will:
1. Read from the previously downloaded content (from the bundle)
2. Upload all images to your mirror registry
3. Generate IDMS and ITMS files for cluster installation

### Verify Success

```bash
# Check generated cluster resources
ls -la content/working-dir/cluster-resources/

# Verify images in registry (via web interface)
echo "🌐 Access registry at: https://$(hostname):8443"

# Check specific image upload
oc-mirror list --config imageset-config.yaml --dest-tls-verify=false docker://$(hostname):8443
```

## Step 6: Validation and Testing

### Verify Air-Gapped Operation

Confirm the air-gapped user successfully completed the mirror operation:

```bash
# As airgap-admin, verify cluster resources exist
cat content/working-dir/cluster-resources/idms-oc-mirror.yaml
cat content/working-dir/cluster-resources/itms-oc-mirror.yaml

# Verify no access to original ec2-user content
ls /home/ec2-user # Should fail with permission denied
```

### Test Registry Access

```bash
# Test registry via browser
# Navigate to: https://bastion.sandboxXXX.opentlc.com:8443

# Verify mirrored content appears in registry interface
# Should see repositories like:
# - openshift/release
# - openshift/release-images
```

## Clean Up

When testing is complete, you can clean up the air-gapped user:

```bash
# Exit from airgap-admin session
exit

# As ec2-user, remove test user if desired
# sudo userdel -r airgap-admin

# Remove transfer bundles if desired  
# rm -f ~/oc-mirror-hackathon/airgap-bundle-*.tar.gz
# rm -rf ~/oc-mirror-hackathon/transfer-bundle
```

## Troubleshooting Air-Gapped Setup

### Common Issues

#### 1. Certificate Trust Issues
```bash
# Verify certificate is trusted
curl -I https://$(hostname):8443

# Re-trust certificate if needed
sudo cp registry-certs/rootCA.pem /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
```

#### 2. Authentication Problems
```bash
# Test registry login
podman login $(hostname):8443

# Verify auth.json format
cat ~/.config/containers/auth.json | jq '.'
```

#### 3. Missing Tools
```bash
# Verify tools are available
which oc-mirror
which oc

# Add to PATH if needed
export PATH=$HOME/tools:$PATH
```

#### 4. Permission Issues
```bash
# Fix file permissions
chmod 600 ~/.config/containers/auth.json

# Verify user can't access ec2-user files
ls /home/ec2-user # Should show "Permission denied"
```

## Summary

This air-gapped testing scenario validates:

✅ **Content Portability**: OpenShift tools and configuration can be bundled and transferred  
✅ **User Isolation**: Air-gapped user operates independently without access to original content  
✅ **Certificate Management**: SSL certificates are properly distributed and trusted  
✅ **Authentication**: Registry credentials work in isolated environment  
✅ **Mirror Operation**: Content can be pushed to registry without internet access  
✅ **Resource Generation**: Cluster installation resources are properly created  

This approach closely mimics real-world air-gapped deployments where content must be transferred via physical media or highly restricted network transfers.

---

*Testing Environment: AWS Demo Platform*  
*Created: $(date)*  
*OpenShift Version: 4.19.2*

