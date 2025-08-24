# Contributors Guide - Hackathon Documentation Framework

## 🎯 **Contributing to the oc-mirror Hackathon Repo**

This guide helps hackathon participants understand and contribute to the modular documentation framework.

## 📋 **Quick Contribution Checklist**

### **Before Contributing:**
- [ ] Read [00-overview.md](00-overview.md) - Understand the structure
- [ ] Review [04-conventions.md](04-conventions.md) - Use canonical variables  
- [ ] Test your changes in a real environment
- [ ] Follow the established patterns and formatting

### **Documentation Standards:**
- [ ] Use consistent emoji patterns (🎯 for goals, ✅ for success, ❌ for failure)
- [ ] Reference canonical variables from [04-conventions.md](04-conventions.md)
- [ ] Include copy-paste ready code blocks
- [ ] Add validation steps and success criteria
- [ ] Link to prerequisites rather than embedding them

## 🏗️ **Documentation Architecture Rules**

### **1. Step Isolation Principle**
**Rule**: Each flow document must be self-contained once prerequisites are met.

**✅ Good Example:**
```markdown
## Prerequisites
Complete [02-shared-prereqs.md](02-shared-prereqs.md) before starting.

## Step 1: Configuration
Export standard variables from [04-conventions.md](04-conventions.md):
```

**❌ Bad Example:**
```markdown  
## Prerequisites  
Install OpenShift CLI:
curl -L https://mirror.openshift.com/... # (duplicated setup content)
```

### **2. Single Source of Truth**
**Rule**: Common content lives in one place and is referenced, not duplicated.

**✅ Good Example:**
```markdown
Use canonical variables (see [04-conventions.md](04-conventions.md)):
```bash
oc mirror -c "$ISC" "$REGISTRY_DOCKER" --v2
```

**❌ Bad Example:**
```markdown
```bash
# Don't hardcode values that should be variables
oc mirror -c imageset-config.yaml docker://localhost:8443 --v2
```

### **3. Operational Readiness**
**Rule**: Every flow must include Ready/Go/Done checkpoints.

**Required Sections:**
- **Prerequisites**: Link to shared setup
- **Validation**: Success/failure criteria  
- **Artifacts**: What gets created where
- **Next Steps**: Links to related workflows

## 📂 **Where to Add What Content**

### **Foundation Documents (Don't Duplicate):**
```
00-overview.md          # Decision guide and navigation
01-concepts.md          # Core oc-mirror concepts  
02-shared-prereqs.md    # One-time environment setup
03-env-profiles.md      # Environment types and patterns
04-conventions.md       # Variables and standards
```
**Rule**: Don't modify these unless adding new core concepts.

### **Flow Documents (Operation-Focused):**
```
flows/10-mirror-to-disk.md              # Mirror to portable archives
flows/11-from-disk-to-registry.md       # Deploy archives to registry
flows/12-mirror-to-registry.md          # Direct mirror-to-registry  
flows/13-delete.md                      # Safe image deletion
flows/20-cluster-upgrade.md             # OpenShift upgrades
```
**Rule**: Pure operational steps. Link to prerequisites, don't embed.

### **Checklists (Validation-Focused):**
```
checklists/prereqs-ready.md             # Environment validation
checklists/run-go.md                    # Pre-execution checklist
checklists/post-done.md                 # Success validation
```
**Rule**: Copy-paste friendly validation commands.

### **References (Deep-Dive Content):**
```
references/troubleshooting.md           # Error → Cause → Fix
references/cache-management.md          # Storage optimization
references/oc-mirror-commands.md        # Complete command reference
```
**Rule**: Comprehensive technical details and troubleshooting.

## ✏️ **Content Creation Patterns**

### **Flow Document Template:**
```markdown
# [Flow Name] - [Brief Description]

## 🎯 **When to Use This Flow**
- ✅ Scenario 1 (be specific)
- ✅ Scenario 2 (be specific)  
- ❌ NOT for Scenario 3 (redirect to appropriate flow)

## 📋 **Prerequisites**  
Complete [02-shared-prereqs.md](02-shared-prereqs.md) and export variables from [04-conventions.md](04-conventions.md).

## 🔍 **Inputs & Artifacts**
**Required Inputs:**
- Configuration file: `$ISC`
- [Other specific inputs]

**Generated Artifacts:**  
- [Specific files/directories created]
- [Where they're located using canonical variables]

## ⚡ **Procedure**
### Step 1: [Action]
```bash
# Copy-paste ready commands using canonical variables
[commands]
```

**Expected Output:**
```
[Exact output example]
```

### Step 2: [Action]  
[Continue pattern...]

## ✅ **Validation**
```bash
# Validation commands that prove success
[validation commands]
```

**Success Criteria:**
- ✅ [Specific success indicator]
- ✅ [Another success indicator]

## 🧹 **Cleanup**
[What can be safely deleted after success]

## 🚀 **Next Steps**
- **Related Flow**: [Link to logical next step]
- **Troubleshooting**: [references/troubleshooting.md](../references/troubleshooting.md)
```

### **Code Block Standards:**
```bash
# ✅ Good: Uses canonical variables, copy-paste ready
export REGISTRY_FQDN="$(hostname):8443"
oc mirror -c "$ISC" "$REGISTRY_DOCKER" --v2 --cache-dir "$CACHE"

# ❌ Bad: Hardcoded values, not portable  
oc mirror -c imageset-config.yaml docker://localhost:8443 --v2 --cache-dir /tmp/cache
```

### **Validation Pattern:**
```bash
# Standard validation function
validate_operation() {
    echo "=== Validating [Operation] ==="
    
    # Test 1: [Specific test]
    [test command] && echo "✅ Test 1 passed" || echo "❌ Test 1 failed"
    
    # Test 2: [Specific test]  
    [test command] && echo "✅ Test 2 passed" || echo "❌ Test 2 failed"
    
    echo "=== Validation Complete ==="
}
```

## 🧪 **Testing Requirements**

### **Before Submitting Changes:**
1. **Environment Test**: Validate in real RHEL 9 environment
2. **Copy-Paste Test**: All code blocks must work when copy-pasted
3. **Link Validation**: All internal links must work on GitHub
4. **Variable Check**: Use canonical variables, no hardcoded values

### **Testing Checklist:**
```bash
# Run these tests before submitting
echo "=== Testing Checklist ==="

# 1. Code blocks work
echo "Testing code blocks..."
# Copy-paste each bash block and verify it works

# 2. Links resolve  
echo "Testing links..."
# Click each link to verify it works on GitHub

# 3. Variables used correctly
echo "Testing variables..."
grep -r "localhost:8443" . && echo "❌ Found hardcoded registry" || echo "✅ Uses canonical variables"

# 4. Prerequisites check
echo "Testing prerequisites..."
# Follow the prerequisites and verify they work
```

## 🔄 **Common Contribution Patterns**

### **Adding a New Flow:**
1. **Create flow file**: `flows/##-flow-name.md`
2. **Follow template**: Use the flow document template above
3. **Update overview**: Add to decision matrix in [00-overview.md](00-overview.md)
4. **Test completely**: End-to-end testing in real environment
5. **Create PR**: With clear description of the new workflow

### **Enhancing Existing Flow:**
1. **Identify improvement**: Clear description of enhancement
2. **Maintain structure**: Don't break existing patterns
3. **Update related docs**: If changing prerequisites or outputs
4. **Test thoroughly**: Both new and existing functionality
5. **Document changes**: Clear commit messages and PR description

### **Adding Troubleshooting Content:**
1. **Format**: `Error Message → Root Cause → Solution`
2. **Location**: Add to [references/troubleshooting.md](references/troubleshooting.md)
3. **Examples**: Include exact commands that demonstrate fix
4. **Cross-reference**: Link from relevant flow documents

### **Adding Configuration Samples:**
1. **Location**: `config-samples/` directory
2. **Naming**: Descriptive, following convention patterns
3. **Comments**: Explain all non-obvious settings
4. **Testing**: Verify configuration works in real environment

## 🚀 **Quick Start for Contributors**

### **1. Set Up Development Environment:**
```bash
# Fork and clone the repo
git clone https://github.com/YOUR-USERNAME/oc-mirror-hackathon.git
cd oc-mirror-hackathon

# Create feature branch
git checkout -b feature/your-improvement

# Set up test environment following 02-shared-prereqs.md
```

### **2. Make Changes Following Patterns:**
```bash
# Follow the documentation patterns
# Use canonical variables
# Test in real environment
# Update related documents
```

### **3. Submit Contribution:**
```bash
# Commit with clear messages
git add .
git commit -m "Add [specific improvement]: [brief description]"

# Push and create PR
git push origin feature/your-improvement
# Create PR on GitHub with description
```

## 💡 **Best Practices for Hackathon**

### **Documentation Style:**
- ✅ **Action-Oriented**: "Run this command" not "You can run this command"  
- ✅ **Copy-Paste Friendly**: Code blocks work without modification
- ✅ **Success-Focused**: Clear indicators of success/failure
- ✅ **Enterprise-Ready**: Patterns suitable for production use

### **Code Examples:**
- ✅ **Use Variables**: Canonical variables from conventions
- ✅ **Include Output**: Show expected command output
- ✅ **Error Handling**: Include validation and error checks
- ✅ **Comments**: Explain non-obvious steps

### **Testing Approach:**
- ✅ **Real Environment**: Test on actual RHEL 9 systems
- ✅ **Complete Workflows**: End-to-end testing
- ✅ **Error Scenarios**: Test failure cases and recovery
- ✅ **Multiple Profiles**: Test different environment types

## 🎯 **Hackathon Success Metrics**

### **Quality Indicators:**
- **Copy-Paste Success Rate**: Code blocks work without modification
- **Complete Workflow Coverage**: All major oc-mirror patterns documented  
- **Real-World Validation**: Tested in enterprise-like environments
- **Maintainable Structure**: Easy to update and extend

### **Contribution Goals:**
- **Flow Completeness**: All oc-mirror workflows covered
- **Operational Readiness**: Production-ready procedures
- **Educational Value**: Clear learning progression
- **Community Adoption**: Patterns others can follow

---

**🎉 Ready to Contribute?** Start by following a complete workflow yourself, then identify areas for improvement. The best contributions come from real-world usage and testing!

**Questions?** Open an issue or ask in the hackathon chat - we're here to help make this the best oc-mirror resource available!
