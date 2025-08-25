# From-Disk-to-Registry Flow

**oc-mirror --v2 Flow Pattern**

## Overview

The **from-disk-to-registry** flow uploads previously mirrored content from portable archives to a target registry in a disconnected environment. This complements the mirror-to-disk flow for air-gapped deployments.

## Use Cases

- **Air-gapped registry population** - Upload content from portable archives
- **Disconnected mirror setup** - Initialize registries in isolated environments
- **Content deployment** - Deploy pre-packaged content bundles
- **Disaster recovery** - Restore registry content from archives

## Flow Pattern

```mermaid
flowchart LR
    A[Portable Archive] --> B[Disconnected Host]
    B --> C[oc-mirror --v2]
    C --> D[Target Registry]
```

## Key Commands

```bash
# Basic from-disk-to-registry operation
oc-mirror -c imageset-config.yaml --from file://content docker://registry.example.com:8443 --v2

# With explicit cache management
oc-mirror -c imageset-config.yaml --from file://content docker://$(hostname):8443 --v2 --cache-dir .cache
```

## What Happens

- **Extracts** content from portable archives
- **Uploads** images to target registry
- **Creates** fresh local cache as needed
- **Preserves** all metadata and manifests

---

## 🚧 **Under Development for Hackathon**

This flow documentation is currently being developed for the oc-mirror hackathon.

**Coming Soon:**
- Step-by-step procedures
- Configuration examples
- Registry setup requirements
- Troubleshooting guidance

**Related Scripts:** `oc-mirror-master/oc-mirror-from-disk-to-registry.sh`

**See Also:** [mirror-to-disk.md](mirror-to-disk.md) for the complementary download flow.
