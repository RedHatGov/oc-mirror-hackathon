# Lab Infrastructure Setup Guide (AWS)

This guide provides AWS-specific infrastructure setup instructions for the oc-mirror hackathon lab environment. These steps prepare your cloud infrastructure before following the universal [oc-mirror-workflow.md](oc-mirror-workflow.md) guide.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [AWS Environment Setup](#aws-environment-setup)
4. [Bastion Host Configuration](#bastion-host-configuration)
5. [Next Steps](#next-steps)

## Overview

This guide covers the AWS-specific infrastructure setup needed for the oc-mirror workshop:

- **AWS Demo Environment**: Red Hat Demo Platform AWS environment
- **Bastion Host**: RHEL 10 instance with networking configuration
- **DNS Configuration**: Route53 DNS records for the bastion host
- **Security Groups**: Firewall rules for mirror registry access

### What You'll Build
- 🌐 **AWS Demo Environment**: Sandbox environment with credentials
- 🖥️ **Bastion Host**: RHEL 10 EC2 instance (t2.large, 1TB storage)
- 🔗 **DNS Record**: Route53 A record for bastion host access
- 🛡️ **Security Group**: Firewall rules for mirror registry (port 8443)

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
| **OS** | Red Hat Enterprise Linux 10 | Latest RHEL version |
| **Instance Type** | `t2.large` | Minimum for mirroring operations |
| **Key Pair** | Create new or select existing | Download and save securely |
| **Network** | Default VPC and subnet | Use previously created Default VPC |
| **Storage** | 1x 1024 GiB (gp3) | Required for mirroring operations |

3. Click **"Launch instance"**

### 2. Security Group Configuration

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

### 3. DNS Configuration

Set up DNS record for your bastion host:

1. **Copy the public IP address** from your EC2 instance details
2. **Navigate to the Route53 console**
3. **Click Hosted zones from the sidebar menu**
4. **Select your hosted zone** (e.g. `sandboxXXX.opentlc.com`)
5. **Click "Create record" and using the following settings**:
   - **Record Name:** `bastion`
   - **Record Type:** A
   - **Value:** [Your bastion EC2 instance's public IP]
6. **Click "Create records"**

### 4. Connect to Bastion Host

#### SSH Connection
```bash
# Replace with your actual key file and IP address
ssh -i ~/.ssh/your-key.pem ec2-user@[BASTION-PUBLIC-IP]

# Alternative: Use the public DNS name
ssh -i ~/.ssh/your-key.pem ec2-user@bastion.sandboxXXX.opentlc.com
```

### 5. Initial System Setup

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

## Next Steps

Once your AWS infrastructure is configured and you're connected to your bastion host, continue with the universal oc-mirror setup guide:

**➡️ Continue to: [oc-mirror-workflow.md](oc-mirror-workflow.md)**

The oc-mirror setup guide covers:
- OpenShift tools installation
- Mirror registry deployment
- Content mirroring with oc-mirror
- User transfer workflows
- Post-installation configuration

---

## AWS-Specific Notes

### Cost Management
- The t2.large instance and 1TB storage will incur costs if left running
- Use the demo environment's auto-stop/auto-destroy features
- Monitor usage through the AWS billing dashboard

### Security Considerations
- Security group rule (0.0.0.0/0) is for lab use only
- In production, restrict source IPs to specific networks
- Consider using AWS Systems Manager Session Manager for SSH access

### Troubleshooting
- If EC2 launch fails, check service limits in the AWS console
- Route53 DNS propagation may take 5-10 minutes
- Ensure your SSH key has proper permissions (chmod 600)

---

*Last Updated: December 2024*  
*AWS Demo Environment: Red Hat Demo Platform*  
*Target Platform: AWS EC2 with Route53*
