# [v2] oc-mirror v2 needs improved operational user experience for air-gapped environments

**Type:** RFE (Request for Enhancement)  
**Priority:** Normal  
**Component:** oc-mirror  
**Labels:** v2, user-experience, operational, air-gapped  

## Description

**Description of problem:**

oc-mirror v2's operational user experience for air-gapped environments needs improvement to reduce confusion, errors, and support burden. Current behavior assumes deep technical knowledge and provides little guidance for common operational scenarios.

**Version-Release number of selected component:**
- oc-mirror v2 (4.19.0-202507292137.p0.gaa8c685.assembly.stream.el9-aa8c685)
- OpenShift 4.19.2

**How reproducible:**
Always - affects user experience for operational scenarios

**Current User Experience Issues:**

1. **Unclear Operational Mode:**
   - No indication whether operation is initial or update
   - No feedback about content type (complete vs differential)
   - No guidance about transfer requirements

2. **Insufficient Progress Information:**
   - Size reductions not explained (24GB → 5.5GB)
   - No indication of cumulative requirements
   - Confusing success messages for differential operations

3. **Limited Air-Gapped Guidance:**
   - No built-in validation for air-gapped readiness
   - No transfer size estimates
   - No dependency checking

**Requested Enhancements:**

### 1. Enhanced Operational Feedback
```bash
# Example improved output:
[INFO] : 🔍 Detected previous mirror content in cache
[INFO] : 🔄 Operation mode: INCREMENTAL UPDATE 
[INFO] : 📊 Content analysis:
[INFO] :   - Previous images: 192 (cached)
[INFO] :   - New images: 5 (web-terminal operator)
[INFO] :   - Total images: 197
[INFO] : 📦 Archive strategy: DIFFERENTIAL (requires previous content)
[INFO] : 🚚 Air-gapped transfer requirements:
[INFO] :   - Current archives: 5.5GB
[INFO] :   - Required previous content: 24GB (from cache or previous archives)
[INFO] :   - Total transfer needed: 29.5GB
```

### 2. Air-Gapped Readiness Validation
```bash
# New flag to validate air-gapped readiness
oc-mirror --validate-airgap-ready

[INFO] : 🔍 Air-gapped readiness check:
[✓] : Archive generation complete
[✓] : Content integrity verified  
[!] : DIFFERENTIAL archives detected
[!] : Air-gapped environment will need:
[INFO] :   - Previous archives: 24GB
[INFO] :   - Current archives: 5.5GB
[INFO] :   - Alternative: Use --cumulative-archives for self-contained set
```

### 3. Operational Mode Selection
```bash
# New flags for clearer operational intent
oc-mirror --mode=initial          # First-time complete mirror
oc-mirror --mode=update           # Incremental update (current behavior)
oc-mirror --mode=cumulative       # Self-contained complete archives
oc-mirror --mode=airgap-ready     # Optimize for air-gapped transfer
```

### 4. Transfer Planning Assistance
```bash
# New command to help plan transfers
oc-mirror transfer-plan

[INFO] : 📋 Transfer Planning Report:
[INFO] : Archive Generation: v2-20240901
[INFO] : Content Type: Differential
[INFO] : 
[INFO] : Air-Gapped Transfer Options:
[INFO] : 
[INFO] : Option 1 - Differential (Current):
[INFO] :   - Transfer size: 29.5GB (5.5GB new + 24GB previous)
[INFO] :   - Files to transfer: 5 archives total
[INFO] :   - Complexity: Medium (requires previous content)
[INFO] : 
[INFO] : Option 2 - Cumulative (Recommended):
[INFO] :   - Rerun with: oc-mirror --cumulative-archives
[INFO] :   - Transfer size: ~22GB (optimized complete set)
[INFO] :   - Files to transfer: 3-4 archives
[INFO] :   - Complexity: Low (self-contained)
```

### 5. Interactive Mode for Complex Operations
```bash
# Interactive mode for operational guidance
oc-mirror --interactive

? What type of operation are you performing?
  ○ Initial mirror (first time)
  ○ Regular update (monthly/quarterly)
  ○ Major version upgrade
  ● Air-gapped preparation

? How will you transfer content to air-gapped environment?
  ○ Network transfer (rsync/scp)
  ● Physical media (DVD/USB)
  ○ Secure file transfer

? What is your media capacity constraint?
  ○ No constraint
  ● DVD (4.7GB per disc)
  ○ Single-layer BD (25GB)
  ○ Dual-layer BD (50GB)

[INFO] : Based on your selections:
[INFO] : - Using --archiveSize=4 for DVD compatibility
[INFO] : - Enabling --cumulative-archives for self-contained transfer
[INFO] : - Will generate ~5 DVD-ready archives
```

### 6. Better Error Recovery
```bash
# Enhanced error messages with recovery suggestions
[ERROR] : Differential archive upload failed - missing dependencies

[INFO] : 🔧 Recovery Options:
[INFO] : 
[INFO] : Option 1 - Provide Previous Content:
[INFO] :   - Copy previous archives to content/ directory
[INFO] :   - Ensure cache directory is available
[INFO] : 
[INFO] : Option 2 - Generate Cumulative Archives:
[INFO] :   - Run: oc-mirror --cumulative-archives [original command]
[INFO] :   - Will create self-contained archive set
[INFO] : 
[INFO] : Option 3 - Validation:
[INFO] :   - Run: oc-mirror --validate-content
[INFO] :   - Check what content is available vs required
```

**Additional info:**

**User Experience Goals:**
- Reduce confusion about differential vs complete content
- Provide clear guidance for air-gapped scenarios  
- Offer actionable recovery options for errors
- Support different operational patterns and constraints

**Customer Benefits:**
- Reduced time to success for air-gapped operations
- Lower support case volume
- Improved confidence in disconnected installations
- Better planning for bandwidth and storage requirements

**Implementation Considerations:**
- Backward compatibility with existing workflows
- Progressive enhancement (new features optional)
- Clear documentation for each enhancement
- Integration with existing archive management features

**Customer Impact:** Medium - Significant improvement in operational user experience

**Reference:** operational_patterns.md documents user experience challenges discovered during testing
