# oc-mirror Sequential Workflow Pattern

A production-ready workflow for managing oc-mirror v2 differential archives in operational environments.

## Overview

Based on testing documented in `operational_patterns.md`, this workflow addresses the key challenges of oc-mirror v2's differential behavior by creating a **predictable sequential structure** that operational teams can rely on.

## Key Benefits

✅ **Predictable Structure** - Clear sequence numbering and versioning  
✅ **Operational Clarity** - Explicit differential vs baseline content marking  
✅ **Air-Gapped Ready** - Built-in transfer guidance and dependency tracking  
✅ **Metadata Rich** - Complete operational information for each sequence  
✅ **Team Friendly** - Clear guidance for different operational scenarios  
✅ **Two-Phase Workflow** - Separate mirror-to-disk and disk-to-mirror operations  
✅ **Auto-Generated Scripts** - Self-contained upload scripts for each sequence  
✅ **Mixed Content Support** - Platform + Operators + Additional Images in one workflow  

## Workflow Structure

### Directory Layout
```
content/
├── seq1-baseline/              # Complete initial content
│   ├── mirror_000001.tar       # ~7.8GB
│   ├── mirror_000002.tar       # ~7.5GB  
│   ├── mirror_000003.tar       # ~6.1GB
│   ├── imageset-config.yaml    # Config used for this sequence
│   ├── seq-metadata.yaml       # Operational metadata
│   ├── seq-upload.sh           # Auto-generated upload script
│   └── working-dir/            # Generated after upload
│       └── cluster-resources/  # IDMS/ITMS manifests
├── seq2-20250818-0127/         # Differential update (timestamped)
│   ├── mirror_000001.tar       # Differential archives
│   ├── mirror_000002.tar       # (4 archives total)
│   ├── mirror_000003.tar
│   ├── mirror_000004.tar
│   ├── imageset-config.yaml    # Config used for this sequence
│   ├── seq-metadata.yaml       # Dependencies and transfer info
│   ├── seq-upload.sh           # Auto-generated upload script
│   └── working-dir/            # Generated after upload
│       └── cluster-resources/  # CUMULATIVE IDMS/ITMS manifests
└── seq3-20250818-0155/         # Another differential update
    ├── mirror_000001.tar       # Differential archives
    ├── mirror_000002.tar       # (4 archives total)
    ├── mirror_000003.tar
    ├── mirror_000004.tar
    ├── imageset-config.yaml    # Config used for this sequence
    ├── seq-metadata.yaml
    ├── seq-upload.sh           # Auto-generated upload script
    └── working-dir/            # Generated after upload
        └── cluster-resources/  # CUMULATIVE IDMS/ITMS manifests
```

### Metadata Example
```yaml
# seq-metadata.yaml
sequence_number: 2
description: "20240818-1430"
timestamp: "2024-08-18T14:30:00Z"
content_type: "differential"
oc_mirror_version: "4.19.0-202507292137"
config_file: "imageset-config.yaml"
config_source: "imageset-config.yaml"

archives:
  - name: "mirror_000001.tar"
    size: "5.5G"

air_gapped_transfer:
  complete: false
  dependencies:
    - "seq1"
  differential_size: "5.5G"
  cumulative_size: "29.5G"
```

## Critical Operational Findings

### Two-Phase Process 🎯

**IMPORTANT:** The workflow operates in **two distinct phases**:

#### Phase 1: Mirror-to-Disk (`./oc-mirror-sequential.sh`)
- ✅ **Downloads** content from Red Hat registries
- ✅ **Creates** tar archives for air-gap transfer  
- ✅ **Generates** sequence metadata and upload scripts
- ❌ **Does NOT generate** cluster resources (IDMS/ITMS)

#### Phase 2: Disk-to-Mirror (`./seq-upload.sh`)  
- ✅ **Uploads** content to local mirror registry
- ✅ **Generates** cluster resources (IDMS/ITMS manifests)
- ✅ **Creates** working directories with deployment artifacts
- ✅ **Provides** ready-to-apply OpenShift manifests

### CUMULATIVE Cluster Resources Pattern 🏗️

**Testing Confirmed:** Cluster resources follow a **CUMULATIVE pattern**, not incremental:

| Sequence | Content | IDMS Lines | Pattern |
|----------|---------|------------|---------|
| **seq1-baseline** | Platform only | 18 lines | Platform IDMS |
| **seq2** | + web-terminal | 33 lines | Platform + Operator IDMS |
| **seq3** | + cluster-logging | 36 lines | Platform + All Operators IDMS |
| **seq4** | + ubi9 additional | 36 lines | Same (additionalImages don't add IDMS) |

**Operational Impact:**
- ✅ **Each sequence contains ALL previous content + new additions**  
- ✅ **Cluster resources are complete snapshots, not deltas**
- ✅ **Teams can deploy using ONLY the latest sequence's cluster resources**
- ✅ **No need to apply multiple IDMS/ITMS files in sequence**

## Usage

### 1. Initial Mirror (Baseline)
```bash
# First run - creates complete baseline
./oc-mirror-sequential.sh

# Output:
# 📁 Creating sequence: seq1-baseline (baseline)
# 🔄 Running oc-mirror...
# ✅ COMPLETE CONTENT - Ready for air-gapped transfer
```

### 2. Operational Updates
```bash
# Update imageset-config.yaml with new operators/versions
vi imageset-config.yaml

# Run sequential update
./oc-mirror-sequential.sh

# Output:
# 📁 Creating sequence: seq2-20250818-0127 (differential)
# 📄 Copied configuration to sequence directory for tracking
# ⚠️  DIFFERENTIAL CONTENT - Requires previous sequences
```

### 3. Upload to Mirror Registry (Phase 2)
```bash
# Each sequence includes a self-contained upload script
cd content/seq1-baseline
./seq-upload.sh

# Output:
# [INFO] 📋 Sequence Information:
#   sequence_number: 1
#   description: "baseline"
# [INFO] 📦 Archive Information:
#     - name: "mirror_000001.tar"
#       size: "7.8G"
# [INFO] 🚀 Executing: oc-mirror --from file://. docker://registry:8443 --v2
# ✅ Upload complete - cluster resources generated in working-dir/

# For differential sequences (requires baseline to exist in registry):
cd content/seq2-20250818-0127  
./seq-upload.sh
```

### 4. List Existing Sequences
```bash
./oc-mirror-sequential.sh --list

# Output:
# Existing sequences:
#   seq1-baseline        22G
#   seq2-20240818-1430   5.5G
#   seq3-20240818-1545   3.2G
```

## Air-Gapped Transfer Patterns

### Pattern 1: Complete Baseline Transfer
```bash
# For seq1-baseline (complete content)
tar -czf seq1-baseline.tar.gz -C content seq1-baseline/

# Air-gapped system:
tar -xzf seq1-baseline.tar.gz  
oc-mirror --from file://seq1-baseline docker://registry:8443 --v2
```

### Pattern 2: Cumulative Update Transfer
```bash
# For seq2+ (differential content) - RECOMMENDED
tar -czf cumulative-seq2.tar.gz -C content .

# Air-gapped system:
tar -xzf cumulative-seq2.tar.gz
oc-mirror --from file://seq2-20240818-1430 docker://registry:8443 --v2
# (Requires seq1 content to be available)
```

### Pattern 3: Individual Sequence Management
```bash
# Transfer each sequence individually
tar -czf seq1-baseline.tar.gz -C content seq1-baseline/
tar -czf seq2-20240818-1430.tar.gz -C content seq2-20240818-1430/

# Air-gapped system needs both:
# 1. Extract all sequences
# 2. Ensure previous content available for differential sequences
```

## Operational Scenarios

### Monthly Update Workflow

**Internet-Connected System (Actual Test Results):**
```bash
# Test 1: Baseline (OpenShift 4.19.2 platform)
./oc-mirror-sequential.sh
# → seq1-baseline (22GB, 191 release images)

# Test 2: Add web-terminal operator  
vi imageset-config.yaml  # Add web-terminal
./oc-mirror-sequential.sh
# → seq2-20250818-0127 (30GB, +5 operator images)

# Test 3: Add cluster-logging operator
vi imageset-config.yaml  # Add cluster-logging
./oc-mirror-sequential.sh  
# → seq3-20250818-0155 (32GB, +8 more operator images)

# Test 4: Add UBI9 additional image
vi imageset-config.yaml  # Add additionalImages
./oc-mirror-sequential.sh
# → seq4-20250818-0204 (32GB, +1 additional image)
```

**Air-Gapped Transfer Planning (Actual Sizes):**
- **Test 1**: Transfer 22GB (complete baseline)
- **Test 2**: Transfer 52GB cumulative (differential requires baseline)
- **Test 3**: Transfer 84GB cumulative (differential requires all previous)
- **Test 4**: Transfer 116GB cumulative (mixed content types)

### Major Version Upgrade
```bash
# For major upgrades, create new baseline
# Update imageset-config.yaml to new version
vi imageset-config.yaml  # Change to 4.20.x

./oc-mirror-sequential.sh
# Description: "upgrade-4.20-baseline"
# → Creates new complete baseline for 4.20
```

## Integration with Existing Tools

### Works With Current Scripts
```bash
# Original script still works for simple scenarios
./oc-mirror.sh  # Uses content/ directly

# New script for operational scenarios  
./oc-mirror-sequential.sh  # Uses content/seqX-description/
```

### Registry Upload Integration
```bash
# Standard upload (works with both patterns)
cd content/seq2-20240818-1430/
../../oc-mirror-to-registry.sh

# Each sequence has its own config for reference
cat imageset-config.yaml  # Shows exactly what was mirrored
```

## Troubleshooting

### Script Reliability Improvements

**CRITICAL FIX:** During testing, AWK parsing bugs were discovered and fixed in the `seq-upload.sh` template generation:

#### Original Issue
```bash
# These patterns failed to parse YAML correctly:
awk '/^archives:/,/^[a-z_]+:/' seq-metadata.yaml  # ❌ Stopped immediately  
awk '/^air_gapped_transfer:/,/^[a-z_]+:/' seq-metadata.yaml  # ❌ Stopped immediately
```

#### Fixed Patterns  
```bash
# Corrected patterns that parse YAML properly:
awk '/^archives:/,/^# /' seq-metadata.yaml  # ✅ Captures until next comment
awk '/^air_gapped_transfer:/,0' seq-metadata.yaml  # ✅ Captures to end of file
```

**Status:** All existing and future `seq-upload.sh` scripts now include these fixes.

### Common Issues

#### 1. Missing Dependencies Error
```bash
# If you see "manifest unknown" errors:
# Check metadata for dependencies
cat content/seq2-20240818-1430/seq-metadata.yaml | grep -A5 dependencies

# Ensure previous sequences are available:
ls content/seq1-*

# Compare configurations to understand changes
diff content/seq1-baseline/imageset-config.yaml content/seq2-20240818-1430/imageset-config.yaml
```

#### 2. Transfer Size Planning
```bash
# Check cumulative size before transfer
./oc-mirror-sequential.sh --list
du -sh content/

# Review metadata for specific transfer requirements
grep -r "cumulative_size" content/*/seq-metadata.yaml
```

#### 3. Sequence Validation
```bash
# Validate sequence integrity (future feature)
./oc-mirror-sequential.sh --validate
```

## Best Practices

### For Development Teams
1. **Use descriptive sequence names** (e.g., "webterminal", "logging", "upgrade-4.20")
2. **Document changes** in sequence descriptions  
3. **Test sequences** before production transfer
4. **Validate complete workflow** in staging environment

### For Operations Teams
1. **Plan cumulative transfers** for air-gapped environments
2. **Maintain sequence history** for rollback capabilities
3. **Monitor cumulative sizes** for storage planning
4. **Use metadata files** for operational decisions
5. **Apply ONLY the latest sequence's cluster resources** (CUMULATIVE pattern)
6. **Complete upload phase** before considering cluster resources ready
7. **Test seq-upload.sh scripts** in staging before production use

### For Air-Gapped Environments
1. **Always transfer cumulative content** for differential sequences
2. **Validate metadata** before upload operations
3. **Maintain previous sequences** until confirmed working
4. **Use consistent extraction procedures**

## Migration from Current Workflow

### Step 1: Backup Current Content
```bash
cp -r content/ content-backup/
```

### Step 2: Start Using Sequential Workflow
```bash
# Your next update becomes seq1
./oc-mirror-sequential.sh
# Description: "current-baseline"
```

### Step 3: Operational Updates
```bash
# Continue with sequential pattern
vi imageset-config.yaml  # Make changes
./oc-mirror-sequential.sh
# Description: "monthly-update-sept"
```

## Implementation Notes

### Script Features
- **Automatic sequence numbering** based on existing directories
- **Interactive descriptions** for operational tracking
- **Metadata generation** with operational information
- **Transfer guidance** based on content type
- **Validation support** (ready for future enhancement)

### Customization Options
- **Modify BASE_CONTENT_DIR** to change storage location
- **Adjust metadata format** for organizational requirements
- **Add validation rules** specific to your environment
- **Integrate with existing operational tools**

## Future Enhancements

### Planned Features
1. **Sequence validation** with integrity checking
2. **Automatic cleanup** of old sequences  
3. **Enhanced metadata** with change tracking
4. **Integration APIs** for CI/CD pipelines
5. **Rollback capabilities** with sequence restoration

### Integration Opportunities
1. **GitOps workflows** with sequence versioning
2. **Monitoring integration** with operational metrics
3. **Backup automation** with sequence archiving
4. **Compliance reporting** with change tracking

## Conclusion

This sequential workflow pattern provides operational teams with:

✅ **Predictable processes** for managing oc-mirror v2 differential behavior  
✅ **Clear guidance** for air-gapped transfer requirements  
✅ **Rich metadata** for operational decision making  
✅ **Flexible patterns** supporting different organizational needs  

The workflow addresses the core challenges identified in our testing while maintaining compatibility with existing processes and providing a foundation for future operational enhancements.

---

**Created:** August 2025  
**Based on:** Comprehensive operational testing and `operational_patterns.md` findings  
**Tested Environment:** AWS Demo Platform, OpenShift 4.19.2, oc-mirror v2  
**Test Results:** 
- ✅ **4 sequential mirroring tests** (baseline → web-terminal → cluster-logging → ubi9)
- ✅ **4 successful uploads** to mirror registry with cluster resource generation
- ✅ **Mixed content types validated** (Platform + Operators + Additional Images)
- ✅ **CUMULATIVE pattern confirmed** through IDMS line count analysis
- ✅ **Script reliability fixes applied** and validated
**Status:** Production Ready - Extensively Tested
