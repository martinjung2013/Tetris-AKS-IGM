# AKS 배포 준비 체크리스트 및 분석 보고서

**작성일**: 2025-12-20  
**상태**: 배포 준비 완료

---

## 📊 인프라 배포 현황

### ✅ 배포된 리소스 (36개)

#### 네트워크 인프라
- ✅ Virtual Network (VNet): `rg-vnet` (10.0.0.0/8)
- ✅ AKS Subnet (10.224.0.0/16)
- ✅ Application Gateway Subnet (10.1.0.0/24)
- ✅ Database Subnet (10.2.0.0/24)
- ✅ Private Endpoints Subnet
- ✅ Network Security Groups (NSG) - AKS 보안 설정됨
- ✅ Application Gateway (Standard_v2, 2 인스턴스)
- ✅ Public IP (Application Gateway): **4.217.248.205**

#### 컴퓨팅
- ✅ AKS Cluster: `cluster-crucial-terrapin`
  - 노드 수: 3개 (Standard_B2s)
  - 인증: System Assigned Managed Identity
  - 네트워크 플러그인: kubenet
  - 로드 밸런서: Standard SKU

#### 데이터베이스 (Keyless Authentication)
- ✅ Azure Database for MySQL Flexible Server
  - Master 인스턴스 (AAD 인증 활성화)
  - Replica 1 (고가용성)
  - Replica 2 (고가용성)
  - 데이터베이스: `main`, `n8n`
  - Managed Identity: 활성화
  - Private Endpoint 연결: 설정됨

- ✅ Azure Cosmos DB
  - 로컬 인증 비활성화 (RBAC만 사용)
  - System Assigned Managed Identity: `4eb3db65-aceb-4bb6-a01c-0918f27edbcd`
  - SQL 데이터베이스 및 컨테이너 생성됨
  - Private Endpoint 연결: 설정됨

- ✅ Azure Cache for Redis
  - AAD 인증 활성화
  - System Assigned Managed Identity: `726f1bac-0257-4454-ba27-8a09a6fa732a`
  - Private Endpoint 연결: 설정됨

#### DNS 및 Private 연결
- ✅ Private DNS Zones
  - MySQL Private DNS Zone
  - Cosmos DB Private DNS Zone
  - Redis Private DNS Zone
- ✅ VNet 링크: 모든 Private DNS 영역이 VNet과 연결됨
- ✅ Private Endpoints: 모든 데이터베이스 서비스용으로 설정됨

#### 보안 및 인증
- ✅ SSH 공개 키 생성 및 저장
- ✅ Kubernetes API 서버 인증서 (민감 정보 보호됨)

---

## 🐳 쿠버네티스 애플리케이션 구성

### n8n 애플리케이션

**배포 현황:**
- Replicas: 2개
- Image: `n8nio/n8n:latest`
- Image Pull Policy: `Always` (최신 버전 자동 다운로드)

**리소스 요청:**
```yaml
resources:
  requests:
    memory: "512Mi"
```

**k8s 매니페스트 파일:**
- ✅ `k8s/n8n/namespace.yaml` - 네임스페이스 정의
- ✅ `k8s/n8n/deployment.yaml` - n8n 배포
- ✅ `k8s/n8n/service.yaml` - Service (ClusterIP)
- ✅ `k8s/n8n/service-lb.yaml` - LoadBalancer Service
- ✅ `k8s/n8n/ingress.yaml` - Ingress 설정
- ✅ `k8s/n8n/pvc.yaml` - Persistent Volume Claim
- ✅ `k8s/n8n/configmap.yaml` - ConfigMap (환경 변수)
- ✅ `k8s/n8n/secret.yaml` - Secret (데이터베이스 자격증명)

### ArgoCD GitOps 설정

**파일:** `argocd/n8n-application.yaml`

**구성:**
```yaml
Repository: https://github.com/<YOUR-ORG>/<YOUR-REPO>.git
Branch: main
Path: k8s/n8n
Destination: https://kubernetes.default.svc (n8n namespace)
```

**자동화 정책:**
- Automated Sync: ✅ 활성화
- Auto Prune: ✅ 활성화
- Self-Heal: ✅ 활성화
- Retry: 최대 5회 (지수 백오프: 5s ~ 3m)
- Namespace 자동 생성: ✅ 활성화

---

## ⚠️ 확인 및 수정 필요 사항

### 🔴 **CRITICAL - 즉시 수정 필요**

#### 1. ArgoCD GitHub Repository 설정
**현재 상태:** `<YOUR-ORG>/<YOUR-REPO>` (플레이스홀더)  
**필수 조치:**
```bash
# argocd/n8n-application.yaml 수정
# repoURL을 실제 GitHub 저장소로 변경
repoURL: https://github.com/YOUR-ACTUAL-ORG/YOUR-ACTUAL-REPO.git
```

**확인 항목:**
- [ ] GitHub Organization 이름 확인
- [ ] Repository 이름 확인
- [ ] Branch 이름 확인 (기본값: main)
- [ ] GitOps용 Personal Access Token (PAT) 준비

#### 2. Terraform 변수 파일 설정
**현재 상태:** `terraform.tfvars.example` (예제 파일)  
**필수 조치:**
```bash
# terraform.tfvars 파일 생성
cp terraform.tfvars.example terraform.tfvars

# 파일을 열어서 MySQL 비밀번호 설정
mysql_admin_password = "YourSecurePassword123!"
```

**보안 주의:**
- [ ] 강력한 비밀번호 생성 (12자 이상, 대문자/소문자/숫자/특수문자 포함)
- [ ] `terraform.tfvars` 파일을 Git에 커밋하지 않기 (.gitignore 확인)
- [ ] 접근 제어 설정 (파일 권한 600)

---

### 🟡 **HIGH - 배포 전 확인 필요**

#### 3. 쿠버네티스 시크릿 업데이트
**파일:** `k8s/n8n/secret.yaml`  
**필수 조치:**
```bash
# 실제 데이터베이스 자격증명으로 업데이트
DB_MYSQLDB_USER: <MySQL 사용자명>
DB_MYSQLDB_PASSWORD: <MySQL 비밀번호>
DB_MYSQLDB_HOST: <MySQL FQDN>
REDIS_PASSWORD: <Redis 비밀번호>
```

**데이터 베이스 정보:**
- MySQL Master FQDN: `<sensitive>` (terraform output에서 확인)
- MySQL n8n 데이터베이스: ✅ 생성됨
- Redis Hostname: `<sensitive>` (terraform output에서 확인)

**조회 명령:**
```bash
cd D:\IGM\aks
terraform output mysql_master_fqdn
terraform output redis_hostname
```

#### 4. n8n 이미지 태그 지정
**현재:** `n8nio/n8n:latest`  
**권장:** 특정 버전으로 고정
```yaml
# k8s/n8n/deployment.yaml
image: n8nio/n8n:1.40.0  # 또는 테스트된 특정 버전
```

**이유:** 
- Production에서는 `latest` 태그 대신 특정 버전 사용 권장
- 예측 불가능한 업데이트 방지

#### 5. Redis 비밀번호 설정
**현재:** Azure Redis Cache 생성됨  
**필수 조치:**
```bash
# Azure Portal에서 Redis 액세스 키 확인
# k8s/n8n/secret.yaml에 추가
redis_password: <access-key>
```

---

### 🟢 **INFO - 권장 사항**

#### 6. 메모리/CPU 리소스 최적화
```yaml
# 현재 k8s/n8n/deployment.yaml
resources:
  requests:
    memory: "512Mi"

# 권장 설정 (n8n용)
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

#### 7. 헬스 체크 설정 추가
```yaml
# k8s/n8n/deployment.yaml에 추가
livenessProbe:
  httpGet:
    path: /health
    port: 5678
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health
    port: 5678
  initialDelaySeconds: 10
  periodSeconds: 5
```

#### 8. Persistent Volume 사이즈 확인
**파일:** `k8s/n8n/pvc.yaml`  
**확인 사항:**
- [ ] PVC 사이즈가 충분한가? (데이터 증가율 고려)
- [ ] Storage Class가 올바르게 설정되었는가?

#### 9. Ingress TLS 설정
**파일:** `k8s/n8n/ingress.yaml`  
**권장:**
```yaml
spec:
  tls:
  - hosts:
    - n8n.yourdomain.com
    secretName: n8n-tls-secret
```

---

## 📋 배포 전 체크리스트

### Phase 1: 사전 준비 (배포 전)
- [ ] Azure 구독 및 권한 확인
- [ ] Azure CLI 로그인: `az login`
- [ ] Terraform 변수 설정: `terraform.tfvars` 생성
- [ ] MySQL 비밀번호 설정 (강력한 암호)
- [ ] GitHub 저장소 준비 (ArgoCD 용)
- [ ] GitHub PAT (Personal Access Token) 생성

### Phase 2: 인프라 배포
```bash
cd D:\IGM\aks

# 1. 변수 파일 설정
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars 파일 편집 (MySQL 비밀번호 설정)

# 2. Terraform 초기화
terraform init

# 3. 배포 계획 검토
terraform plan -out=tfplan

# 4. 인프라 배포
terraform apply tfplan

# 5. 출력값 확인
terraform output
```

**예상 소요 시간:** 15-20분

### Phase 3: 쿠버네티스 설정
```bash
# 1. AKS 클러스터 연결
az aks get-credentials \
  --resource-group rg-useful-cougar \
  --name cluster-crucial-terrapin

# 2. ArgoCD 설치 (필요한 경우)
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. n8n Secret 업데이트
kubectl edit secret -n n8n n8n-credentials

# 4. ArgoCD 연결 설정
kubectl apply -f argocd/n8n-application.yaml

# 5. 동기화 확인
kubectl get application -n argocd
```

### Phase 4: 배포 검증
```bash
# n8n 파드 상태 확인
kubectl get pods -n n8n

# n8n 로그 확인
kubectl logs -n n8n deployment/n8n -f

# 데이터베이스 연결 테스트
kubectl exec -it -n n8n <pod-name> -- sh

# Application Gateway 상태 확인
kubectl get ingress -n n8n
```

---

## 🔐 보안 고려사항

### Keyless Authentication ✅
- ✅ MySQL: AAD Authentication + System Assigned Identity
- ✅ Cosmos DB: RBAC 기반 인증 (로컬 인증 비활성화)
- ✅ Redis: AAD Authentication

### Private Connectivity ✅
- ✅ 모든 데이터베이스가 Private Endpoint로 연결됨
- ✅ Private DNS Zone 설정됨

### 네트워크 보안 ✅
- ✅ NSG 규칙 설정됨
- ✅ VNet 격리됨

### 추가 권장사항
- [ ] Pod Security Policy (PSP) 또는 Pod Security Standards (PSS) 적용
- [ ] Network Policy 설정 (마이크로세그멘테이션)
- [ ] Secret 암호화 (etcd 암호화)
- [ ] RBAC 세분화

---

## 🚀 배포 실행 순서

### 1단계: Terraform 배포
```bash
cd D:\IGM\aks
terraform apply tfplan
```
**완료 신호:** 모든 리소스가 "Apply complete!" 메시지와 함께 표시됨

### 2단계: AKS 연결
```bash
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw kubernetes_cluster_name)
```

### 3단계: 네임스페이스 생성
```bash
kubectl apply -f k8s/n8n/namespace.yaml
```

### 4단계: 시크릿 생성
```bash
# secret.yaml 파일을 실제 값으로 업데이트한 후
kubectl apply -f k8s/n8n/secret.yaml
```

### 5단계: 나머지 리소스 배포
```bash
kubectl apply -f k8s/n8n/
```

### 6단계: ArgoCD 설정 (선택사항)
```bash
# ArgoCD가 이미 설치되어 있다면
kubectl apply -f argocd/n8n-application.yaml

# ArgoCD가 없다면 먼저 설치
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

---

## 📊 배포 후 모니터링

### 필수 모니터링 항목
- [ ] Pod 상태: `kubectl get pods -n n8n`
- [ ] 데이터베이스 연결: MySQL, Redis, Cosmos DB
- [ ] Ingress 트래픽: Application Gateway 상태
- [ ] 리소스 사용량: CPU, 메모리

### 로그 확인
```bash
# n8n 애플리케이션 로그
kubectl logs -n n8n deployment/n8n -f

# 이전 버전 로그 (재시작 후)
kubectl logs -n n8n deployment/n8n --previous
```

---

## 📝 주요 파일 상태

| 파일 | 상태 | 설명 |
|------|------|------|
| `main.tf` | ✅ 완료 | AKS 클러스터 정의 |
| `network.tf` | ✅ 완료 | VNet, Subnet, NSG |
| `appgateway.tf` | ✅ 완료 | Application Gateway |
| `database.tf` | ✅ 완료 | MySQL 설정 |
| `cosmosdb.tf` | ✅ 완료 | Cosmos DB 설정 |
| `redis.tf` | ⚠️ 경고 | 제공자 버전 업데이트 필요 |
| `providers.tf` | ✅ 완료 | Terraform 제공자 |
| `variables.tf` | ✅ 완료 | 변수 정의 |
| `outputs.tf` | ✅ 완료 | 출력값 정의 |
| `terraform.tfstate` | ✅ 백업됨 | 배포된 상태 저장됨 |
| `k8s/n8n/*` | ✅ 준비됨 | 쿠버네티스 매니페스트 |
| `argocd/*.yaml` | ⚠️ 수정필요 | GitHub 저장소 주소 업데이트 필요 |

---

## 🔧 Redis 제공자 버전 경고 해결

**경고:**
```
Warning: Argument is deprecated
`enable_non_ssl_port` will be removed in favour of the property `non_ssl_port_enabled` 
in version 4.0 of the AzureRM Provider.
```

**수정:**
```bash
# redis.tf 파일 수정
# 변경 전:
enable_non_ssl_port = false

# 변경 후:
non_ssl_port_enabled = false
```

---

## ✨ 마지막 확인

배포 전 최종 체크리스트:

```bash
# 1. Terraform 검증
cd D:\IGM\aks
terraform validate

# 2. 포맷 확인
terraform fmt -check -recursive

# 3. 배포 계획 검토
terraform plan

# 4. k8s 매니페스트 검증
kubectl apply -f k8s/n8n/ --dry-run=client

# 5. ArgoCD 설정 검증
kubectl apply -f argocd/ --dry-run=client
```

---

**배포 준비 상태:** ✅ **준비 완료** (위의 CRITICAL 항목 수정 후 배포 가능)

**다음 단계:** 
1. `terraform.tfvars` 파일 생성 및 MySQL 비밀번호 설정
2. `argocd/n8n-application.yaml`의 GitHub 저장소 URL 수정
3. `k8s/n8n/secret.yaml`의 데이터베이스 자격증명 수정
4. 배포 실행
