# 🐛 NAPS Hackathon Bug Filing Guide

**Red Hat Issue Tracker (JIRA) Bug Filing Instructions for oc-mirror v2**

## 🎯 Quick Start

1. **Access JIRA:** [Red Hat Issue Tracker - OCPBUGS Project](https://issues.redhat.com/projects/OCPBUGS/issues)
2. **Create New Issue** using the bug template below
3. **Add Label:** `naps-hackathon`
4. **Update Tracking Table** with your bug details

---

## 📋 Bug Template Format

Use this exact format when creating your JIRA bug report:

### **Title Format:**
```
[v2] oc-mirror v2 [Brief description of the issue]
```

### **Required Fields:**
- **Type:** Bug
- **Priority:** [Critical/Major/Normal/Minor]
- **Component:** oc-mirror
- **Labels:** `v2, naps-hackathon, [additional relevant labels]`

### **Description Template:**

```markdown
## Description

**Description of problem:**
[Clear explanation of what's wrong, what you expected vs. what happened]

**Version-Release number of selected component:**
- oc-mirror v2 [full version string]
- OpenShift [version]

**How reproducible:**
[Always/Sometimes/Rarely - with frequency details]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Actual results:**
[What actually happened - include error messages, logs, screenshots]

**Expected results:**
[What should have happened]

**Additional info:**
[Environment details, workarounds, related issues]

**Customer Impact:** [High/Medium/Low] - [Brief explanation of business impact]

**Reference:** [Link to documentation, testing evidence, or related materials]
```

---

## 🏷️ Required Labels

**Every hackathon bug MUST include:**
- `v2` - Indicates oc-mirror v2 specific issue
- `naps-hackathon` - Identifies bugs from hackathon participants

---

## 📊 Hackathon Bug Tracking Table

**Instructions:** After filing your bug, add a row to this table with your details.

| Participant | JIRA Bug ID | Title | Priority | Component | Status | Notes |
|-------------|-------------|-------|----------|-----------|---------|--------|
| [Your Name] | [OCPBUGS-XXXXX](https://issues.redhat.com/browse/OCPBUGS-XXXXX) | Brief title | Major | oc-mirror | Open | Brief description |
| Kevin O'Donnell | [OCPBUGS-60928](https://issues.redhat.com/browse/OCPBUGS-60928) | oc-mirror --v2 m2m fails when graph is in imageset-config.yaml | Major | oc-mirror | Open | 401 Unauthorized error accessing graph-image |
| Mark Clemente | [OCPBUGS-60929] (https://issues.redhat.com/browse/OCPBUGS-60929)| oc-mirror creates tar file even after errors from image pull| Normal | oc-mirror | Open | |
|Keith Jackson | [OCPBUGS-60917](https://issues.redhat.com/browse/OCPBUGS-60917) | Running oc-mirror as root affects operator index image creation | Normal | oc-mirror | Open | |
| Mark Clemente | [OCPBUGS-60955](https://issues.redhat.com/browse/OCPBUGS-60955)|oc-mirror should create a unique name for mirror.tar file |Unidentified | oc-mirror| Open| |
| Keith Jackson | [OCPBUGS-60956](https://issues.redhat.com/browse/OCPBUGS-60956) | oc-mirror v2 overwrites delete-imageset-config.yaml and delete-images.yaml | Nromal | oc-mirror | Open | |



---



## 🔗 Resources

- **JIRA Project:** [OCPBUGS Issues](https://issues.redhat.com/projects/OCPBUGS/issues)
- **Example Bug:** [OCPBUGS-48842](https://issues.redhat.com/browse/OCPBUGS-48842)
- **oc-mirror Documentation:** [OpenShift Documentation](https://docs.openshift.com)
- **Hackathon Repository:** [oc-mirror-hackathon](https://github.com/RedHatGov/oc-mirror-hackathon)

---

**Happy bug hunting! 🐛🔍**

*Remember: Good bug reports lead to better software for everyone!*
