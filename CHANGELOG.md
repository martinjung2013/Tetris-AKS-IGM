# Changelog

All notable changes to this AKS infrastructure project will be documented in this file.

## [2024-12-20] - External Access & Documentation Update (v2.0)

### Added

#### External Internet Access
- **Public LoadBalancer Service**
  - Static Public IP: 4.217.223.153
  - Resource Group: mc_rg-liked-yak_cluster-right-marmoset_koreacentral
  - SKU: Standard
  - Ports: 80 (HTTP), 443 (HTTPS)
  - Status: ✅ Active and accessible from internet

#### Network Security Configuration
- **NSG Rules for External Access**
  - AKS Subnet NSG: allow-http (Port 80, Priority 110)
  - AKS Subnet NSG: allow-https (Port 443, Priority 100)
  - AKS Subnet NSG: allow-n8n-nodeport (Port 30678, Priority 120)
  - Node Pool NSG: allow-n8n-nodeport (Port 30678, Priority 1000)

#### Alternative Access Methods
- **NodePort Service** (n8n-nodeport)
  - NodePort: 30678 (HTTP), 30679 (HTTPS)
  - Alternative access for development/testing
- **Internal LoadBalancer Service** (service-internal-lb.yaml)
  - VNet-only private access
  - Private Link Service support
- **Port Forwarding Scripts**
  - Windows PowerShell: scripts/start-n8n.ps1
  - Linux/macOS Bash: scripts/start-n8n.sh
  - Automated health checks and browser launch

#### Firewall Configuration Scripts
- **Windows**: scripts/configure-firewall.ps1
  - Automatic firewall rule creation for ports 5678, 3000, 9000
  - Proxy settings verification
  - kubectl installation check
- **Linux/macOS**: scripts/configure-firewall.sh
  - Support for ufw, iptables, firewalld
  - Automatic port configuration

### Changed

#### Documentation Major Update to Version 2.0
- **PROJECT-README.md**
  - Updated version to 2.0
  - Status: "프로덕션 준비 완료"
  - Added Public IP as primary access method
  - Updated access methods comparison table
  - Marked external access tasks as completed

- **QUICK-START.md**
  - Restructured with internet access as easiest method first
  - Added Public IP: http://4.217.223.153
  - Port forwarding moved to secondary option
  - Updated version to 2.0

- **N8N-CONNECTION-INFO.md**
  - Prioritized Public LoadBalancer as recommended method
  - Added comprehensive service information (3 service types)
  - Updated with External IP: 4.217.223.153
  - Version 2.0 with latest status

- **EXTERNAL-ACCESS.md**
  - Complete external access setup documentation
  - Security recommendations and NSG configuration details
  - DNS setup instructions
  - Troubleshooting guide

#### Service Configuration Updates
- **service-lb.yaml**
  - Updated LoadBalancer annotations for Public IP binding
  - Added resource group specification
  - Set static IP: 4.217.223.153

### Fixed
- LoadBalancer PENDING state issue resolved by manual Public IP creation
- Port 8080 conflict with ArgoCD (changed to 5678, 3000, 9000)
- NSG authorization issues for external access
- PowerShell script syntax errors for firewall configuration

### Access Methods Summary

| Method | URL | Access Scope | Status | Use Case |
|--------|-----|--------------|--------|----------|
| Public LoadBalancer | http://4.217.223.153 | Internet | ✅ Active | Production (Recommended) |
| Port Forward | http://localhost:5678 | Local only | ✅ Available | Development/Testing |
| NodePort | http://NODE-IP:30678 | VNet/Internet | ✅ Available | Alternative Access |
| Internal LB | http://10.224.x.x | VNet only | Not deployed | Internal services |
| Private Endpoint | http://n8n.n8n.internal | VNet only | Not deployed | Enterprise |

### Security Considerations
- ⚠️ Public IP is fully exposed to internet
- Recommended next steps:
  1. IP whitelist configuration
  2. TLS/HTTPS certificate setup
  3. Domain name mapping
  4. WAF (Web Application Firewall) setup
  5. Rate limiting configuration

### New Documentation Files
```
EXTERNAL-ACCESS.md          - External internet access guide
FIREWALL-SETUP.md           - Firewall and proxy configuration
scripts/configure-firewall.ps1 - Windows firewall automation
scripts/configure-firewall.sh  - Linux/macOS firewall automation
scripts/start-n8n.ps1       - Windows N8N quick start
scripts/start-n8n.sh        - Linux/macOS N8N quick start
k8s/n8n/service-nodeport.yaml  - NodePort service configuration
k8s/n8n/service-internal-lb.yaml - Internal LoadBalancer
```

### Login Credentials
- Username: admin
- Password: N8nAdmin2025!
- Authentication: Basic Auth (enabled)

---

## [2024-12-20] - Monitoring Stack Implementation

### Added

#### Monitoring Infrastructure
- **Prometheus** monitoring system
  - ConfigMap with comprehensive scrape configurations
  - RBAC (ServiceAccount, ClusterRole, ClusterRoleBinding)
  - Deployment with 30-day retention and 100Gi storage
  - PersistentVolumeClaim (100Gi, managed-csi-premium)
  - ClusterIP Service
  - Ingress configuration with TLS support

- **Grafana** visualization platform
  - Secret management for credentials and Azure integration
  - ConfigMap with Prometheus and Azure Monitor data sources
  - Pre-configured dashboards for N8N and Kubernetes monitoring
  - Deployment with plugin support
  - PersistentVolumeClaim (10Gi, managed-csi-premium)
  - ClusterIP Service
  - Ingress configuration with TLS support

#### BI Integration
- ConfigMap for Power BI, Tableau, and Looker integration
- Public dashboard configurations
- Data export automation scripts
- Prometheus query templates for BI tools

#### N8N Monitoring Enhancements
- Updated ConfigMap with metrics settings:
  - `N8N_METRICS: "true"`
  - `N8N_METRICS_PREFIX: "n8n_"`
  - `N8N_DIAGNOSTICS_ENABLED: "true"`
- Service annotations for Prometheus scraping
- ServiceMonitor resource for automated metric collection

#### ArgoCD Configuration
- New monitoring-application.yaml for GitOps deployment
- Automated sync policies
- Health check configurations

#### Documentation
- Comprehensive README.md for monitoring stack
- Detailed DEPLOYMENT.md with step-by-step instructions
- Updated CI-CD-SETUP-GUIDE.md with monitoring section
- Troubleshooting guides

### Changed
- N8N ConfigMap: Added metrics-related environment variables
- N8N Service: Added Prometheus scrape annotations
- Prometheus ConfigMap: Enhanced n8n job configuration with annotation-based service discovery
- Kustomization: Added n8n-servicemonitor.yaml resource
- CI-CD-SETUP-GUIDE.md: Updated with monitoring stack completion status

### Files Added
```
k8s/monitoring/
├── namespace.yaml
├── prometheus-configmap.yaml
├── prometheus-rbac.yaml
├── prometheus-pvc.yaml
├── prometheus-deployment.yaml
├── prometheus-service.yaml
├── prometheus-ingress.yaml
├── prometheus-operator-crd.yaml
├── grafana-secret.yaml
├── grafana-configmap.yaml
├── grafana-dashboards.yaml
├── grafana-pvc.yaml
├── grafana-deployment.yaml
├── grafana-service.yaml
├── grafana-ingress.yaml
├── bi-integration-configmap.yaml
├── n8n-servicemonitor.yaml
├── kustomization.yaml
├── README.md
└── DEPLOYMENT.md

argocd/
└── monitoring-application.yaml
```

### Files Modified
```
k8s/n8n/
├── configmap.yaml (added N8N_METRICS settings)
└── service.yaml (added Prometheus annotations)

CI-CD-SETUP-GUIDE.md (added monitoring section)
```

### Deployment Information

#### Prometheus
- **Image**: prom/prometheus:v2.48.0
- **Port**: 9090
- **Storage**: 100Gi (Premium SSD)
- **Retention**: 30 days
- **Access**: https://prometheus.igm.local

#### Grafana
- **Image**: grafana/grafana:10.2.2
- **Port**: 3000
- **Storage**: 10Gi (Premium SSD)
- **Plugins**: Azure Monitor, Clock, Simple JSON, Pie Chart
- **Access**: https://grafana.igm.local
- **Default Credentials**: admin / (set in grafana-secret.yaml)

#### Key Metrics Collected
- N8N workflow execution metrics
- N8N execution duration and error rates
- Kubernetes pod and node metrics
- Container CPU and memory usage
- Network I/O statistics
- Persistent volume usage

#### BI Tool Integration
- **Power BI**: Direct Prometheus API queries
- **Tableau**: Web Data Connector support
- **Looker**: Grafana plugin integration
- **Export Format**: JSON, CSV
- **Refresh Interval**: Configurable (default: hourly)

### Security Considerations
- Grafana credentials stored in Kubernetes Secret
- Azure credentials for Azure Monitor integration
- TLS/SSL support via Ingress
- RBAC configured for Prometheus ServiceAccount
- Basic authentication recommended for Prometheus Ingress

### Next Steps
1. Update `grafana-secret.yaml` with actual Azure credentials
2. Deploy monitoring stack: `kubectl apply -k k8s/monitoring/`
3. Configure DNS for prometheus.igm.local and grafana.igm.local
4. Set up TLS certificates (cert-manager recommended)
5. Configure BI tool connections
6. Create custom Grafana dashboards as needed

---

## [Previous] - N8N Deployment

### Added
- N8N deployment configuration
- PostgreSQL database integration
- Redis cache integration
- ArgoCD application setup
- CI/CD pipeline with GitHub Actions

### Infrastructure
- AKS cluster provisioning
- Application Gateway setup
- CosmosDB configuration
- Virtual Network configuration
