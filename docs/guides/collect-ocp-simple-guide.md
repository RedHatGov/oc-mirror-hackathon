# collect_ocp_simple - Quick Reference Guide

A simplified tool collection script for OpenShift disconnected installations.

## 🚀 Quick Start

### 1. Choose Your OpenShift Version

Edit the version in the script:
```bash
# Edit line 14 in collect_ocp_simple
OPENSHIFT_VERSION="stable"        # For latest stable release
# OR
OPENSHIFT_VERSION="4.19.2"       # For specific version
```

### 2. Run the Script

```bash
./collect_ocp_simple
```

**What it does:**
- ✅ Downloads all required OpenShift tools
- ✅ Installs them to system PATH (`/usr/local/bin/`)  
- ✅ Creates versioned filenames (e.g., `openshift-install-linux-4.19.2.tar.gz`)
- ✅ Organizes everything in `downloads/` directory
- ✅ Creates `downloads/install.sh` for disconnected systems

## 📁 What You Get

```
downloads/
├── install.sh*                           # Self-contained installer
├── mirror-registry/                      # Mirror registry components
├── openshift-install-linux-[VERSION].tar.gz  # Version-stamped installer
├── oc-mirror.tar.gz                      # Content mirroring tool
├── openshift-client-linux.tar.gz        # OpenShift CLI
├── butane-amd64                          # Config generator
└── [extracted binaries]*                 # Ready to install
```

## 🔄 Disconnected Workflow

### Connected System:
```bash
./collect_ocp_simple
```

### Transfer to Air-Gapped System:
```bash
# Copy entire downloads directory
scp -r downloads/ user@airgapped-host:/path/
# OR
rsync -av downloads/ /media/usb-drive/
# OR  
tar -czf openshift-tools.tar.gz downloads/
```

### Air-Gapped System:
```bash
cd downloads
./install.sh
```

**That's it!** All tools are now installed and ready to use.

## 🎯 Version Examples

### Latest Stable
```bash
OPENSHIFT_VERSION="stable"
./collect_ocp_simple
# Creates: openshift-install-linux-stable.tar.gz
# Installs: Current stable version (e.g., 4.19.7)
```

### Specific Version
```bash
OPENSHIFT_VERSION="4.19.2"
./collect_ocp_simple  
# Creates: openshift-install-linux-4.19.2.tar.gz
# Installs: Exact version 4.19.2
```

## ✅ Verification

After installation, verify all tools work:
```bash
oc version
openshift-install version
oc-mirror --help
butane --help
```

## 🆚 vs. Old collect_ocp Script

| Feature | Old `collect_ocp` | New `collect_ocp_simple` |
|---------|------------------|-------------------------|
| **Lines of code** | 567 lines | 73 lines (87% reduction) |
| **Version support** | Complex logic | Simple `OPENSHIFT_VERSION="4.19.2"` |
| **File naming** | Generic | Version-stamped |
| **Organization** | Scattered | All in `downloads/` |
| **Disconnected support** | Manual | Automatic `install.sh` |
| **Maintenance** | Complex | Simple |

## 📋 Requirements

- **Linux system** with bash, curl, tar
- **Internet access** for downloading (connected phase)
- **sudo access** for installing to `/usr/local/bin/`
- **Storage**: ~1GB for downloads

---

*Simple, clean, and designed for disconnected OpenShift workflows.*
