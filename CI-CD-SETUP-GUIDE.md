# CI/CD 파이프라인 설정 가이드

**버전**: 2.0
**최종 업데이트**: 2024-12-20
**상태**: ✅ 구성 완료

## 개요

이 프로젝트는 **GitHub Webhook CI**와 **ArgoCD CD**를 사용하는 완전한 CI/CD 파이프라인으로 구성되어 있습니다.

### 아키텍처

```
GitHub Push/PR → GitHub Actions (CI) → ArgoCD (CD) → AKS Cluster
```

- **CI (Continuous Integration)**: GitHub Actions가 코드 변경을 감지하고 빌드, 테스트, 검증 수행
- **CD (Continuous Deployment)**: ArgoCD가 Kubernetes 매니페스트 변경을 감지하고 자동 배포

## 배포된 인프라 정보

### AKS 클러스터
- **리소스 그룹**: `rg-liked-yak`
- **클러스터 이름**: `cluster-right-marmoset`
- **노드 수**: 3
- **리전**: Korea Central

### ArgoCD
- **URL**: http://20.249.152.142 또는 https://20.249.152.142
- **Username**: admin
- **Initial Password**: `FJca8gqCK5Lx7N1B`

⚠️ **중요**: 초기 비밀번호를 변경하세요!
```bash
argocd account update-password --server 20.249.152.142 --insecure
```

### Application Gateway
- **Public IP**: 4.230.129.183

## CI/CD 파이프라인 설정

### 1. GitHub Secrets 설정

다음 Secrets를 GitHub 리포지토리에 추가해야 합니다:

```
Settings → Secrets and variables → Actions → New repository secret
```

필수 Secrets:
- `AZURE_CREDENTIALS`: Azure 서비스 주체 자격 증명 (JSON 형식)
- `MYSQL_ADMIN_PASSWORD`: MySQL 관리자 비밀번호
- `ARGOCD_PASSWORD`: ArgoCD admin 비밀번호

#### Azure Credentials 생성 방법:

```bash
# 서비스 주체 생성
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/df0d11f5-ae3d-4abd-bd72-862d485c4ed6/resourceGroups/rg-liked-yak \
  --sdk-auth

# 출력 결과를 AZURE_CREDENTIALS에 저장
```

### 2. ArgoCD Application 설정

`argocd/n8n-application.yaml` 파일을 업데이트하여 GitHub 리포지토리 정보를 설정하세요:

```yaml
spec:
  source:
    repoURL: https://github.com/<YOUR-ORG>/<YOUR-REPO>.git
    targetRevision: main
    path: k8s/n8n
```

그 다음 ArgoCD Application을 배포:

```bash
kubectl apply -f argocd/n8n-application.yaml
```

### 3. GitHub Webhook 설정

GitHub은 기본적으로 리포지토리의 push 이벤트에 대해 GitHub Actions를 트리거합니다.

추가 웹훅 설정 (선택사항):
```
Settings → Webhooks → Add webhook
Payload URL: (필요시 외부 CI 시스템 URL)
Content type: application/json
Events: Push, Pull request
```

## Workflow 설명

### 1. CI Workflow (`.github/workflows/ci.yaml`)

**트리거**: Push, Pull Request
**목적**: 코드 품질 검증

단계:
1. **Lint and Validate**: Kubernetes 매니페스트 검증
2. **Security Scan**: Trivy를 사용한 보안 취약점 스캔
3. **Test**: 애플리케이션 테스트 (커스터마이즈 가능)
4. **Build Status**: 모든 CI 검사 통과 확인

### 2. Terraform Workflow (`.github/workflows/aks-deploy.yaml`)

**트리거**: Push to main (인프라 변경 시)
**목적**: 인프라 프로비저닝 및 ArgoCD 동기화

단계:
1. **Terraform Validate**: Terraform 코드 검증
2. **Terraform Plan**: 변경사항 미리보기 (PR)
3. **Terraform Apply**: 인프라 배포 (main 브랜치)
4. **Notify ArgoCD**: ArgoCD에 애플리케이션 동기화 요청

### 3. ArgoCD Sync Workflow (`.github/workflows/argocd-sync.yaml`)

**트리거**: k8s/ 또는 argocd/ 경로 변경 시
**목적**: ArgoCD 애플리케이션 수동 동기화

## ArgoCD 자동 동기화 설정

ArgoCD는 다음과 같이 자동으로 변경사항을 감지하고 배포합니다:

```yaml
syncPolicy:
  automated:
    prune: true        # 삭제된 리소스 자동 제거
    selfHeal: true     # 클러스터 상태가 Git과 다를 경우 자동 복구
    allowEmpty: false  # 빈 커밋 무시
```

### Git Repository 폴링 주기 변경 (선택사항)

기본값: 3분

```bash
kubectl edit configmap argocd-cm -n argocd
```

```yaml
data:
  timeout.reconciliation: 180s  # 3분 (기본값)
```

## 배포 프로세스

### 일반적인 배포 흐름:

1. **개발자가 코드 변경 후 Push**
   ```bash
   git add .
   git commit -m "Update deployment configuration"
   git push origin main
   ```

2. **GitHub Actions (CI) 자동 실행**
   - Kubernetes 매니페스트 검증
   - 보안 스캔
   - 테스트 실행

3. **CI 통과 후 ArgoCD가 변경 감지**
   - Git 리포지토리를 주기적으로 폴링 (3분마다)
   - 또는 GitHub Actions에서 명시적 sync 호출

4. **ArgoCD가 자동 배포 (CD)**
   - Kubernetes 매니페스트 적용
   - Health Check 수행
   - 배포 상태 모니터링

### 수동 동기화 (필요시):

```bash
# ArgoCD CLI 사용
argocd app sync n8n --prune --force

# 또는 UI에서
# http://20.249.152.142 접속 → n8n 앱 선택 → Sync 버튼 클릭
```

## ArgoCD UI 사용법

### 접속
1. 브라우저에서 http://20.249.152.142 접속
2. Username: `admin`
3. Password: `FJca8gqCK5Lx7N1B` (초기 비밀번호, 변경 필요)

### 주요 기능
- **Applications**: 배포된 애플리케이션 목록 및 상태
- **Sync Status**: Git과 클러스터 간 동기화 상태
- **Health Status**: 리소스 Health 상태
- **App Diff**: Git과 클러스터 간 차이점 비교
- **History**: 배포 이력 및 롤백

## 트러블슈팅

### CI 실패 시:
```bash
# GitHub Actions 로그 확인
# Settings → Actions → 실패한 워크플로우 클릭

# 로컬에서 매니페스트 검증
kubeval --strict k8s/**/*.yaml
yamllint k8s/
```

### ArgoCD 동기화 실패 시:
```bash
# ArgoCD 애플리케이션 상태 확인
argocd app get n8n

# 상세 로그 확인
kubectl logs -n argocd deployment/argocd-repo-server
kubectl logs -n argocd deployment/argocd-application-controller

# 수동 동기화 재시도
argocd app sync n8n --prune --force
```

### ArgoCD가 변경사항을 감지하지 못할 때:
```bash
# Git 리포지토리 연결 확인
argocd repo list

# 애플리케이션 새로고침
argocd app refresh n8n

# ConfigMap 확인 (폴링 주기)
kubectl get configmap argocd-cm -n argocd -o yaml
```

## 보안 권장사항

1. **ArgoCD 초기 비밀번호 즉시 변경**
2. **RBAC 설정**: ArgoCD 사용자 및 권한 관리
3. **TLS 인증서 적용**: ArgoCD 서버에 HTTPS 설정
4. **Secret 관리**: Sealed Secrets 또는 External Secrets 사용 고려
5. **Network Policies**: 네트워크 격리 정책 적용

## 다음 단계

1. ✅ ArgoCD 비밀번호 변경
2. ✅ GitHub Secrets 설정
3. ✅ `argocd/n8n-application.yaml`에 실제 리포지토리 URL 입력
4. ✅ ArgoCD Application 배포
5. ✅ 테스트 커밋 푸시하여 CI/CD 파이프라인 검증
6. 🔄 (선택) Ingress Controller 설정
7. 🔄 (선택) TLS/SSL 인증서 설정
8. ✅ 모니터링 (Prometheus/Grafana) 설정 완료

## 모니터링 스택

### Prometheus & Grafana 설정

✅ **구성 완료**: AKS 클러스터에 Prometheus와 Grafana 모니터링 스택이 구성되었습니다.

자세한 내용은 다음 문서를 참조하세요:
- [모니터링 스택 README](k8s/monitoring/README.md)
- [배포 가이드](k8s/monitoring/DEPLOYMENT.md)

주요 기능:
- **Prometheus**: 메트릭 수집 및 저장 (30일 보존)
- **Grafana**: 시각화 대시보드
- **N8N 모니터링**: 워크플로우 실행 메트릭
- **Kubernetes 모니터링**: 클러스터, Pod, Node 메트릭
- **BI 통합**: Power BI, Tableau, Looker 연동

접속 정보:
- Prometheus: https://prometheus.igm.local
- Grafana: https://grafana.igm.local

## 참고 자료

- [ArgoCD 공식 문서](https://argo-cd.readthedocs.io/)
- [GitHub Actions 문서](https://docs.github.com/en/actions)
- [Kubernetes 모범 사례](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Prometheus 문서](https://prometheus.io/docs/)
- [Grafana 문서](https://grafana.com/docs/)
