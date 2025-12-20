# Azure AKS + N8N 배포 가이드

## 📋 목차
1. [인프라 구성](#인프라-구성)
2. [MySQL Master-Replica 설정](#mysql-master-replica-설정)
3. [Cosmos DB Java SDK Private Link](#cosmos-db-java-sdk-private-link)
4. [N8N 배포](#n8n-배포)
5. [ArgoCD 설정](#argocd-설정)
6. [GitHub Actions CI/CD](#github-actions-cicd)

---

## 인프라 구성

### 업데이트된 아키텍처

```
Internet → Application Gateway → AKS Cluster
                                      ↓
                    ┌─────────────────┼─────────────────┐
                    ↓                 ↓                 ↓
            MySQL Master      Cosmos DB        Redis Cache
           (+ 2 Replicas)   (Java Private)     (AAD Auth)
```

### 주요 변경사항

#### 1. MySQL Master-Replica 구성 ✅
- **Master**: 1개 (Zone Redundant HA)
- **Read Replicas**: 2개
- **특징**:
  - Geo-redundant backup 활성화
  - Zone Redundant High Availability
  - AAD Authentication (Keyless)

#### 2. Cosmos DB Private Link (Java SDK) ✅
- **Private Endpoint**: AKS Subnet에 직접 연결
- **Java SDK 지원**:
  - Gateway Mode: Private Endpoint 지원
  - Direct Mode: Private Endpoint 지원
- **완전 Keyless**: `local_authentication_disabled = true`

#### 3. N8N Workflow Automation ✅
- **기존 인증키 사용**: ArgoCD와 동일한 인증키 재사용
- **고가용성**: 2 Replicas
- **데이터베이스**: MySQL Master 연결
- **큐**: Redis Cache 사용

---

## MySQL Master-Replica 설정

### Terraform 구성

```hcl
# Master 노드
resource "azurerm_mysql_flexible_server" "main" {
  high_availability {
    mode = "ZoneRedundant"
  }
  geo_redundant_backup_enabled = true
}

# Read Replica 1
resource "azurerm_mysql_flexible_server" "replica1" {
  create_mode      = "Replica"
  source_server_id = azurerm_mysql_flexible_server.main.id
}

# Read Replica 2
resource "azurerm_mysql_flexible_server" "replica2" {
  create_mode      = "Replica"
  source_server_id = azurerm_mysql_flexible_server.main.id
}
```

### 연결 문자열

**Master (Read/Write)**:
```
mysql-master-rg-useful-cougar.mysql.database.azure.com
```

**Replica 1 (Read-Only)**:
```
mysql-replica1-rg-useful-cougar.mysql.database.azure.com
```

**Replica 2 (Read-Only)**:
```
mysql-replica2-rg-useful-cougar.mysql.database.azure.com
```

---

## Cosmos DB Java SDK Private Link

### Java SDK 연결 설정

#### Pom.xml 의존성

```xml
<dependency>
    <groupId>com.azure</groupId>
    <artifactId>azure-cosmos</artifactId>
    <version>4.50.0</version>
</dependency>
<dependency>
    <groupId>com.azure</groupId>
    <artifactId>azure-identity</artifactId>
    <version>1.11.0</version>
</dependency>
```

#### Gateway Mode (권장 - Private Link)

```java
import com.azure.cosmos.*;
import com.azure.identity.*;

// Managed Identity 사용 (Keyless)
DefaultAzureCredential credential = new DefaultAzureCredentialBuilder().build();

CosmosClient client = new CosmosClientBuilder()
    .endpoint("https://cosmos-rg-useful-cougar.documents.azure.com:443/")
    .credential(credential)
    .gatewayMode()  // Private Link 사용
    .consistencyLevel(ConsistencyLevel.SESSION)
    .buildClient();
```

#### Direct Mode (Private Link)

```java
CosmosClient client = new CosmosClientBuilder()
    .endpoint("https://cosmos-rg-useful-cougar.documents.azure.com:443/")
    .credential(credential)
    .directMode()  // Direct mode with Private Link
    .consistencyLevel(ConsistencyLevel.SESSION)
    .buildClient();
```

### Private Endpoint 확인

```bash
# Private Endpoint 연결 확인
az network private-endpoint list \
  --resource-group rg-useful-cougar \
  --query "[?name=='cosmosdb-aks-private-endpoint']"

# Private DNS Zone 확인
az network private-dns zone show \
  --resource-group rg-useful-cougar \
  --name privatelink.documents.azure.com
```

---

## N8N 배포

### 1. Terraform으로 인프라 배포

```bash
cd D:\IGM\aks

# 변수 설정
export TF_VAR_mysql_admin_password="YourSecurePassword123!"

# 배포
terraform init
terraform plan
terraform apply
```

### 2. ArgoCD를 통한 N8N 배포

```bash
# ArgoCD 로그인
cd ~
./argocd.exe login 20.249.157.190 \
  --username admin \
  --password HEeG57YwIUD8qE9r \
  --insecure

# N8N Application 생성
kubectl apply -f argocd/n8n-application.yaml

# 또는 CLI로 생성
./argocd.exe app create n8n \
  --repo https://github.com/<YOUR-ORG>/<YOUR-REPO>.git \
  --path k8s/n8n \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace n8n \
  --sync-policy automated

# 동기화
./argocd.exe app sync n8n
```

### 3. N8N 접속

```bash
# Ingress 확인
kubectl get ingress -n n8n

# Port Forward (로컬 테스트)
kubectl port-forward -n n8n svc/n8n 5678:80
```

**접속 정보**:
- URL: http://localhost:5678 또는 https://n8n.local
- Username: `admin`
- Password: `HEeG57YwIUD8qE9r` (기존 AKS 인증키 재사용)

---

## ArgoCD 설정

### N8N Application 상태 확인

```bash
# Application 목록
./argocd.exe app list

# N8N 상세 정보
./argocd.exe app get n8n

# 동기화 상태
./argocd.exe app wait n8n --health
```

### 수동 동기화

```bash
# 강제 동기화
./argocd.exe app sync n8n --force --prune

# Rollback
./argocd.exe app rollback n8n
```

---

## GitHub Actions CI/CD

### 1. GitHub Secrets 설정

Repository Settings → Secrets and variables → Actions에서 다음을 설정:

```
AZURE_CREDENTIALS: Azure 서비스 주체 JSON
MYSQL_ADMIN_PASSWORD: MySQL 관리자 비밀번호
ARGOCD_PASSWORD: ArgoCD admin 비밀번호 (HEeG57YwIUD8qE9r)
```

#### Azure 서비스 주체 생성

```bash
az ad sp create-for-rbac \
  --name "github-actions-aks" \
  --role contributor \
  --scopes /subscriptions/df0d11f5-ae3d-4abd-bd72-862d485c4ed6/resourceGroups/rg-useful-cougar \
  --sdk-auth
```

### 2. Workflow 트리거

#### Infrastructure CI/CD (aks-deploy.yaml)
- **트리거**: `*.tf` 또는 `k8s/**` 파일 변경 시
- **동작**:
  1. Terraform 검증
  2. Terraform Plan (PR)
  3. Terraform Apply (main 브랜치)
  4. K8s 리소스 배포

#### ArgoCD Sync (argocd-sync.yaml)
- **트리거**: `k8s/**` 또는 `argocd/**` 파일 변경 시
- **동작**:
  1. ArgoCD CLI 설치
  2. ArgoCD 로그인
  3. Application 생성/업데이트
  4. 동기화 및 상태 확인

### 3. 배포 프로세스

```
1. 코드 변경 (main.tf, k8s/n8n/*.yaml)
   ↓
2. Git Push to GitHub
   ↓
3. GitHub Actions 트리거
   ↓
4. Terraform Apply (인프라 변경)
   ↓
5. ArgoCD Sync (K8s 리소스 배포)
   ↓
6. N8N 서비스 업데이트
```

---

## 인증키 관리

### 기존 인증키 재사용

N8N은 기존 AKS에서 사용하던 인증키를 재사용합니다:

**공통 인증키**: `HEeG57YwIUD8qE9r`

사용처:
- ✅ ArgoCD Admin Password
- ✅ N8N Basic Auth Password
- ✅ N8N Encryption Key

### 보안 권장사항

1. **프로덕션 환경**: Azure Key Vault 사용
   ```bash
   # Key Vault 생성
   az keyvault create \
     --name kv-aks-secrets \
     --resource-group rg-useful-cougar \
     --location koreacentral

   # Secret 저장
   az keyvault secret set \
     --vault-name kv-aks-secrets \
     --name n8n-auth-key \
     --value "HEeG57YwIUD8qE9r"
   ```

2. **Kubernetes Secret 암호화**:
   - Sealed Secrets 또는 External Secrets Operator 사용

---

## 모니터링

### N8N 헬스 체크

```bash
# Pod 상태
kubectl get pods -n n8n

# 로그 확인
kubectl logs -n n8n deployment/n8n -f

# 리소스 사용량
kubectl top pods -n n8n
```

### ArgoCD에서 확인

```bash
# Application 상태
./argocd.exe app get n8n

# 동기화 히스토리
./argocd.exe app history n8n
```

---

## 트러블슈팅

### N8N Pod가 시작되지 않음

```bash
# 이벤트 확인
kubectl describe pod -n n8n <pod-name>

# MySQL 연결 확인
kubectl exec -it -n n8n <pod-name> -- ping mysql-master-rg-useful-cougar.mysql.database.azure.com
```

### ArgoCD 동기화 실패

```bash
# 상세 로그
./argocd.exe app get n8n --show-operation

# 수동 동기화 재시도
./argocd.exe app sync n8n --force
```

### Cosmos DB 연결 실패 (Java)

```bash
# Private Endpoint 상태 확인
az network private-endpoint show \
  --resource-group rg-useful-cougar \
  --name cosmosdb-aks-private-endpoint

# DNS 해상도 확인
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup cosmos-rg-useful-cougar.documents.azure.com
```

---

## 다음 단계

1. ✅ Application Gateway HTTPS 인증서 설정
2. ✅ N8N 커스텀 도메인 연결
3. ✅ Prometheus + Grafana 모니터링 구성
4. ✅ Log Analytics Workspace 연결
5. ✅ Backup 및 DR 전략 수립

---

## 참고 자료

- [Azure MySQL Flexible Server - Read Replicas](https://learn.microsoft.com/azure/mysql/flexible-server/concepts-read-replicas)
- [Cosmos DB Java SDK - Private Link](https://learn.microsoft.com/azure/cosmos-db/how-to-configure-private-endpoints)
- [N8N Documentation](https://docs.n8n.io/)
- [ArgoCD User Guide](https://argo-cd.readthedocs.io/)
- [GitHub Actions for Azure](https://github.com/Azure/actions)
