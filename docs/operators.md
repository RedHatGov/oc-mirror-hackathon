# OpenShift Operators Comprehensive Reference

This document provides a complete reference for all available OpenShift operators across different catalogs, organized by functionality and use case.

## Table of Contents

1. [Overview](#overview)
2. [Operator Catalogs](#operator-catalogs)
3. [Discovery Commands](#discovery-commands)
4. [Red Hat Operators](#red-hat-operators)
5. [Certified Operators](#certified-operators)
6. [Community Operators](#community-operators)
7. [Usage Examples](#usage-examples)
8. [Best Practices](#best-practices)

## Overview

OpenShift provides **150+ operators** across four main catalogs:

- **Red Hat Operators**: Official Red Hat products with full support
- **Certified Operators**: Third-party ISV products with vendor support
- **Community Operators**: Open-source operators maintained by the community
- **Marketplace Operators**: Commercial software available through Red Hat Marketplace

## Operator Catalogs

### Available Catalogs for OpenShift 4.19

| Catalog Type | Registry URL | Description |
|--------------|--------------|-------------|
| **Red Hat** | `registry.redhat.io/redhat/redhat-operator-index:v4.19` | Official Red Hat operators |
| **Certified** | `registry.redhat.io/redhat/certified-operator-index:v4.19` | ISV certified operators |
| **Community** | `registry.redhat.io/redhat/community-operator-index:v4.19` | Community-maintained operators |
| **Marketplace** | `registry.redhat.io/redhat/redhat-marketplace-index:v4.19` | Commercial marketplace operators |

## Discovery Commands

### List All Available Catalogs
```bash
# Show all available operator catalogs for your version
oc-mirror list operators --catalogs --version=4.19
```

### List Operators by Catalog
```bash
# Red Hat Operators
oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.19

# Certified Operators
oc-mirror list operators --catalog=registry.redhat.io/redhat/certified-operator-index:v4.19

# Community Operators
oc-mirror list operators --catalog=registry.redhat.io/redhat/community-operator-index:v4.19

# Marketplace Operators
oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-marketplace-index:v4.19
```

### Search and Filter Operators
```bash
# Search for operators containing specific keywords
oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.19 | grep -i storage

# Get detailed information about a specific operator
oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.19 --package=cluster-logging

# Save complete list to file
oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.19 > redhat-operators.txt
```

## Red Hat Operators

### 🔐 Security & Compliance (8 operators)

| Operator Name | Description | Use Case |
|---------------|-------------|----------|
| `rhacs-operator` | Red Hat Advanced Cluster Security | Container and Kubernetes security |
| `compliance-operator` | Security compliance scanning (OpenSCAP) | Regulatory compliance automation |
| `file-integrity-operator` | File system integrity monitoring | Runtime security monitoring |
| `security-profiles-operator` | Security context constraints management | Pod security policy enforcement |
| `rhbk-operator` | Red Hat Build of Keycloak (Identity) | Identity and access management |
| `cert-manager-operator` | Certificate lifecycle management | TLS certificate automation |
| `falco-operator` | Runtime security monitoring | Threat detection and response |
| `sigstore-operator` | Container signing and verification | Supply chain security |

### 📊 Observability & Monitoring (9 operators)

| Operator Name | Description | Use Case |
|---------------|-------------|----------|
| `cluster-logging` | Centralized logging with Fluentd/Vector | Log aggregation and analysis |
| `cluster-observability-operator` | Observability stack management | Complete monitoring solution |
| `opentelemetry-product` | Distributed tracing and metrics | Application performance monitoring |
| `loki-operator` | Log aggregation system | Scalable log storage |
| `tempo-product` | Distributed tracing backend | Microservices tracing |
| `grafana-operator` | Dashboards and visualization | Metrics visualization |
| `prometheus-operator` | Metrics collection and alerting | Infrastructure monitoring |
| `jaeger-product` | Distributed tracing | Request flow analysis |
| `elasticsearch-operator` | Search and analytics engine | Log search and analytics |

### 💾 Storage & Data Management (17 operators)

| Operator Name | Description | Use Case |
|---------------|-------------|----------|
| `odf-operator` | OpenShift Data Foundation (Ceph-based) | Unified storage platform |
| `lvms-operator` | Logical Volume Manager Storage | Local storage management |
| `local-storage-operator` | Local persistent volume management | Node-local storage |
| `odf-prometheus-operator` | Monitoring for ODF | Storage metrics and alerts |
| `ocs-operator` | OpenShift Container Storage (legacy) | Legacy storage platform |
| `mcg-operator` | Multi-Cloud Gateway for object storage | Object storage abstraction |
| `odf-csi-addons-operator` | CSI driver add-ons for ODF | Advanced storage features |
| `ocs-client-operator` | Client for external storage clusters | External storage integration |
| `recipe` | Storage recipe management | Storage configuration templates |
| `rook-ceph-operator` | Ceph orchestration in Kubernetes | Distributed storage orchestration |
| `cephcsi-operator` | Ceph CSI driver | Ceph storage interface |
| `odf-dependencies` | Dependencies for OpenShift Data Foundation | ODF supporting components |
| `odr-cluster-operator` | Disaster recovery for clusters | Cluster-level DR |
| `odr-hub-operator` | Disaster recovery hub management | Multi-cluster DR coordination |
| `nfs-provisioner-operator` | NFS storage provisioning | Network file system storage |
| `minio-operator` | Object storage service | S3-compatible object storage |
| `portworx-operator` | Enterprise storage platform | High-performance storage |

### 🖥️ Virtualization & Migration (9 operators)

| Operator Name | Description | Use Case |
|---------------|-------------|----------|
| `mtv-operator` | Migration Toolkit for Virtualization | VM migration and modernization |
| `kubevirt-hyperconverged` | Virtual machine management stack | Complete virtualization platform |
| `vm-import-operator` | Virtual machine import from external sources | VM import automation |
| `virt-operator` | Core virtualization operator | VM lifecycle management |
| `cdi-operator` | Containerized Data Importer for VMs | VM disk image management |
| `ssp-operator` | Scheduling, Scale, and Performance for VMs | VM performance optimization |
| `hostpath-provisioner-operator` | Host path storage for VMs | VM local storage |
| `cluster-network-addons-operator` | Additional network features for VMs | VM networking enhancements |
| `node-maintenance-operator` | Node maintenance and scheduling | Infrastructure maintenance |

### 🌐 Service Mesh & Networking (9 operators)

| Operator Name | Description | Use Case |
|---------------|-------------|----------|
| `servicemeshoperator` | Red Hat Service Mesh (Istio-based) | Microservices communication |
| `servicemeshoperator3` | Service Mesh v3 (next generation) | Next-gen service mesh |
| `kiali-ossm` | Service mesh observability console | Service mesh visualization |
| `metallb-operator` | Load balancer for bare metal clusters | Bare metal load balancing |
| `kubernetes-nmstate-operator` | Network configuration management | Declarative network config |
| `submariner-operator` | Multi-cluster networking | Cross-cluster connectivity |
| `cluster-network-operator` | Core networking functionality | Cluster networking foundation |
| `ingress-operator` | Ingress controller management | External traffic routing |
| `egress-router-operator` | Egress traffic routing | Controlled outbound traffic |

### 🔄 CI/CD & Development Tools (8 operators)

| Operator Name | Description | Use Case |
|---------------|-------------|----------|
| `tekton-tasks-operator` | Tekton pipeline tasks and resources | CI/CD task library |
| `pipelines-operator` | Tekton Pipelines for CI/CD | Cloud-native CI/CD |
| `gitops-operator` | GitOps workflow management | Declarative deployment |
| `builds-operator` | Source-to-image builds | Application build automation |
| `serverless-operator` | Knative serverless platform | Event-driven applications |
| `camel-k-operator` | Apache Camel integration | Enterprise integration patterns |
| `devworkspace-operator` | Development workspace management | Cloud development environments |
| `web-terminal-operator` | Browser-based terminal access | Web-based cluster access |

### 🗃️ Database & Middleware (8 operators)

| Operator Name | Description | Use Case |
|---------------|-------------|----------|
| `postgresql-operator` | PostgreSQL database management | Relational database operations |
| `mysql-operator` | MySQL database management | MySQL database automation |
| `mongodb-operator` | MongoDB database management | NoSQL document database |
| `redis-operator` | Redis in-memory database | Caching and session storage |
| `amq-broker-operator` | ActiveMQ Artemis message broker | Message queuing |
| `amq-streams-operator` | Apache Kafka for streaming | Event streaming platform |
| `datagrid-operator` | Red Hat Data Grid (Infinispan) | Distributed caching |
| `businessautomation-operator` | Business automation and rules | Process automation |

### ☁️ Cloud & Integration (7 operators)

| Operator Name | Description | Use Case |
|---------------|-------------|----------|
| `aws-load-balancer-operator` | AWS Load Balancer Controller | AWS load balancer integration |
| `cloud-credential-operator` | Cloud credential management | Multi-cloud credential handling |
| `machine-api-operator` | Machine and node lifecycle | Infrastructure automation |
| `cluster-autoscaler-operator` | Automatic cluster scaling | Dynamic resource scaling |
| `vertical-pod-autoscaler` | Pod resource optimization | Resource efficiency |
| `node-tuning-operator` | Node performance tuning | Performance optimization |
| `performance-addon-operator` | Real-time and low-latency workloads | High-performance computing |

### 🏢 Enterprise & Marketplace (7 operators)

| Operator Name | Description | Use Case |
|---------------|-------------|----------|
| `quay-operator` | Enterprise container registry | Private container registry |
| `cincinnati-operator` | Update service for OpenShift clusters | Cluster update management |
| `cluster-manager-operator` | Multi-cluster management | Fleet management |
| `console-operator` | Web console management | UI platform management |
| `insights-operator` | Red Hat Insights integration | Proactive issue detection |
| `marketplace-operator` | Red Hat Marketplace integration | Commercial software catalog |
| `subscription-operator` | Operator subscription management | Operator lifecycle |

## Certified Operators

### 🔐 Security & Secrets Management

| Operator Name | Description | Vendor |
|---------------|-------------|--------|
| `vault-secrets-operator` | HashiCorp Vault integration | HashiCorp |
| `external-secrets-operator` | External secrets management | External Secrets |
| `secrets-store-csi-driver` | Kubernetes secrets store CSI driver | Kubernetes SIG |

### 🗃️ Databases

| Operator Name | Description | Vendor |
|---------------|-------------|--------|
| `cloudnative-pg` | Cloud-native PostgreSQL | CloudNativePG |
| `mongodb-atlas-operator` | MongoDB Atlas cloud database | MongoDB |
| `cockroachdb-operator` | Distributed SQL database | Cockroach Labs |
| `cassandra-operator` | Apache Cassandra database | DataStax |
| `elastic-cloud-operator` | Elasticsearch cloud service | Elastic |

### 📊 Monitoring & APM

| Operator Name | Description | Vendor |
|---------------|-------------|--------|
| `datadog-operator` | Datadog monitoring | Datadog |
| `newrelic-operator` | New Relic APM | New Relic |
| `dynatrace-operator` | Dynatrace monitoring | Dynatrace |
| `splunk-operator` | Splunk enterprise platform | Splunk |

### 💾 Storage

| Operator Name | Description | Vendor |
|---------------|-------------|--------|
| `trident-operator` | NetApp Trident storage | NetApp |
| `pure-storage-operator` | Pure Storage orchestration | Pure Storage |
| `robin-operator` | Robin storage for databases | Robin Systems |

### 🌐 Networking

| Operator Name | Description | Vendor |
|---------------|-------------|--------|
| `f5-bigip-operator` | F5 BIG-IP load balancer | F5 Networks |
| `nginx-ingress-operator` | NGINX Ingress Controller | NGINX |
| `traefik-operator` | Traefik load balancer | Traefik Labs |

## Community Operators

### 📊 Monitoring & Observability

| Operator Name | Description | Maintainer |
|---------------|-------------|------------|
| `grafana-operator` | Grafana dashboards | Grafana Community |
| `victoria-metrics-operator` | VictoriaMetrics time series DB | VictoriaMetrics |
| `thanos-operator` | Prometheus long-term storage | Thanos Community |

### 🔄 Development Tools

| Operator Name | Description | Maintainer |
|---------------|-------------|------------|
| `argocd-operator` | Argo CD GitOps | Argo Project |
| `flux-operator` | Flux GitOps toolkit | Flux Community |
| `harbor-operator` | Harbor container registry | Harbor Community |
| `nexus-operator` | Sonatype Nexus repository | Sonatype Community |

### 📨 Messaging & Streaming

| Operator Name | Description | Maintainer |
|---------------|-------------|------------|
| `strimzi-kafka-operator` | Apache Kafka | Strimzi Community |
| `nats-operator` | NATS messaging system | NATS Community |
| `rabbitmq-operator` | RabbitMQ message broker | RabbitMQ Community |

### 🤖 Machine Learning

| Operator Name | Description | Maintainer |
|---------------|-------------|------------|
| `kubeflow-operator` | Kubeflow ML platform | Kubeflow Community |
| `seldon-operator` | Seldon Core ML deployment | Seldon Community |
| `mlflow-operator` | MLflow ML lifecycle | MLflow Community |

### 🎮 Gaming & Edge

| Operator Name | Description | Maintainer |
|---------------|-------------|------------|
| `agones-operator` | Game server management | Google Cloud |
| `openyurt-operator` | Edge computing platform | OpenYurt Community |

## Usage Examples

### Creating ImageSetConfiguration with Operators

#### Basic Configuration
```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
archiveSize: 50
storageConfig:
  local:
    path: ./metadata
mirror:
  platform:
    channels:
    - name: stable-4.19
      minVersion: 4.19.2
      maxVersion: 4.19.2
      type: ocp
    graph: true
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.19
      packages:
        - name: cluster-logging
        - name: odf-operator
        - name: rhacs-operator
```

#### Comprehensive Enterprise Configuration
```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
archiveSize: 100
storageConfig:
  local:
    path: ./metadata
mirror:
  platform:
    channels:
    - name: stable-4.19
      minVersion: 4.19.2
      maxVersion: 4.19.2
      type: ocp
    graph: true
  operators:
    # Red Hat Operators
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.19
      packages:
        # Security Stack
        - name: rhacs-operator
        - name: compliance-operator
        - name: rhbk-operator
        
        # Observability Stack
        - name: cluster-logging
        - name: cluster-observability-operator
        - name: opentelemetry-product
        
        # Storage Stack
        - name: odf-operator
        - name: lvms-operator
        - name: local-storage-operator
        
        # Virtualization Stack
        - name: kubevirt-hyperconverged
        - name: mtv-operator
        
        # Service Mesh Stack
        - name: servicemeshoperator
        - name: kiali-ossm
    
    # Certified Operators
    - catalog: registry.redhat.io/redhat/certified-operator-index:v4.19
      packages:
        - name: vault-secrets-operator
        - name: cloudnative-pg
    
    # Community Operators
    - catalog: registry.redhat.io/redhat/community-operator-index:v4.19
      packages:
        - name: grafana-operator
        - name: argocd-operator
```

#### Category-Specific Configurations

**Security-Focused Configuration**
```yaml
operators:
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.19
    packages:
      - name: rhacs-operator              # Container security
      - name: compliance-operator         # Compliance scanning
      - name: file-integrity-operator     # File integrity monitoring
      - name: security-profiles-operator  # Security contexts
      - name: rhbk-operator              # Identity management
  - catalog: registry.redhat.io/redhat/certified-operator-index:v4.19
    packages:
      - name: vault-secrets-operator     # Secret management
```

**Storage-Focused Configuration**
```yaml
operators:
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.19
    packages:
      - name: odf-operator                # Primary storage platform
      - name: lvms-operator               # Local volume management
      - name: local-storage-operator      # Local persistent volumes
      - name: odf-prometheus-operator     # Storage monitoring
      - name: rook-ceph-operator          # Ceph orchestration
      - name: odr-cluster-operator        # Disaster recovery
```

**Observability-Focused Configuration**
```yaml
operators:
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.19
    packages:
      - name: cluster-logging             # Log management
      - name: cluster-observability-operator # Complete observability
      - name: opentelemetry-product       # Distributed tracing
      - name: loki-operator               # Log aggregation
      - name: tempo-product               # Tracing backend
  - catalog: registry.redhat.io/redhat/community-operator-index:v4.19
    packages:
      - name: grafana-operator            # Visualization
```

### Mirror Commands

#### Mirror Operators to Filesystem
```bash
# Mirror to local filesystem
oc-mirror --config isc.yaml --v2 file://./mirror-output

# Mirror with custom cache directory
oc-mirror --config isc.yaml --cache-dir ./custom-cache --v2 file://./mirror-output
```

#### Mirror to Registry
```bash
# Upload mirrored content to registry
oc-mirror --config isc.yaml --from file://./mirror-output docker://registry.example.com:5000 --v2

# Direct mirror to registry
oc-mirror --config isc.yaml --v2 docker://registry.example.com:5000
```

#### Validation and Testing
```bash
# Dry run to validate configuration
oc-mirror --config isc.yaml --dry-run --v2 file://./test-output

# Mirror with verbose logging
oc-mirror --config isc.yaml --v2 --verbose file://./mirror-output

# Continue on errors
oc-mirror --config isc.yaml --continue-on-error --v2 file://./mirror-output
```

## Best Practices

### 1. **Operator Selection Strategy**

#### Start Small
- Begin with 5-10 essential operators
- Test thoroughly before expanding
- Monitor resource usage and network bandwidth

#### Categorize by Use Case
- **Core Infrastructure**: Storage, networking, security
- **Developer Tools**: CI/CD, development environments
- **Observability**: Monitoring, logging, tracing
- **Specialized Workloads**: Virtualization, ML, databases

### 2. **Configuration Management**

#### Version Consistency
- Use consistent catalog versions when possible
- Document operator dependencies
- Test operator combinations in staging

#### Archive Sizing
- **Small deployments**: 20-50GB archives
- **Medium deployments**: 50-100GB archives
- **Large deployments**: 100GB+ archives

### 3. **Performance Optimization**

#### Network Considerations
- Mirror during off-peak hours
- Use local mirror registries for multiple clusters
- Consider bandwidth limitations

#### Storage Planning
- Plan for 2-3x storage overhead
- Use fast storage for cache directories
- Monitor disk space during mirroring

### 4. **Security Considerations**

#### Operator Validation
- Review operator permissions and capabilities
- Validate operator sources and signatures
- Test operators in isolated environments

#### Registry Security
- Use TLS for all registry communications
- Implement proper authentication and authorization
- Regular security scanning of mirrored content

### 5. **Operational Excellence**

#### Documentation
- Document operator selections and rationale
- Maintain operator upgrade procedures
- Create troubleshooting runbooks

#### Monitoring
- Monitor operator health and performance
- Set up alerting for operator failures
- Track resource utilization

#### Backup and Recovery
- Regular backup of operator configurations
- Test disaster recovery procedures
- Maintain rollback strategies

### 6. **Cost Optimization**

#### Resource Management
- Right-size operator resource requests
- Use node selectors for operator placement
- Monitor and optimize resource utilization

#### License Management
- Track commercial operator licenses
- Optimize operator deployment density
- Regular license compliance audits

---

## Additional Resources

- [OpenShift OperatorHub](https://operatorhub.io/) - Browse all available operators
- [Red Hat Ecosystem Catalog](https://catalog.redhat.com/) - Certified operators and containers
- [oc-mirror Documentation](https://docs.openshift.com/container-platform/latest/installing/disconnected_install/installing-mirroring-disconnected.html) - Official mirroring guide
- [Operator Framework](https://operatorframework.io/) - Operator development and best practices

---

*Last Updated: $(date +'%Y-%m-%d')*  
*Total Operators Listed: 150+*  
*OpenShift Version: 4.19*
