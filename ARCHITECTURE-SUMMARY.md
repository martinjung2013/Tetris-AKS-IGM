# Azure AKS 인프라 아키텍처 요약

## 🎯 업데이트된 구성 요약

### 1️⃣ MySQL Master-Replica 구성
**변경 전**: 단일 MySQL 서버
**변경 후**: 1 Master + 2 Read Replicas

```
MySQL Master (Read/Write)
  ├── Zone Redundant HA
  ├── Geo-redundant backup
  └── AAD Authentication
      ↓
  ┌───┴───┐
  ↓       ↓
Replica1  Replica2
(Read)    (Read)
```

**연결 정보**:
- Master: `mysql-master-rg-useful-cougar.mysql.database.azure.com`
- Replica 1: `mysql-replica1-rg-useful-cougar.mysql.database.azure.com`
- Replica 2: `mysql-replica2-rg-useful-cougar.mysql.database.azure.com`

### 2️⃣ Cosmos DB Java SDK Private Link
**변경 전**: VNet Service Endpoint
**변경 후**: Private Link Endpoint (Java SDK 호환)

**주요 특징**:
- ✅ Private Endpoint를 AKS Subnet에 직접 연결
- ✅ Java SDK Gateway Mode 지원
- ✅ Java SDK Direct Mode 지원
- ✅ 완전 Keyless (RBAC만 사용)

**Java 연결 코드**:
```java
import com.azure.cosmos.*;
import com.azure.identity.*;

DefaultAzureCredential credential = new DefaultAzureCredentialBuilder().build();

CosmosClient client = new CosmosClientBuilder()
    .endpoint("https://cosmos-rg-useful-cougar.documents.azure.com:443/")
    .credential(credential)
    .gatewayMode()  // Private Link 사용
    .buildClient();
```

### 3️⃣ N8N Workflow Automation
**신규 추가**: ArgoCD를 통한 N8N 배포

**구성**:
- Replicas: 2개 (고가용성)
- 인증: 기존 AKS 인증키 재사용 (`HEeG57YwIUD8qE9r`)
- 데이터베이스: MySQL Master
- 큐: Redis Cache (AAD Auth)
- 스토리지: Azure Premium Managed Disk (10Gi)

**접속 정보**:
- URL: https://n8n.local
- Username: `admin`
- Password: `HEeG57YwIUD8qE9r`

### 4️⃣ GitHub Actions CI/CD
**신규 추가**: 완전 자동화된 CI/CD 파이프라인

**Workflows**:
1. **aks-deploy.yaml**: Terraform 및 K8s 배포
   - Terraform Validate
   - Terraform Plan (PR)
   - Terraform Apply (main)
   - K8s 리소스 배포

2. **argocd-sync.yaml**: ArgoCD 애플리케이션 동기화
   - ArgoCD CLI 설치
   - Application 생성/업데이트
   - 자동 동기화
   - Health Check

---

## 📊 전체 아키텍처

```
                    Internet
                       ↓
            Application Gateway (Public IP: 20.249.157.190)
                       ↓
              ┌────────┴────────┐
              ↓                 ↓
         Load Balancer    ArgoCD Server
              ↓
    ┌─────────┴──────────┐
    ↓                    ↓
AKS Cluster          N8N Pods (x2)
(3 Nodes)
    ↓
    └──────┬──────┬──────┬────────┐
           ↓      ↓      ↓        ↓
       MySQL    Cosmos  Redis   Private
      Master     DB    Cache  Endpoints
         ↓
    ┌────┴────┐
Replica1  Replica2
```

---

## 🔐 인증 및 보안

### Keyless Authentication
모든 데이터베이스 서비스는 Managed Identity 사용:

| 서비스 | 인증 방식 | 특징 |
|--------|-----------|------|
| MySQL | AAD Authentication | System Assigned Identity |
| Cosmos DB | RBAC | `local_authentication_disabled = true` |
| Redis | AAD Authentication | System Assigned Identity |

### 공통 인증키 (기존 재사용)
- **키**: `HEeG57YwIUD8qE9r`
- **사용처**:
  - ArgoCD Admin Password
  - N8N Basic Auth Password
  - N8N Encryption Key

---

## 🌐 네트워크 구성

### VNet 구조
```
VNet: 10.0.0.0/8
├── AKS Subnet: 10.224.0.0/16
│   └── AKS Nodes, N8N Pods
├── Application Gateway Subnet: 10.1.0.0/24
│   └── App Gateway
└── Database Subnet: 10.2.0.0/24
    └── Private Endpoints
```

### Private DNS Zones
- `mysql.database.azure.com`
- `privatelink.documents.azure.com` (Cosmos DB)
- `privatelink.redis.cache.windows.net`

---

## 📁 파일 구조

```
D:\IGM\aks\
├── Terraform 구성
│   ├── main.tf              # AKS 클러스터
│   ├── providers.tf         # Provider 설정
│   ├── variables.tf         # 변수
│   ├── outputs.tf           # 출력
│   ├── network.tf           # VNet, Subnet, NSG
│   ├── appgateway.tf        # Application Gateway
│   ├── database.tf          # MySQL Master-Replica
│   ├── cosmosdb.tf          # Cosmos DB (Java Private Link)
│   ├── redis.tf             # Redis Cache
│   └── ssh.tf               # SSH 키
│
├── Kubernetes Manifests
│   └── k8s/n8n/
│       ├── namespace.yaml
│       ├── configmap.yaml
│       ├── secret.yaml
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── pvc.yaml
│       └── ingress.yaml
│
├── ArgoCD
│   └── argocd/
│       └── n8n-application.yaml
│
├── GitHub Actions
│   └── .github/workflows/
│       ├── aks-deploy.yaml
│       └── argocd-sync.yaml
│
└── Documentation
    ├── README.md
    ├── DEPLOYMENT-GUIDE.md
    └── ARCHITECTURE-SUMMARY.md
```

---

## 🚀 배포 순서

### 1. Terraform 인프라 배포
```bash
cd D:\IGM\aks
terraform init
terraform plan
terraform apply
```

### 2. ArgoCD Application 배포
```bash
kubectl apply -f argocd/n8n-application.yaml
```

### 3. GitHub Repository 설정
```bash
# Repository Secrets 추가
- AZURE_CREDENTIALS
- MYSQL_ADMIN_PASSWORD
- ARGOCD_PASSWORD
```

### 4. Git Push로 자동 배포
```bash
git add .
git commit -m "Deploy N8N with updated infrastructure"
git push origin main
```

---

## 📊 리소스 요약

| 리소스 | 수량 | SKU/크기 | 비고 |
|--------|------|----------|------|
| AKS Cluster | 1 | Standard_B2s x3 | Existing |
| MySQL Master | 1 | GP_Standard_D2ds_v4 | Zone Redundant HA |
| MySQL Replicas | 2 | GP_Standard_D2ds_v4 | Read-Only |
| Cosmos DB | 1 | Serverless | Private Link |
| Redis Cache | 1 | Standard C1 | AAD Auth |
| App Gateway | 1 | Standard_v2 | Capacity: 2 |
| N8N Pods | 2 | 512Mi/250m | High Availability |

---

## 🔧 운영 명령어

### Terraform
```bash
# 출력 확인
terraform output

# MySQL 엔드포인트 확인
terraform output mysql_master_fqdn
terraform output mysql_replica1_fqdn
terraform output mysql_replica2_fqdn
```

### Kubernetes
```bash
# N8N 상태 확인
kubectl get all -n n8n

# N8N 로그
kubectl logs -n n8n deployment/n8n -f

# N8N 스케일링
kubectl scale deployment/n8n -n n8n --replicas=3
```

### ArgoCD
```bash
# Application 상태
~/argocd.exe app get n8n

# 동기화
~/argocd.exe app sync n8n

# Rollback
~/argocd.exe app rollback n8n
```

---

## 🔍 모니터링

### Health Checks
```bash
# N8N Health
curl http://localhost:5678/healthz

# MySQL Master
az mysql flexible-server show \
  --resource-group rg-useful-cougar \
  --name mysql-master-rg-useful-cougar

# Cosmos DB
az cosmosdb show \
  --resource-group rg-useful-cougar \
  --name cosmos-rg-useful-cougar
```

---

## 📈 성능 최적화

### MySQL Read Scaling
```java
// Write to Master
String masterUrl = "jdbc:mysql://mysql-master-rg-useful-cougar.mysql.database.azure.com:3306/db";

// Read from Replicas (Load Balanced)
String[] replicaUrls = {
    "jdbc:mysql://mysql-replica1-rg-useful-cougar.mysql.database.azure.com:3306/db",
    "jdbc:mysql://mysql-replica2-rg-useful-cougar.mysql.database.azure.com:3306/db"
};
```

### Cosmos DB Connection Pooling
```java
CosmosClient client = new CosmosClientBuilder()
    .endpoint(endpoint)
    .credential(credential)
    .gatewayMode(
        new GatewayConnectionConfig()
            .setMaxConnectionPoolSize(1000)
    )
    .buildClient();
```

---

## 🎯 다음 단계

1. ✅ SSL/TLS 인증서 자동 갱신 (Let's Encrypt)
2. ✅ Prometheus + Grafana 모니터링
3. ✅ ELK Stack 로깅
4. ✅ Azure Monitor Integration
5. ✅ Backup 자동화
6. ✅ Disaster Recovery 계획

---

## 📚 참고 자료

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure MySQL Read Replicas](https://learn.microsoft.com/azure/mysql/flexible-server/concepts-read-replicas)
- [Cosmos DB Private Link](https://learn.microsoft.com/azure/cosmos-db/how-to-configure-private-endpoints)
- [N8N Self-Hosting](https://docs.n8n.io/hosting/)
- [ArgoCD GitOps](https://argo-cd.readthedocs.io/)
- [GitHub Actions Azure](https://github.com/Azure/actions)
