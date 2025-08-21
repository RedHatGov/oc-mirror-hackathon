# [v2] oc-mirror v2 delete command lacks --dry-run capability for safe operational validation

**Type:** RFE (Request for Enhancement)  
**Priority:** High  
**Component:** oc-mirror  
**Labels:** v2, operational-safety, user-experience, delete-operations  

## Description

**Description of problem:**

oc-mirror v2's `delete` command does not support `--dry-run` functionality, preventing operators from safely validating what content would be deleted before executing destructive operations. This creates significant operational risk in production mirror registry environments where accidental deletion could disrupt disconnected OpenShift operations.

**Version-Release number of selected component:**
- oc-mirror v2 (4.19.0-202507292137.p0.gaa8c685.assembly.stream.el9-aa8c685)
- OpenShift 4.19.7
- Mirror Registry v1.3.10

**How reproducible:**
Always - missing functionality affects all delete operations

**Steps to Reproduce:**

1. Create an imageset configuration for deletion:
```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
archiveSize: 8
storageConfig:
  local:
    path: ./delete-metadata
mirror:
  platform:
    channels:
    - name: stable-4.19
      minVersion: 4.19.2
      maxVersion: 4.19.6  # Target old versions for deletion
    graph: true
```

2. Attempt to use --dry-run with delete command:
```bash
oc-mirror --v2 delete --config imageset-delete.yaml --generate --dry-run
```

**Actual results:**

```
2025/08/20 02:45:03  [ERROR]  : [Executor] unknown flag: --dry-run 
```

The delete command fails and shows help text, confirming --dry-run is not supported.

**Expected results:**

The command should support `--dry-run` functionality to:
- Show what images/manifests would be deleted without executing
- Generate delete YAML file for inspection
- Validate configuration without risk
- Provide size estimates of content to be removed

## Customer Impact

**Operational Risk:**
- **High**: Accidental deletion of required content in production registries
- **Medium**: No validation capability before destructive operations
- **Medium**: Increased support burden from deletion errors

**Business Impact:**
- Production mirror registries at risk without validation capability
- Operations teams cannot safely plan cleanup operations
- Extended downtime possible from accidental content deletion

**Affected Scenarios:**
1. **Registry Cleanup:** Removing old OpenShift versions after upgrades
2. **Storage Management:** Clearing unused operator content
3. **Compliance Operations:** Systematic removal of deprecated images
4. **Operational Planning:** Estimating storage reclamation

## Proposed Enhancement

**Add --dry-run flag to delete command:**

```bash
# Validate what would be deleted
oc-mirror --v2 delete --config imageset-delete.yaml --generate --dry-run

# Show deletion plan with size estimates  
oc-mirror --v2 delete --delete-yaml-file delete-images.yaml --dry-run
```

**Expected dry-run output:**
```
[INFO] DRY RUN MODE - No deletion will occur
[INFO] Would generate delete configuration:
[INFO]   - Platform releases: 4.19.2, 4.19.3, 4.19.4, 4.19.5, 4.19.6
[INFO]   - Estimated size reduction: ~45GB
[INFO] Generated delete YAML: delete-images.yaml (review before execution)
[INFO] To execute: oc-mirror --v2 delete --delete-yaml-file delete-images.yaml
```

## Benefits

**Operational Safety:**
- Zero-risk validation of delete operations
- Configuration verification before execution  
- Size and impact estimation
- Prevention of accidental deletions

**Production Readiness:**
- Safe cleanup operations in production registries
- Planned storage management with impact assessment
- Compliance-friendly operational procedures
- Reduced risk of operational disruption

**User Experience:**
- Clear feedback about deletion scope and impact
- Confidence in cleanup operations
- Better operational planning capabilities
- Reduced support escalations from deletion errors

## Current Workaround

Currently, operators must:
1. Generate delete YAML file with `--generate`  
2. Manually inspect the generated file
3. Hope the configuration is correct
4. Execute deletion with no safety validation

This workaround is error-prone and lacks the safety validation that --dry-run would provide.

---

**Enhancement Requirement:** Add `--dry-run` flag support to `oc-mirror --v2 delete` command for safe operational validation before executing destructive delete operations.

**Template Source:** [OCPBUGS-54587](https://issues.redhat.com/browse/OCPBUGS-54587)
