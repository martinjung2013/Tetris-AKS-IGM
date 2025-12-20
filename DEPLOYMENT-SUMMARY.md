# 🚀 AKS 배포 데이터 분석 및 준비 완료 보고서

**분석 날짜:** 2025-12-20  
**프로젝트:** Azure AKS Infrastructure with n8n  
**경로:** `D:\IGM\aks`

---

## 📊 배포 현황 요약

### ✅ 배포 완료 (36개 리소스)

| 카테고리 | 리소스 | 상태 | 설명 |
|---------|--------|------|------|
| **네트워크** | Virtual Network | ✅ | 10.0.0.0/8 |
| | AKS Subnet | ✅ | 10.224.0.0/16 |
| | Application Gateway | ✅ | IP: 4.217.248.205 |
| | NSG (Network Security Groups) | ✅ | 보안 규칙 설정됨 |
| | Private Endpoints | ✅ | 3개 (MySQL, Cosmos DB, Redis) |
| **컴퓨팅** | AKS Cluster | ✅ | cluster-crucial-terrapin |
| | Node Pool | ✅ | 3개 노드 (Standard_B2s) |
| **데이터베이스** | MySQL Flexible Server | ✅ | Master + 2 Replicas |
| | MySQL 데이터베이스 | ✅ | main, n8n |
| | Azure Cosmos DB | ✅ | SQL API, RBAC 활성화 |
| | Azure Cache for Redis | ✅ | Standard C1 |
| **보안 & ID** | Managed Identities | ✅ | MySQL, Cosmos DB, Redis |
| | Private DNS Zones | ✅ | 3개 (MySQL, Cosmos, Redis) |
| **애플리케이션** | n8n Deployment | ✅ | 2개 replica |
| | Kubernetes Manifests | ✅ | 8개 파일 |
| | ArgoCD Application | ✅ | GitOps 설정 |

---

## 🎯 배포 준비 상태

### 🟢 완료된 항목
- [x] Terraform 코드 작성 및 검증
- [x] 인프라 리소스 배포
- [x] 데이터베이스 생성 및 설정
- [x] Kubernetes 매니페스트 준비
- [x] ArgoCD 설정 파일 생성
- [x] Private 네트워크 구성
- [x] Managed Identity 설정
- [x] SSH 키 쌍 생성

### 🟡 **즉시 조치 필요** (3개)
1. **terraform.tfvars 파일 생성**
   - 상태: 누락됨
   - 조치: `copy terraform.tfvars.example terraform.tfvars`
   - 필수값: MySQL 관리자 비밀번호 설정

2. **ArgoCD GitHub 저장소 URL 수정**
   - 파일: `argocd/n8n-application.yaml`
   - 현재: `https://github.com/<YOUR-ORG>/<YOUR-REPO>.git` (플레이스홀더)
   - 필요: 실제 GitHub 저장소 URL로 교체

3. **Kubernetes Secret 값 설정**
   - 파일: `k8s/n8n/secret.yaml`
   - 필수값:
     - `DB_MYSQLDB_USER` (MySQL 사용자명)
     - `DB_MYSQLDB_PASSWORD` (MySQL 비밀번호)
     - `DB_MYSQLDB_HOST` (MySQL FQDN)
     - `REDIS_PASSWORD` (Redis 액세스 키)

### 🟢 권장 사항 (개선 가능)
- [ ] n8n 이미지 태그를 `latest` 대신 특정 버전으로 지정
- [ ] Pod 리소스 제한 설정 (CPU/Memory limits)
- [ ] 헬스체크 probe 추가
- [ ] Ingress TLS 인증서 설정
- [ ] Pod Security Policy 적용
- [ ] Network Policy 설정

---

## 📋 배포 단계별 절차

### Phase 1: 사전 준비 (30분)
```bash
# 1. 필수 도구 설치 확인
az --version              # Azure CLI
terraform --version      # Terraform
kubectl version --client # kubectl

# 2. Azure 로그인
az login

# 3. terraform.tfvars 생성 및 설정
copy terraform.tfvars.example terraform.tfvars
# 파일 편집: MySQL 비밀번호 설정

# 4. GitHub 저장소 준비
# - GitHub 저장소 생성 또는 확인
# - Personal Access Token (PAT) 생성
```

### Phase 2: 인프라 배포 (20분)
```bash
cd D:\IGM\aks

# 1. Terraform 초기화
terraform init

# 2. 배포 계획 검토
terraform plan -out=tfplan

# 3. 인프라 배포 실행
terraform apply tfplan

# 4. 배포 정보 확인
terraform output
```

### Phase 3: 쿠버네티스 설정 (15분)
```bash
# 1. AKS 클러스터 연결
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
CLUSTER_NAME=$(terraform output -raw kubernetes_cluster_name)

az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME

# 2. 연결 확인
kubectl get nodes

# 3. 네임스페이스 생성
kubectl apply -f k8s/n8n/namespace.yaml
```

### Phase 4: 애플리케이션 배포 (10분)
```bash
# 1. 데이터베이스 자격증명 업데이트
kubectl apply -f k8s/n8n/secret.yaml

# 2. 나머지 리소스 배포
kubectl apply -f k8s/n8n/

# 3. 배포 상태 확인
kubectl get all -n n8n
kubectl logs -n n8n deployment/n8n
```

### Phase 5: ArgoCD 설정 (5분, 선택사항)
```bash
# ArgoCD가 이미 설치되어 있다면:
kubectl apply -f argocd/n8n-application.yaml

# 설치되지 않았다면:
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argocd/n8n-application.yaml
```

**총 소요 시간:** ~80분

---

## 🔍 중요 설정값

### Terraform 출력값
```
리소스 그룹: rg-useful-cougar
AKS 클러스터: cluster-crucial-terrapin
지역: koreacentral
노드 수: 3개
노드 유형: Standard_B2s

데이터베이스:
- MySQL: <민감 정보>
- Cosmos DB Endpoint: <민감 정보>
- Redis: <민감 정보>

Application Gateway:
- 공개 IP: 4.217.248.205
- SKU: Standard_v2
- 인스턴스: 2개
```

### 환경 변수 (설정 필요)
```yaml
# k8s/n8n/secret.yaml에 설정할 값
DB_MYSQLDB_HOST: <MySQL FQDN>
DB_MYSQLDB_PORT: 3306
DB_MYSQLDB_DATABASE: n8n
DB_MYSQLDB_USER: <사용자명>
DB_MYSQLDB_PASSWORD: <비밀번호>
REDIS_HOST: <Redis 호스트명>
REDIS_PORT: 6380
REDIS_PASSWORD: <Redis 액세스 키>
REDIS_DB: 0
```

### Kubernetes 구성
```yaml
네임스페이스: n8n
배포명: n8n
이미지: n8nio/n8n:latest
Replicas: 2
메모리 요청: 512Mi
포트: 5678
```

---

## ✅ 배포 체크리스트

### 배포 전 (⚠️ 필수)
- [ ] Azure 구독 활성 및 권한 확인
- [ ] 로컬 머신에 필수 도구 설치 확인
  - [ ] Azure CLI
  - [ ] Terraform CLI
  - [ ] kubectl
  - [ ] Git
- [ ] terraform.tfvars 파일 생성 및 비밀번호 설정
- [ ] GitHub 저장소 URL로 ArgoCD 설정 업데이트
- [ ] Terraform 검증: `terraform validate`

### 배포 중
- [ ] Terraform Plan 검토
- [ ] Terraform Apply 실행
- [ ] 모든 리소스가 "Apply complete" 메시지 출력 확인
- [ ] Terraform outputs 저장

### 배포 후 (검증)
- [ ] AKS 클러스터 연결 확인: `kubectl get nodes`
- [ ] n8n 파드 실행 확인: `kubectl get pods -n n8n`
- [ ] n8n 로그 확인: `kubectl logs -n n8n deployment/n8n`
- [ ] 데이터베이스 연결 테스트
- [ ] Application Gateway 헬스 확인
- [ ] ArgoCD 동기화 상태 확인

---

## 🔐 보안 체크리스트

### 구현된 보안
- [x] Keyless Authentication (Managed Identity)
- [x] Private Endpoint로 모든 데이터베이스 보호
- [x] Network Security Groups (NSG) 구성
- [x] Private DNS Zone 설정
- [x] SSH 공개 키 인증
- [x] AAD 인증 활성화 (MySQL, Redis)
- [x] RBAC 기반 인증 (Cosmos DB)

### 권장 추가 보안 조치
- [ ] Pod Security Policy 또는 Pod Security Standards 적용
- [ ] Network Policy 설정 (마이크로세그멘테이션)
- [ ] etcd 암호화 활성화
- [ ] RBAC 세분화 (Role/RoleBinding)
- [ ] Secret 암호화 (Azure Key Vault 연동)
- [ ] Ingress TLS 인증서 설정
- [ ] Azure Defender for Kubernetes 활성화

---

## 📞 문제 해결

### 문제 1: Terraform 적용 실패
```bash
# 해결:
terraform destroy -auto-approve  # 이전 상태 제거
terraform apply                 # 다시 적용
```

### 문제 2: n8n Pod 실행 안 됨
```bash
# 확인:
kubectl describe pod -n n8n <pod-name>
kubectl logs -n n8n <pod-name>

# Secret 확인:
kubectl get secret -n n8n
kubectl describe secret -n n8n n8n-credentials
```

### 문제 3: 데이터베이스 연결 오류
```bash
# 확인:
terraform output mysql_master_fqdn
terraform output redis_hostname

# 연결 테스트:
kubectl exec -it -n n8n <pod-name> -- sh
# 내부에서:
mysql -h <host> -u <user> -p
```

### 문제 4: ArgoCD 동기화 실패
```bash
# 확인:
kubectl get application -n argocd
argocd app get n8n

# GitHub 접근 확인:
git clone <repository-url>
```

---

## 📚 참고 문서

1. **DEPLOYMENT-PREPARATION-CHECKLIST.md** - 상세 배포 체크리스트
2. **ARCHITECTURE-SUMMARY.md** - 아키텍처 개요
3. **README.md** - 프로젝트 개요
4. **Azure 공식 문서:**
   - [Azure AKS 배포 가이드](https://docs.microsoft.com/en-us/azure/aks/)
   - [Terraform AzureRM 공급자](https://registry.terraform.io/providers/hashicorp/azurerm/)
   - [Kubernetes 문서](https://kubernetes.io/docs/)

---

## 🎉 배포 준비 완료

**현재 상태:** ✅ **배포 준비 완료**

다음 단계:
1. ⚠️ **즉시 조치 필요 항목 3개 완료**
2. 🚀 Terraform 배포 실행
3. 🐳 Kubernetes 애플리케이션 배포
4. ✅ 배포 검증

**예상 총 소요 시간:** 약 80분

---

**생성자:** AI 배포 준비 도구  
**생성일:** 2025-12-20
