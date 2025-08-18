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

## Workflow Structure

### Directory Layout
```
content/
├── seq1-baseline/              # Complete initial content
│   ├── mirror_000001.tar       # ~8GB
│   ├── mirror_000002.tar       # ~8GB  
│   ├── mirror_000003.tar       # ~6GB
│   ├── imageset-config.yaml    # Config used for this sequence
│   └── seq-metadata.yaml       # Operational metadata
├── seq2-20240818-1430/         # Differential update (timestamped)
│   ├── mirror_000001.tar       # ~5.5GB (only web-terminal)
│   ├── imageset-config.yaml    # Config used for this sequence
│   └── seq-metadata.yaml       # Dependencies and transfer info
└── seq3-20240818-1545/         # Another differential update
    ├── mirror_000001.tar       # ~3GB (only logging operator)
    ├── imageset-config.yaml    # Config used for this sequence
    └── seq-metadata.yaml
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
# 📁 Creating sequence: seq2-20240818-1430 (differential)
# 📄 Copied configuration to sequence directory for tracking
# ⚠️  DIFFERENTIAL CONTENT - Requires previous sequences
```

### 3. List Existing Sequences
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

**Internet-Connected System:**
```bash
# Month 1: Baseline
./oc-mirror-sequential.sh
# → seq1-baseline (22GB complete)

# Month 2: Add operators  
vi imageset-config.yaml  # Add web-terminal
./oc-mirror-sequential.sh
# → seq2-20240818-1430 (5.5GB differential)

# Month 3: Add more operators
vi imageset-config.yaml  # Add logging
./oc-mirror-sequential.sh  
# → seq3-20240918-0930 (3.2GB differential)
```

**Air-Gapped Transfer Planning:**
- **Month 1**: Transfer 22GB (complete)
- **Month 2**: Transfer 29.5GB cumulative (or manage sequences)
- **Month 3**: Transfer 32.7GB cumulative (growing pattern)

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
**Based on:** Operational testing and `operational_patterns.md` findings  
**Tested Environment:** AWS Demo Platform, OpenShift 4.19.2, oc-mirror v2  
**Status:** Production Ready
