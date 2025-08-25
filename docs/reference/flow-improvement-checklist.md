# Flow Improvement Checklist

**Systematic framework for improving oc-mirror flow documentation**

This checklist provides a standardized approach for enhancing flow documentation based on the successful transformation of `mirror-to-registry.md` and `mirror-to-disk.md`.

---

## 📋 Content Structure Framework

### **✅ Prerequisites & Environment Assessment**
- [ ] **Clear environment requirements** - RHEL version, storage, memory, network
- [ ] **System verification commands** - Check tools, disk space, connectivity  
- [ ] **Required tools listing** - All dependencies clearly stated
- [ ] **Setup verification section** - Commands to validate prerequisites

### **✅ ImageSet Configuration**
- [ ] **Standardized config matching working files** - Use actual working `imageset-config.yaml`
- [ ] **Flow-appropriate version targeting**:
  - Single-version flows: `maxVersion: 4.19.2` 
  - Upgrade workflows: `maxVersion: 4.19.10`
- [ ] **Consistent operators** - Use `web-terminal` only for simplicity
- [ ] **Standard additional images** - Include `ubi9/ubi:latest`
- [ ] **Configuration explanation** - Key options documented

### **✅ System Preparation**
- [ ] **Complete setup section** - From packages through registry verification
- [ ] **Package installation** - `sudo dnf install -y podman git jq vim wget curl`
- [ ] **Hostname configuration** - `hostnamectl set-hostname` commands
- [ ] **Firewall configuration** - Ports 80, 443, 8443 opened
- [ ] **OpenShift tools installation** - Repository clone and `./collect_ocp`
- [ ] **Mirror registry setup** - Installation, SSL trust, authentication
- [ ] **Registry verification** - Web browser access test

### **✅ Step-by-Step Procedure**
- [ ] **Dedicated executable script** - `oc-mirror-[flow-name].sh` 
- [ ] **Multiple execution options** - Script (recommended), manual command, alternatives
- [ ] **Clear script descriptions** - What each script does
- [ ] **Monitoring guidance** - How to track progress
- [ ] **Verification steps** - How to confirm success

### **✅ Reference Links Replace Verbose Sections**
- [ ] **Performance Optimization** → Link to `../reference/oc-mirror-v2-commands.md#performance-tuning`
- [ ] **Cache Management** → Link to `../reference/cache-management.md`
- [ ] **Troubleshooting** → Links to reference docs with quick debugging tips
- [ ] **Essential quick tips** - Include 2-3 most critical commands inline

### **✅ Decision Guidance**
- [ ] **"When to Use This Flow" section** - Clear use cases with ✅/❌ indicators
- [ ] **Comparison with alternatives** - When NOT to use this flow
- [ ] **Environment suitability** - Connected/semi-connected/air-gapped guidance

### **✅ Streamlined Next Steps**
- [ ] **Celebration of completion** - 🎉 acknowledgment
- [ ] **Primary next action** - Clear, prominent next step
- [ ] **Logical progression** - Link to next flow or cluster deployment
- [ ] **Alternative paths** - Secondary options when applicable
- [ ] **Context for next steps** - What user will accomplish next

### **✅ Comprehensive References**
- [ ] **Organized by category**:
  - **oc-mirror Flow Patterns** - Related flows, decision guide
  - **Next Steps** - OpenShift cluster creation, upgrades
  - **Technical References** - Commands, cache, performance docs
  - **Setup & Infrastructure** - AWS setup, complete workflow
- [ ] **All linked documents** - Every reference used in the flow
- [ ] **Consistent link formatting** - Clear descriptions for each link

---

## 🔧 Technical Standardization

### **✅ Script Creation & Management**
- [ ] **Dedicated script exists** - `oc-mirror-[flow-name].sh` in `oc-mirror-master/`
- [ ] **Executable permissions** - `chmod +x` applied
- [ ] **Consistent formatting** - Echo messages, error handling, output
- [ ] **Dynamic hostnames** - Use `$(hostname):8443` for portability
- [ ] **Standardized cache** - `--cache-dir .cache` in all scripts
- [ ] **v2 flag usage** - Include `--v2` flag consistently

### **✅ Configuration Consistency**
- [ ] **Working config alignment** - Match actual `imageset-config.yaml` 
- [ ] **Version strategy** - Single version vs range based on use case
- [ ] **Operator consistency** - Same operators across related flows
- [ ] **Archive size appropriateness** - `archiveSize: 8` for disk flows, commented for registry flows

---

## 🎯 Content Quality Standards

### **✅ Focus & Scope**
- [ ] **Remove automation sections** - Keep flows focused on core procedures
- [ ] **Self-contained setup** - No external dependencies assumed
- [ ] **Essential steps only** - Remove non-critical information
- [ ] **Hackathon appropriateness** - Suitable for learning/testing context

### **✅ Cross-Reference Maintenance**
- [ ] **Internal links current** - All references point to correct locations
- [ ] **Relative paths correct** - `../guides/`, `../reference/` paths accurate
- [ ] **Bidirectional references** - Flows reference each other appropriately

### **✅ User Experience**
- [ ] **Clear progression** - Logical step-by-step flow
- [ ] **Success indicators** - Users know when they're done
- [ ] **Error prevention** - Common pitfalls addressed
- [ ] **Confidence building** - Users feel guided and supported

---

## 📊 Quality Validation

### **Before Marking Complete:**
- [ ] **Read entire flow** - Does it make sense end-to-end?
- [ ] **Check all links** - Do all references work?
- [ ] **Verify scripts exist** - Are all referenced scripts available?
- [ ] **Confirm config consistency** - Does imageset-config match working files?
- [ ] **Test logical flow** - Does next steps progression work?

### **Success Criteria:**
- [ ] **Self-contained** - Can be followed from fresh system to completion
- [ ] **Script-enabled** - Executable scripts available for key operations  
- [ ] **Reference-linked** - Comprehensive guidance accessible via links
- [ ] **Decision-guided** - Clear guidance on when to use this flow
- [ ] **Progression-clear** - Obvious next steps after completion

---

## 🚀 Application Process

### **Step 1: Assessment**
1. Read the current flow documentation
2. Identify which checklist items are missing
3. Note what's already implemented well

### **Step 2: Systematic Application** 
1. Work through checklist items in order
2. Focus on one section at a time
3. Test improvements as you go

### **Step 3: Quality Control**
1. Read the flow end-to-end
2. Verify all links work
3. Check scripts are executable and functional
4. Confirm configuration consistency

### **Step 4: Documentation**
1. Mark checklist items as complete
2. Note any flow-specific variations
3. Document lessons learned for future improvements

---

## 📝 Notes

**Created:** Based on successful transformation of `mirror-to-registry.md` and `mirror-to-disk.md`
**Usage:** Apply systematically to any oc-mirror flow documentation  
**Maintenance:** Update checklist as patterns evolve
**Location:** Store in `docs/reference/` for easy access by documentation maintainers

---

*This checklist ensures consistent, high-quality flow documentation that provides complete guidance for users while maintaining clean, focused content structure.*
