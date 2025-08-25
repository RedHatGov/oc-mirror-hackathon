# Mirror-to-Disk Flow

**oc-mirror --v2 Flow Pattern**

## Overview

The **mirror-to-disk** flow creates portable archive packages of OpenShift content that can be transferred to disconnected environments. This flow downloads content from external registries and packages it into transportable bundles.

## Use Cases

- **Air-gapped environments** - Transfer content across air gaps
- **Bandwidth-constrained sites** - Reduce repeated downloads
- **Offline installations** - Package content for later deployment
- **Content distribution** - Create standardized deployment packages

## Flow Pattern

```mermaid
flowchart LR
    A[External Registry] --> B[oc-mirror --v2]
    B --> C[Local Disk Storage]
    C --> D[Portable Archive]
```

## Key Commands

```bash
# Basic mirror-to-disk operation
oc-mirror -c imageset-config.yaml file://content --v2

# With explicit cache management
oc-mirror -c imageset-config.yaml file://content --v2 --cache-dir .cache
```

## What Gets Created

- **content/** directory with all mirrored images
- **content/working-dir/** with essential metadata
- **Portable archives** ready for transfer

---

## 🚧 **Under Development for Hackathon**

This flow documentation is currently being developed for the oc-mirror hackathon. 

**Coming Soon:**
- Step-by-step procedures
- Configuration examples  
- Troubleshooting guidance
- Integration with other flows

**Related Scripts:** `oc-mirror-master/oc-mirror-to-disk.sh`

**See Also:** [from-disk-to-registry.md](from-disk-to-registry.md) for the complementary upload flow.
