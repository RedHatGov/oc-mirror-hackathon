# [v2] oc-mirror v2 needs enhanced archive management features for operational environments

**Type:** RFE (Request for Enhancement)  
**Priority:** Normal  
**Component:** oc-mirror  
**Labels:** v2, operational, feature-request, enterprise  

- https://issues.redhat.com/browse/OCPBUGS-54443 EXISTING BUG - 

## Description

**Description of problem:**

oc-mirror v2 lacks operational archive management features needed for enterprise air-gapped environments. Current archive generation resets to `mirror_000001.tar` on each run without versioning, sequencing, or metadata to help customers manage cumulative content across multiple update cycles.

**Version-Release number of selected component:**
- oc-mirror v2 (4.19.0-202507292137.p0.gaa8c685.assembly.stream.el9-aa8c685)
- OpenShift 4.19.2

**How reproducible:**
Always - affects archive management across multiple runs

**Current Limitations:**

1. **No Archive Versioning:**
   - Archives always start with `mirror_000001.tar`
   - No indication of generation or update cycle
   - Difficult to track which archives belong together

2. **No Metadata Generation:**
   - No manifest files describing archive contents
   - No change logs between generations
   - No dependency information for cumulative requirements

3. **No Validation Tools:**
   - No way to verify archive completeness
   - No tools to check cumulative content integrity
   - No validation for air-gapped transfer readiness

4. **Limited Operational Support:**
   - No rollback capabilities
   - No archive set management
   - No cleanup procedures for old generations

**Steps to Reproduce Current Limitations:**

1. Run initial oc-mirror → generates `mirror_000001.tar`, `mirror_000002.tar`, etc.
2. Update configuration and run again → generates new `mirror_000001.tar` (overwrites previous)
3. No way to distinguish between generations
4. No metadata to understand what changed between runs
5. No tools to validate complete archive sets

**Expected results (Requested Features):**

### 1. Archive Versioning
```bash
# Generate versioned archives
content/
├── v1-20240801/
│   ├── mirror_000001.tar
│   ├── mirror_000002.tar
│   └── generation.yaml
└── v2-20240901/
    ├── mirror_000001.tar  # Contains differential content
    └── generation.yaml
```

### 2. Metadata Generation
```yaml
# generation.yaml example
version: "v2-20240901"
timestamp: "2024-09-01T10:30:00Z"
base_version: "v1-20240801" 
changes:
  - added: "web-terminal operator"
  - updated: "none"
archives:
  - name: "mirror_000001.tar"
    size: "5.5GB" 
    content_type: "differential"
    dependencies: ["v1-20240801"]
cumulative_size: "29.5GB"
```

### 3. Archive Management Commands
```bash
# List archive generations
oc-mirror archive list

# Validate archive set completeness  
oc-mirror archive validate --generation v2-20240901

# Package for air-gapped transfer
oc-mirror archive package --generation v2-20240901 --output airgap-update.tar.gz

# Show changes between generations
oc-mirror archive diff v1-20240801 v2-20240901
```

### 4. Operational Features
```bash
# Create cumulative archive set (all content in new archives)
oc-mirror --cumulative-archives

# Cleanup old generations (keep last N)
oc-mirror archive cleanup --keep 3

# Validate air-gapped transfer readiness
oc-mirror archive validate --airgap-ready
```

**Additional info:**

**Business Justification:**
- Enterprise customers need predictable operational procedures
- Air-gapped environments require careful change management
- Compliance requirements may mandate archive retention and traceability
- Operational teams need tools to manage complex update cycles

**Customer Use Cases:**
1. **Monthly Updates:** Track what changes in each update cycle
2. **Compliance:** Maintain audit trail of mirrored content changes  
3. **Rollback:** Ability to revert to previous working archive sets
4. **Multi-Environment:** Consistent archive management across dev/staging/prod
5. **Air-Gapped Operations:** Validated complete archive sets for transfer

**Suggested Implementation Priority:**
1. **High:** Archive versioning and metadata generation
2. **Medium:** Validation and packaging commands
3. **Low:** Advanced management and cleanup features

**Customer Impact:** Medium - Improves operational reliability and enterprise adoption

**Reference:** operational_patterns.md contains detailed requirements analysis and customer workflow patterns
