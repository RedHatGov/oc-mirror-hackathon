# oc-mirror v2 Bug Reports and RFEs

This directory contains bug reports and RFEs (Request for Enhancement) discovered during operational testing of oc-mirror v2 air-gapped scenarios.

## 📁 Issue Categories

### **🚀 [enhancements/](enhancements/)**
Feature requests and improvement proposals
- Archive management improvements
- Dry-run capabilities for delete operations
- User experience enhancements

### **🐛 [issues/](issues/)**  
Bug reports and technical problems
- Context timeout during mirroring
- Misleading log output
- Poor error messaging

### **📖 [documentation/](documentation/)**
Documentation gaps and improvements
- Missing procedures and guides
- Inaccurate or outdated content

## Summary of Critical Issues

Based on testing documented in `../docs/workflows/operational-patterns.md`, the following critical issues were identified:

## 🚨 Critical Bugs

### 1. Misleading Log Output ([misleading-log-output.md](./issues/misleading-log-output.md))
- **Type:** Bug
- **Priority:** Major  
- **Issue:** oc-mirror v2 logs claim complete content when archives contain only differential content
- **Impact:** Customers transfer incomplete archive sets, causing failed air-gapped operations
- **Template Source:** [OCPBUGS-54587](https://issues.redhat.com/browse/OCPBUGS-54587)

### 2. Poor Error Messaging ([poor-error-messaging.md](./issues/poor-error-messaging.md))
- **Type:** Bug
- **Priority:** Major
- **Issue:** Cryptic error messages when cumulative content is missing  
- **Impact:** Extended troubleshooting time, increased support cases
- **Template Source:** [OCPBUGS-54587](https://issues.redhat.com/browse/OCPBUGS-54587)

### 3. Context Timeout During Mirroring ([context-timeout-during-mirroring.md](./issues/context-timeout-during-mirroring.md))
- **Type:** Bug
- **Priority:** High
- **Issue:** oc-mirror v2 fails with "context deadline exceeded" during large image downloads
- **Impact:** Extended operations fail unpredictably, blocking air-gapped workflows and upgrades
- **Template Source:** [OCPBUGS-54587](https://issues.redhat.com/browse/OCPBUGS-54587)

## 📋 Enhancement Requests

### 4. Documentation Gap ([documentation-gap.md](./documentation/documentation-gap.md))
- **Type:** RFE
- **Priority:** High
- **Issue:** Missing operational guidance for differential archive behavior
- **Impact:** Customer confusion, failed deployments, poor planning
- **Template Source:** [OCPBUGS-54587](https://issues.redhat.com/browse/OCPBUGS-54587)

### 5. Archive Management ([archive-management.md](./enhancements/archive-management.md))
- **Type:** RFE  
- **Priority:** Normal
- **Issue:** Lack of versioning, metadata, and operational tools for archive management
- **Impact:** Difficult enterprise adoption, limited rollback capabilities
- **Template Source:** [OCPBUGS-54587](https://issues.redhat.com/browse/OCPBUGS-54587)

### 6. Operational User Experience ([operational-ux.md](./enhancements/operational-ux.md))
- **Type:** RFE
- **Priority:** Normal  
- **Issue:** Poor UX for air-gapped operations, insufficient guidance
- **Impact:** Reduced usability, higher learning curve
- **Template Source:** [OCPBUGS-54587](https://issues.redhat.com/browse/OCPBUGS-54587)



## Testing Evidence

All issues are backed by concrete testing evidence documented in:
- `../docs/workflows/operational-patterns.md` - Detailed analysis and findings
- `../docs/guides/airgap-testing.md` - Air-gapped scenario testing  
- Configuration artifacts included in operational patterns document

## Reproducibility

Each bug/RFE includes:
- ✅ **Complete reproduction steps** with actual configurations used
- ✅ **Version information** for all components tested
- ✅ **Expected vs actual results** with specific examples
- ✅ **Customer impact assessment** based on operational scenarios

## Priority Assessment

### High Priority (Customer Blocking)
1. **Misleading Log Output** - Causes immediate operational failures
2. **Context Timeout During Mirroring** - Blocks extended operations and upgrades
3. **Documentation Gap** - Prevents successful air-gapped adoption

### Medium Priority (Operational Impact)  
4. **Poor Error Messaging** - Increases support burden and troubleshooting time
5. **Archive Management** - Limits enterprise operational capabilities

### Lower Priority (User Experience)
6. **Operational UX** - Improves usability but workarounds exist

## Implementation Recommendations

### Phase 1 (Critical Fixes)
- Fix misleading log output to clearly indicate differential content
- Improve error messages with actionable guidance
- Create operational documentation section

### Phase 2 (Operational Enhancement)
- Add archive versioning and metadata features
- Implement validation and packaging commands
- Create interactive operational modes

### Phase 3 (User Experience)
- Enhanced progress reporting and feedback
- Transfer planning assistance tools
- Advanced archive management features

## Testing Environment

**Tested Configuration:**
- **Platform:** AWS Demo Platform
- **OS:** RHEL 10
- **oc-mirror:** v2 (4.19.0-202507292137.p0.gaa8c685.assembly.stream.el9-aa8c685)  
- **OpenShift:** 4.19.2
- **Test Scenario:** Air-gapped operational updates with web-terminal operator addition

**Reference Documentation:**
- [Original Bug Template](https://issues.redhat.com/browse/OCPBUGS-54587) - Used as formatting template
- `operational_patterns.md` - Detailed technical analysis
- `airgap-testing.md` - Testing methodology and results

---

**Created:** August 2025  
**Based on Testing:** Real-world air-gapped operational scenarios  
**Template Source:** Red Hat Issue Tracker OCPBUGS-54587
