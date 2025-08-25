# oc-mirror --v2 Flow Patterns

**Choose Your oc-mirror Journey**

This directory contains the core **flow patterns** for oc-mirror --v2, designed for hackathon participants to understand and implement different mirroring scenarios.

## 🎯 **Available Flows**

| Flow | Environment | Use Case | Complexity |
|------|-------------|----------|------------|
| **[mirror-to-disk.md](mirror-to-disk.md)** | Connected | Create portable archives | ⭐⭐ |
| **[from-disk-to-registry.md](from-disk-to-registry.md)** | Disconnected | Deploy from archives | ⭐⭐ |
| **[mirror-to-registry.md](mirror-to-registry.md)** | Semi-connected | Direct mirroring | ⭐ |
| **[delete.md](delete.md)** | Any | Safe content cleanup | ⭐⭐⭐ |

## 🤔 **Which Flow Do I Need?**

### **Air-Gapped Environment (No Internet)**
1. **Connected Phase:** Use [mirror-to-disk.md](mirror-to-disk.md)
2. **Transfer Phase:** Move archives to disconnected environment  
3. **Disconnected Phase:** Use [from-disk-to-registry.md](from-disk-to-registry.md)

### **Semi-Connected Environment (Limited Internet)**
- **Direct Mirroring:** Use [mirror-to-registry.md](mirror-to-registry.md)

### **Content Cleanup (Any Environment)**
- **Delete Old Versions:** Use [delete.md](delete.md)

## 🏗️ **Flow Architecture**

```mermaid
flowchart TD
    A[Choose Your Environment] --> B{Connected to Internet?}
    B -->|No| C[Air-Gapped Flow]
    B -->|Limited| D[Semi-Connected Flow]
    B -->|Yes| E[Connected Flow]
    
    C --> F[mirror-to-disk]
    F --> G[Transfer Archives]
    G --> H[from-disk-to-registry]
    
    D --> I[mirror-to-registry]
    E --> J[mirror-to-registry]
    
    H --> K[delete - cleanup]
    I --> K
    J --> K
```

## 🚀 **Getting Started**

### **Prerequisites**
- Complete [../setup/](../setup/) - Environment preparation
- Review [../guides/collect-ocp.md](../guides/collect-ocp.md) - Tool installation

### **Flow Selection Process**
1. **Assess your environment** (connected, semi-connected, air-gapped)
2. **Choose appropriate flow** from table above
3. **Follow step-by-step procedures** in selected flow document
4. **Use provided scripts** from `oc-mirror-master/` directory

## 📚 **Related Documentation**

### **Foundation**
- **[../setup/](../setup/)** - Initial environment setup
- **[../guides/](../guides/)** - Step-by-step operational guides

### **Advanced**
- **[../reference/](../reference/)** - Technical references and troubleshooting
- **[../reference/workflows/](../reference/workflows/)** - Enterprise operational patterns

### **Scripts**
- **[../../oc-mirror-master/](../../oc-mirror-master/)** - Ready-to-use implementation scripts

---

## 🚧 **Hackathon Development Status**

All flows are currently under active development for the oc-mirror hackathon:

- **✅ delete.md** - Complete with tested procedures
- **🚧 mirror-to-disk.md** - Stub created, needs content
- **🚧 from-disk-to-registry.md** - Stub created, needs content  
- **🚧 mirror-to-registry.md** - Stub created, needs content

**Goal:** Build out comprehensive, tested flow documentation that hackathon participants can follow successfully.
