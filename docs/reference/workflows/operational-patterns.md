# oc-mirror v2 Operational Patterns - Critical Discoveries

This document captures critical operational behaviors discovered during testing that fundamentally impact how customers should plan air-gapped OpenShift deployments with oc-mirror v2.

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Critical Discovery](#critical-discovery)
3. [Testing Evidence](#testing-evidence)
4. [Operational Implications](#operational-implications)
5. [Recommended Customer Patterns](#recommended-customer-patterns)
6. [Common Misconceptions](#common-misconceptions)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

## Executive Summary

**🚨 CRITICAL FINDING:** oc-mirror v2 creates **differential archives**, not self-contained complete archives, despite misleading log output that suggests otherwise.

**Key Impact:** Air-gapped customers cannot simply transfer the latest archive set - they must maintain and transfer cumulative content or risk failed mirror operations.

## Critical Discovery

### The Problem

During operational testing, we discovered that oc-mirror v2's behavior differs significantly from expectations:

**What Customers Expect:**
```bash
# Run 1: Creates complete archive set (24GB)
# Run 2: Creates new complete archive set (5.5GB) with ALL content
# Transfer: Only latest archive set needed ❌ WRONG!
```

**What Actually Happens:**
```bash
# Run 1: Creates complete archive set (24GB) 
# Run 2: Creates differential archive (5.5GB) with ONLY new content
# Transfer: Need ALL archives or cached content ✅ REALITY!
```

### Test Configuration Artifacts

#### Baseline Configuration (imageset-config.yaml)
```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
# archiveSize: 8 # only used in mirror-to-disk flow 
mirror:
  platform:
    channels:
    - name: stable-4.19
      minVersion: 4.19.2
      maxVersion: 4.19.2 
    graph: true
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.19
      packages:
        - name: web-terminal
  additionalImages: 
    - name: registry.redhat.io/ubi9/ubi:latest
```

### Evidence of Differential Behavior

#### Test Scenario
- **Baseline**: OpenShift 4.19.2 + ubi9 image (192 images, 24GB in 4 archives)
- **Update**: Added web-terminal operator (5 additional images)
- **Result**: Single 5.5GB archive claiming "197 images mirrored successfully"

#### The Failed Test
```bash
# Attempted to upload only the new 5.5GB archive to fresh registry namespace
oc-mirror -c imageset-config.yaml --from file://content docker://$(hostname):8443/seq2 --v2

# Result: FAILED with error:
# error processing graph image in local cache: 
# reading manifest latest in localhost:55000/openshift/graph-image: manifest unknown
```

#### Size Analysis
- **New archive**: 5.5GB (claims 197 images)
- **Cache directory**: 23GB (contains original content)
- **Total needed**: 28.5GB (archive + cache)

## Operational Implications

### For Customer Air-Gapped Operations

#### ❌ **WRONG Approach (Common Misconception)**
```bash
# Monthly update cycle - FAILS!
1. Run oc-mirror.sh on internet-connected system
2. Transfer only new archives (5.5GB) 
3. Upload to air-gapped registry → FAILS!
```

#### ✅ **CORRECT Approach (Cumulative Transfer)**
```bash
# Monthly update cycle - SUCCESS!
1. Run oc-mirror.sh on internet-connected system  
2. Transfer ALL archives from ALL runs (cumulative)
3. Upload complete archive set to air-gapped registry
```

### Bandwidth and Storage Impact

#### Cumulative Growth Pattern
```bash
# Month 1: Transfer 24GB (baseline)
# Month 2: Transfer 29.5GB (baseline + web-terminal)  
# Month 3: Transfer 35GB+ (baseline + all operators)
# Pattern: Always growing, never just differential
```

#### Storage Requirements
```bash
# Internet-connected system:
archives/
├── 2024-08/          # Month 1 archives (24GB)
├── 2024-09/          # Month 2 archives (29.5GB)  
└── 2024-10/          # Month 3 archives (35GB+)

# Air-gapped system:
# Must store complete archive set for each update
```

## Recommended Customer Patterns

### Pattern 1: Cumulative Archive Management (Recommended)

#### Internet-Connected System Process
```bash
# Monthly update workflow
cd /mirror-operations/$(date +%Y-%m)

# 1. Update configuration for new content
vi imageset-config.yaml  # Add new operators, versions, etc.

# 2. Generate new archive set
./oc-mirror.sh

# 3. Package complete archive set for transfer
tar -czf monthly-update-$(date +%Y%m%d).tar.gz content/

# 4. Transfer to air-gapped environment
# NOTE: Complete archive set, not just new files
```

#### Air-Gapped System Process
```bash
# Monthly update application  
cd /mirror-operations

# 1. Extract complete archive set
tar -xzf monthly-update-YYYYMMDD.tar.gz

# 2. Replace previous content completely
rm -rf /previous/content/
mv content/ /mirror/location/

# 3. Upload complete set to registry
./oc-mirror-to-registry.sh
```

### Pattern 2: Versioned Archive Strategy

#### Directory Structure
```bash
mirror-operations/
├── baseline-2024-08/        # Initial OpenShift 4.19.2
│   └── content/             # 24GB
├── update-2024-09/          # + web-terminal 
│   └── content/             # 29.5GB (cumulative)
└── update-2024-10/          # + additional operators
    └── content/             # 35GB+ (cumulative)
```

#### Benefits
- **Rollback capability**: Keep previous versions  
- **Clear versioning**: Explicit update tracking
- **Audit trail**: Complete change history

### Pattern 3: Cache Synchronization (Advanced)

#### For Large Operations Teams
```bash
# Synchronize cache directory between systems
# Complex but potentially more efficient for frequent updates
rsync -av .cache/ airgapped-system:/mirror/.cache/
rsync -av content/ airgapped-system:/mirror/content/
```

**⚠️ Warning:** This approach requires careful cache management and is prone to synchronization issues.

## Common Misconceptions

### Misconception 1: "Latest Archive Contains Everything"
**Reality:** Latest archive contains only differential content since last run.

### Misconception 2: "Log Output Shows Archive Content"  
**Reality:** Log output shows cumulative mirrored content across all runs, not individual archive content.

### Misconception 3: "Smaller Archive = More Efficient"
**Reality:** Smaller archives require larger total transfers due to cumulative requirements.

### Misconception 4: "oc-mirror v2 is Fully Incremental"
**Reality:** oc-mirror v2 is differential but requires cumulative content for operations.

## Best Practices

### For Customer Success

#### 1. Plan for Cumulative Transfers
- **Budget bandwidth** for growing archive sizes
- **Plan storage** for multiple archive generations  
- **Test restoration** from archive sets regularly

#### 2. Maintain Clear Versioning
```bash
# Use consistent naming patterns
archives/
├── ocp-4.19.2-baseline-20240801.tar.gz
├── ocp-4.19.2-webterminal-20240901.tar.gz  
└── ocp-4.19.2-logging-20241001.tar.gz
```

#### 3. Validate Before Production
```bash
# Always test archive transfers in staging
# Verify complete content with fresh registry uploads
oc-mirror --from file://content docker://test-registry/validation --v2
```

#### 4. Document Content Changes
```bash
# Maintain change log for each archive generation
echo "Added web-terminal operator" >> archives/changes-20240901.log
echo "Added cluster-logging operator" >> archives/changes-20241001.log
```

### For Air-Gapped Environments

#### 1. Complete Replacement Strategy
```bash
# Always replace entire archive set, never merge
rm -rf /current/content/
tar -xzf /incoming/archives.tar.gz
```

#### 2. Verification Process
```bash
# Verify archive integrity before upload
tar -tf archives.tar.gz | head -20
du -sh content/
```

#### 3. Rollback Preparation
```bash
# Maintain previous working archive set
mv /current/content/ /backup/content-previous/
```

## Troubleshooting

### Common Issues

#### 1. "manifest unknown" Error
```bash
# Symptom: Upload fails with manifest errors
# Cause: Missing content from previous runs
# Solution: Ensure complete archive set transfer
```

#### 2. Incomplete Operator Installation
```bash
# Symptom: Operators fail to install from mirror
# Cause: Missing dependencies from base images  
# Solution: Use complete cumulative archive set
```

#### 3. Graph Image Errors
```bash
# Symptom: Release processing fails
# Cause: Missing OpenShift graph metadata
# Solution: Include all release content in archive set
```

### Debugging Commands

#### Verify Archive Contents
```bash
# Check what repositories are in archive
tar -tf content/mirror_*.tar | grep "repositories/" | cut -d'/' -f5 | sort -u

# Verify size expectations  
du -sh content/
tar -tf content/mirror_*.tar | wc -l
```

#### Test Archive Completeness
```bash
# Test upload to temporary registry namespace
oc-mirror --from file://content docker://$(hostname):8443/test-$(date +%s) --v2
```

## Implications for Documentation

### Required Updates

1. **Customer Guides**: Must emphasize cumulative transfer requirements
2. **Architecture Docs**: Clarify differential vs incremental behavior  
3. **Sizing Guides**: Account for cumulative growth patterns
4. **Troubleshooting**: Add differential-specific error scenarios

### Training Considerations

1. **Field Teams**: Understand cumulative requirements for customer planning
2. **Support**: Recognize differential behavior in customer issues
3. **Sales**: Set proper expectations for bandwidth and storage growth

## Conclusion

oc-mirror v2's differential behavior creates a **fundamental shift** in operational patterns compared to assumptions. While the tool optimizes content effectively, customers must plan for:

- **Cumulative transfers** rather than incremental
- **Growing bandwidth** requirements over time  
- **Complete archive management** strategies
- **Careful change tracking** across updates

**Success requires understanding that each update operation needs access to all previous content, either through cumulative archives or synchronized cache directories.**

---

**Document Version:** 1.0  
**Last Updated:** August 2025  
**Tested Environment:** AWS Demo Platform, oc-mirror v2 (4.19.0-202507292137)  
**OpenShift Version:** 4.19.2
