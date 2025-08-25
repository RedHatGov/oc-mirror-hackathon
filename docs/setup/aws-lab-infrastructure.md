# Lab Infrastructure Setup Guide (AWS)

This guide provides AWS-specific infrastructure setup instructions for the oc-mirror hackathon lab environment. These steps prepare your cloud infrastructure before following the universal [oc-mirror-workflow.md](oc-mirror-workflow.md) guide.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [AWS Environment Setup](#aws-environment-setup)
4. [Bastion Host Configuration](#bastion-host-configuration)
5. [Registry Host Configuration](#registry-host-configuration)
6. [DNS Configuration](#dns-configuration)
7. [Next Steps](#next-steps)

## Overview

This guide covers the AWS-specific infrastructure setup needed for the oc-mirror workshop, including the **two-host architecture** required for air-gapped mirroring workflows:

- **AWS Demo Environment**: Red Hat Demo Platform AWS environment
- **Bastion Host**: RHEL 9 instance for connected mirroring operations
- **Registry Host**: RHEL 9 instance for disconnected registry operations
- **DNS Configuration**: Route53 DNS records for both hosts
- **Security Groups**: Firewall rules for mirror registry access

### What You'll Build
- 🌐 **AWS Demo Environment**: Sandbox environment with credentials
- 🖥️ **Bastion Host**: RHEL 9 EC2 instance for mirror-to-disk operations (t2.large, 1TB storage)
- 🖥️ **Registry Host**: RHEL 9 EC2 instance for from-disk-to-registry operations (t2.large, 1TB storage)
- 🔗 **DNS Records**: Route53 A records for both bastion and registry host access
- 🛡️ **Security Groups**: Firewall rules for mirror registry access (port 8443)

## Prerequisites

### Required Access
- Access to Red Hat Demo Platform
- SSH client for connecting to EC2 instances
- Basic understanding of AWS EC2 and networking concepts

### Technical Requirements
- Valid Red Hat account for demo platform access
- Web browser for AWS console access
- SSH key pair management capability

## AWS Environment Setup

### 1. Create AWS Demo Environment

Navigate to the Red Hat Demo Platform and provision your AWS environment:

**🔗 Demo Platform URL:**
```
https://catalog.demo.redhat.com/catalog?item=babylon-catalog-prod/sandboxes-gpte.sandbox-open.prod&utm_source=webapp&utm_medium=share-link
```

**Configuration Settings:**
- **Purpose:** Practice / Enablement
- **Training Type:** Conduct internal training  
- **Duration:** Auto-stop, Auto-destroy (1 week)

> ⚠️ **Important:** Keep the demo environment page open for AWS credential access throughout the setup process

### 2. AWS Console Access

1. **Copy the AWS Web Console URL** from the demo environment page
2. **Open this URL in a new browser window**
3. **Log into AWS using the Web Console Credentials** from the demo environment page
4. **Navigate to required AWS services** using Search at the top, with each service in a new tab:
   - **EC2:** Instance management and configuration
   - **Route53:** DNS configuration for the bastion host

### 3. Network Infrastructure Setup

#### Create Default VPC (if needed)
1. Navigate to: [VPC Console - Create Default VPC](https://us-east-2.console.aws.amazon.com/vpc/home?region=us-east-2#CreateDefaultVpc:)
2. Click **"Create Default VPC"**
3. Wait for creation to complete

## Bastion Host Configuration

### 1. Launch EC2 Instance

#### Instance Configuration
1. In the EC2 Console, click **"Launch instance"**
2. Use the wizard to configure the following settings:

| Setting | Value | Notes |
|---------|-------|-------|
| **Name** | `bastion` | Descriptive name for identification |
| **OS** | Red Hat Enterprise Linux 9 | Latest stable RHEL version |
| **Instance Type** | `t2.large` | Minimum for mirroring operations |
| **Key Pair** | Create new or select existing | Download and save securely |
| **Network** | Default VPC and subnet | Use previously created Default VPC |
| **Storage** | 1x 1024 GiB (gp3) | Required for mirroring operations |

3. Click **"Launch instance"**

### 2. Security Group Configuration, only needed to access your registry externally

Configure inbound rule to allow access to mirror registry:

1. **Select your bastion instance** from the EC2 console
2. Navigate to the **"Security"** tab
3. **Click on the currently applied Security Group** link (usually `launch-wizard-1`)
4. Click **"Edit inbound rules"**
5. Click **"Add rule"** and use the following settings:
   - **Type:** Custom TCP
   - **Port Range:** 8443
   - **Source:** 0.0.0.0/0 (for lab/testing only - restrict in production)
6. Click **"Save Rules"**

### 3. Connect to Bastion Host

#### SSH Connection
```bash
# Replace with your actual key file and IP address
ssh -i ~/.ssh/your-key.pem ec2-user@[BASTION-PUBLIC-IP]

# Alternative: Use the public DNS name (after DNS configuration)
ssh -i ~/.ssh/your-key.pem ec2-user@bastion.sandboxXXX.opentlc.com
```

### 4. Initial System Setup (Bastion)

Once connected to your bastion host, perform initial configuration:

```bash
# Set the hostname (replace XXX with your sandbox number)
sudo hostnamectl hostname bastion.sandboxXXX.opentlc.com

# Install required packages
sudo dnf install -y podman git jq vim wget

# Verify installation
podman --version
git --version
```

## Registry Host Configuration

### 1. Launch Registry EC2 Instance

Create a second EC2 instance identical to the bastion host for registry operations:

#### Instance Configuration
1. In the EC2 Console, click **"Launch instance"**
2. Use the wizard to configure the following settings:

| Setting | Value | Notes |
|---------|-------|-------|
| **Name** | `registry` | Descriptive name for registry operations |
| **OS** | Red Hat Enterprise Linux 10 | Same as bastion host |
| **Instance Type** | `t2.large` | Same specifications as bastion |
| **Key Pair** | Use same key pair as bastion | For consistent access |
| **Network** | Default VPC and subnet | Same network as bastion host |
| **Storage** | 1x 1024 GiB (gp3) | Same storage as bastion for registry data |

3. Click **"Launch instance"**



### 3. Connect to Registry Host

#### SSH Connection
```bash
# Replace with your actual key file and IP address
ssh -i ~/.ssh/your-key.pem ec2-user@[REGISTRY-PUBLIC-IP]

# Alternative: Use the public DNS name (after DNS configuration)
ssh -i ~/.ssh/your-key.pem ec2-user@registry.sandboxXXX.opentlc.com
```

### 4. Initial System Setup (Registry)

Once connected to your registry host, perform initial configuration:

```bash
# Set the hostname (replace XXX with your sandbox number)
sudo hostnamectl hostname registry.sandboxXXX.opentlc.com

# Install required packages
sudo dnf install -y podman git jq vim wget

# Verify installation
podman --version
git --version
```

## DNS Configuration

Set up DNS records for both bastion and registry hosts:

### 1. Create Bastion DNS Record

1. **Copy the public IP address** from your bastion EC2 instance details
2. **Navigate to the Route53 console**
3. **Click Hosted zones from the sidebar menu**
4. **Select your hosted zone** (e.g. `sandboxXXX.opentlc.com`)
5. **Click "Create record" and use the following settings**:
   - **Record Name:** `bastion`
   - **Record Type:** A
   - **Value:** [Your bastion EC2 instance's public IP]
6. **Click "Create records"**

### 2. Create Registry DNS Record

1. **Copy the public IP address** from your registry EC2 instance details
2. **In the same hosted zone**, click **"Create record"** again
3. **Use the following settings**:
   - **Record Name:** `registry`
   - **Record Type:** A
   - **Value:** [Your registry EC2 instance's public IP]
4. **Click "Create records"**

### 3. Verify DNS Configuration

```bash
# Test DNS resolution for both hosts
nslookup bastion.sandboxXXX.opentlc.com
nslookup registry.sandboxXXX.opentlc.com

# Alternative: Use dig command
dig +short bastion.sandboxXXX.opentlc.com
dig +short registry.sandboxXXX.opentlc.com
```

## Next Steps

🎉 **Infrastructure Setup Complete!** 

Your AWS environment is now ready with:
- ✅ **Bastion Host** (`bastion.sandboxXXX.opentlc.com`) - Ready for connected operations
- ✅ **Registry Host** (`registry.sandboxXXX.opentlc.com`) - Ready for disconnected operations  
- ✅ **DNS Configuration** - Both hosts accessible via Route53
- ✅ **Security Groups** - Registry access configured on port 8443

### **🔄 Return to Your Hackathon Journey**

**➡️ [Continue with the Hackathon Quick Start Guide](../hackathon-quickstart.md#-step-2-understand-oc-mirror-flows)**

Your infrastructure now supports all hackathon paths:
- **🚫 Two-Host Air-Gapped Path** - Use both hosts for complete air-gapped simulation
- **🔗 Semi-Connected Path** - Use either host for direct registry mirroring  
- **🌐 Single-Host Testing** - Use bastion host for quick testing

The hackathon guide will help you select and execute the right flow for your learning goals.

---

## AWS-Specific Notes

### Cost Management
- **Two t2.large instances** and **2TB total storage** (2x1TB) will incur higher costs
- Use the demo environment's auto-stop/auto-destroy features for both instances
- Monitor usage through the AWS billing dashboard
- Consider stopping instances when not in use for extended periods

### Security Considerations
- Security group rule (0.0.0.0/0) is for lab use only
- In production, restrict source IPs to specific networks
- **Registry host** should have additional security hardening in production environments
- Consider using AWS Systems Manager Session Manager for SSH access to both hosts

### Network Architecture
- Both hosts share the same VPC and security group for simplicity
- In production, consider separate subnets or security groups for role isolation
- DNS names (`bastion.sandboxXXX.opentlc.com` and `registry.sandboxXXX.opentlc.com`) provide clear host identification

### Troubleshooting
- If EC2 launch fails, check service limits in the AWS console (now using 2 instances)
- Route53 DNS propagation may take 5-10 minutes for both records
- Ensure your SSH key has proper permissions (chmod 600) and works with both hosts
- Test connectivity between bastion and registry hosts if using internal networking

---

*Last Updated: December 2024*  
*AWS Demo Environment: Red Hat Demo Platform*  
*Target Platform: AWS EC2 with Route53*
