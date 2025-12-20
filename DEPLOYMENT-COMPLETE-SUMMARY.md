# AKS 배포 및 CI/CD 파이프라인 구성 완료 보고서

## 📋 실행 요약

**배포 날짜**: 2025-12-20
**배포 타입**: 신규 AKS 클러스터 배포 + ArgoCD CI/CD 파이프라인 구성
**상태**: ✅ 성공

---

## 🎯 완료된 작업

### 1. 인프라 배포 (Terraform)

✅ **Azure 리소스 배포 완료**
- 리소스 그룹: `rg-liked-yak`
- 리전: Korea Central
- 배포 시간: ~20분

#### 배포된 리소스 (총 36개):

**컴퓨팅**
- ✅ AKS 클러스터: `cluster-right-marmoset`
  - 노드 수: 3
  - VM 크기: Standard_B2s
  - Kubernetes 버전: 1.33.5

**데이터베이스**
- ✅ MySQL Flexible Server (Zone Redundant HA)
  - 마스터: `mysql-master-rg-liked-yak`
  - 읽기 복제본 1: `mysql-replica1-rg-liked-yak`
  - 읽기 복제본 2: `mysql-replica2-rg-liked-yak`
  - 데이터베이스: `appdb`, `n8n`

- ✅ CosmosDB (Private Mode)
  - 계정: `cosmos-rg-liked-yak`
  - 데이터베이스: `appdb`
  - 컨테이너: `items`

- ✅ PostgreSQL (Kubernetes 내부)
  - n8n 워크플로우 엔진용
  - 사용자: `n8nuser`
  - 데이터베이스: `n8n`

**캐싱**
- ✅ Redis Cache (Private Endpoint)
  - 인스턴스: `redis-rg-liked-yak`
  - SKU: Standard

**네트워킹**
- ✅ Virtual Network: `rg-vnet`
  - 서브넷: AKS, Database, AppGW, Private Endpoints
- ✅ Application Gateway
  - Public IP: `4.230.129.183`
  - SKU: Standard_v2
- ✅ Private Endpoints (MySQL, CosmosDB, Redis)
- ✅ Private DNS Zones
- ✅ Network Security Groups

---

### 2. Kubernetes 애플리케이션 배포

#### ArgoCD 배포 ✅
- **네임스페이스**: argocd
- **서비스 타입**: LoadBalancer
- **접속 정보**:
  - URL: http://20.249.152.142 (HTTP) / https://20.249.152.142 (HTTPS)
  - Username: `admin`
  - Initial Password: `FJca8gqCK5Lx7N1B`

**상태**:
- ✅ 모든 ArgoCD 컴포넌트 Running (7/7)
- ✅ LoadBalancer Public IP 할당 완료

#### N8N 워크플로우 엔진 배포 🔄
- **네임스페이스**: n8n
- **데이터베이스**: PostgreSQL (클러스터 내부)
- **캐시**: Azure Redis (Private Endpoint)

**현재 상태**:
- 🔄 PostgreSQL 준비 완료
- 🔄 Secret 구성 완료
- ⚠️ n8n 파드 시작 중 (비밀번호 인코딩 이슈 해결 중)

---

### 3. CI/CD 파이프라인 구성 ✅

#### CI (Continuous Integration) - GitHub Actions

**새로 생성된 워크플로우**:

1. **`ci.yaml`** - 메인 CI 파이프라인
   - ✅ Kubernetes 매니페스트 Lint 및 검증
   - ✅ 보안 취약점 스캔 (Trivy)
   - ✅ 테스트 실행 (확장 가능)
   - ✅ 빌드 상태 확인

**업데이트된 워크플로우**:

2. **`aks-deploy.yaml`** - 인프라 및 ArgoCD 통합
   - ✅ Terraform 검증 및 배포
   - ✅ ArgoCD 동기화 트리거
   - ✅ 새 리소스 그룹 정보 반영 (`rg-liked-yak`, `cluster-right-marmoset`)

3. **`argocd-sync.yaml`** - ArgoCD 수동 동기화
   - ✅ k8s/ 경로 변경 감지
   - ✅ ArgoCD 애플리케이션 생성/업데이트
   - ✅ 새 ArgoCD 서버 IP 반영 (`20.249.152.142`)

#### CD (Continuous Deployment) - ArgoCD

**GitOps 기반 자동 배포**:
- ✅ Git 리포지토리 폴링 (3분마다)
- ✅ 자동 동기화 활성화
  - Prune: true (삭제된 리소스 자동 제거)
  - Self-Heal: true (상태 자동 복구)
- ✅ Health Check 및 모니터링

---

## 📊 CI/CD 파이프라인 아키텍처

```
┌─────────────────┐
│  GitHub Repo    │
│  (코드 푸시)     │
└────────┬────────┘
         │
         ├─────────────────┐
         │                 │
         v                 v
┌─────────────────┐  ┌─────────────────┐
│  GitHub Actions │  │  GitHub Actions │
│  (CI - ci.yaml) │  │  (Infrastructure)│
├─────────────────┤  ├─────────────────┤
│ • Lint & Valid  │  │ • Terraform     │
│ • Security Scan │  │ • AKS Setup     │
│ • Tests         │  │ • Notify ArgoCD │
└────────┬────────┘  └────────┬────────┘
         │                    │
         └──────────┬─────────┘
                    │
                    v
            ┌───────────────┐
            │    ArgoCD     │
            │  (CD Engine)  │
            ├───────────────┤
            │ • Git Poll    │
            │ • Auto Sync   │
            │ • Health Check│
            └───────┬───────┘
                    │
                    v
            ┌───────────────┐
            │  AKS Cluster  │
            │ (rg-liked-yak)│
            ├───────────────┤
            │ • n8n         │
            │ • PostgreSQL  │
            │ • Redis       │
            └───────────────┘
```

---

## 🔐 보안 및 접속 정보

### ArgoCD
- **URL**: http://20.249.152.142 또는 https://20.249.152.142
- **Username**: admin
- **Password**: `FJca8gqCK5Lx7N1B` (⚠️ 즉시 변경 필요!)

### Application Gateway
- **Public IP**: 4.230.129.183
- **Ports**: 80 (HTTP), 443 (HTTPS)

### 데이터베이스
- **MySQL Master**: `mysql-master-rg-liked-yak.mysql.database.azure.com`
- **PostgreSQL**: `postgres.n8n.svc.cluster.local:5432` (클러스터 내부)
- **CosmosDB**: Private Endpoint only
- **Redis**: `redis-rg-liked-yak.redis.cache.windows.net` (Private Endpoint)

---

## ⚙️ 다음 설정 단계

### 필수 (즉시 수행)

1. **ArgoCD 비밀번호 변경**
   ```bash
   argocd account update-password --server 20.249.152.142 --insecure
   ```

2. **GitHub Secrets 설정**
   - `AZURE_CREDENTIALS`: Azure 서비스 주체 자격 증명
   - `MYSQL_ADMIN_PASSWORD`: `76020025aa!!ZX`
   - `ARGOCD_PASSWORD`: (변경한 새 비밀번호)

3. **ArgoCD Application 배포**
   - `argocd/n8n-application.yaml`에서 `<YOUR-ORG>/<YOUR-REPO>` 수정
   ```bash
   kubectl apply -f argocd/n8n-application.yaml
   ```

4. **CI/CD 파이프라인 테스트**
   ```bash
   # 테스트 커밋
   git add .
   git commit -m "Test CI/CD pipeline"
   git push origin main

   # GitHub Actions 확인
   # ArgoCD UI에서 배포 상태 확인
   ```

### 권장 (단계별 진행)

5. **Ingress Controller 설정** (선택사항)
   - NGINX Ingress Controller 또는 Application Gateway Ingress Controller
   - TLS/SSL 인증서 설정

6. **모니터링 설정**
   - Prometheus + Grafana
   - Azure Monitor 통합

7. **백업 및 재해 복구**
   - Velero 설정
   - 데이터베이스 자동 백업 확인

8. **보안 강화**
   - Network Policies
   - Pod Security Standards
   - Sealed Secrets 또는 External Secrets

---

## 📝 설정 파일 위치

| 구성 요소 | 파일 경로 |
|----------|----------|
| Terraform | `*.tf` (루트 디렉토리) |
| Kubernetes Manifests | `k8s/n8n/*.yaml` |
| ArgoCD Application | `argocd/n8n-application.yaml` |
| CI Workflow | `.github/workflows/ci.yaml` |
| Infrastructure Workflow | `.github/workflows/aks-deploy.yaml` |
| ArgoCD Sync Workflow | `.github/workflows/argocd-sync.yaml` |
| Setup Guide | `CI-CD-SETUP-GUIDE.md` |

---

## 🔧 트러블슈팅

### N8N 파드가 시작되지 않는 경우

현재 PostgreSQL 비밀번호 인코딩 이슈로 n8n 파드가 재시작 중입니다.

**해결 방법**:
```bash
# Secret 재생성 (PowerShell에서)
kubectl delete secret n8n-secrets -n n8n
kubectl create secret generic n8n-secrets \
  --from-literal=DB_TYPE=postgresdb \
  --from-literal=DB_POSTGRESDB_HOST=postgres \
  --from-literal=DB_POSTGRESDB_PORT=5432 \
  --from-literal=DB_POSTGRESDB_DATABASE=n8n \
  --from-literal=DB_POSTGRESDB_USER=n8nuser \
  --from-literal=DB_POSTGRESDB_PASSWORD='PostgresN8n2025!' \
  -n n8n

# Deployment 재시작
kubectl rollout restart deployment/n8n -n n8n
```

### ArgoCD가 변경사항을 감지하지 못하는 경우

```bash
# 수동 새로고침
argocd app refresh n8n

# 수동 동기화
argocd app sync n8n --prune --force
```

### CI 파이프라인 실패 시

```bash
# 로컬에서 매니페스트 검증
kubectl apply --dry-run=client -f k8s/n8n/
```

---

## 📊 배포 통계

- **총 배포 시간**: ~30분
- **Terraform 리소스**: 36개
- **Kubernetes 네임스페이스**: 3개 (n8n, argocd, kube-system)
- **총 파드 수**: 10개 (ArgoCD: 7, n8n: 1, PostgreSQL: 1)
- **GitHub Actions 워크플로우**: 3개

---

## ✅ 최종 체크리스트

- [x] AKS 클러스터 배포
- [x] MySQL, CosmosDB, Redis 배포
- [x] Application Gateway 설정
- [x] Private Endpoints 구성
- [x] ArgoCD 설치 및 노출
- [x] PostgreSQL 배포 (n8n용)
- [x] GitHub Actions CI 워크플로우 작성
- [x] Terraform 워크플로우 업데이트
- [x] ArgoCD Sync 워크플로우 업데이트
- [ ] ArgoCD 비밀번호 변경
- [ ] GitHub Secrets 설정
- [ ] ArgoCD Application 리포지토리 URL 설정
- [ ] N8N 애플리케이션 배포 완료 확인
- [ ] CI/CD 파이프라인 엔드투엔드 테스트

---

## 📚 추가 문서

상세한 설정 가이드는 다음 문서를 참조하세요:
- **CI/CD 설정 가이드**: [CI-CD-SETUP-GUIDE.md](./CI-CD-SETUP-GUIDE.md)
- **아키텍처 요약**: [ARCHITECTURE-SUMMARY.md](./ARCHITECTURE-SUMMARY.md)
- **배포 가이드**: [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md)

---

**작성일**: 2025-12-20
**작성자**: Claude Code AI Assistant
**프로젝트**: Azure AKS with ArgoCD CI/CD Pipeline
