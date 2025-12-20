# GitHub Webhook 설정 가이드

## 개요

이 가이드는 GitHub Actions를 통한 CI/CD 파이프라인 설정을 위한 Webhook 구성 방법을 설명합니다.

## 현재 구성

- **Repository**: https://github.com/martinjung2013/Tetris-AKS-IGM
- **Branch**: webapp
- **ArgoCD Server**: 20.249.152.142
- **AKS Cluster**: cluster-right-marmoset (rg-liked-yak)

## GitHub Secrets 설정

GitHub 리포지토리에 다음 Secrets를 추가해야 합니다:

### 1. GitHub Secrets 페이지 이동

1. GitHub 리포지토리 페이지로 이동
2. `Settings` → `Secrets and variables` → `Actions` 클릭
3. `New repository secret` 클릭

### 2. 필수 Secrets

#### AZURE_CREDENTIALS
Azure 서비스 주체 인증 정보입니다.

```bash
# Azure CLI로 생성
az ad sp create-for-rbac --name "github-actions-aks" \
  --role contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-liked-yak \
  --sdk-auth
```

출력된 JSON을 그대로 Secret 값으로 추가합니다.

#### MYSQL_ADMIN_PASSWORD
```
AksDeployment@2025!SecurePass123
```

#### ARGOCD_PASSWORD
ArgoCD admin 비밀번호를 설정합니다.

```bash
# ArgoCD 초기 비밀번호 확인
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# 새 비밀번호로 변경 (권장)
# ArgoCD UI에서 User Info → Update Password
```

## GitHub Actions Workflows

현재 3개의 워크플로우가 구성되어 있습니다:

### 1. CI - Build and Test (.github/workflows/ci.yaml)

**트리거**:
- Push to main, develop, feature/* branches
- Pull requests to main, develop

**작업**:
- YAML linting (yamllint)
- Kubernetes manifest validation (kubeval)
- Security scanning (Trivy)
- 애플리케이션 테스트

### 2. Terraform Deploy (.github/workflows/aks-deploy.yaml)

**트리거**:
- Push to main branch (terraform files changed)
- Manual workflow dispatch

**작업**:
- Terraform validation
- Terraform plan
- Terraform apply
- ArgoCD 동기화 트리거

### 3. ArgoCD Sync (.github/workflows/argocd-sync.yaml)

**트리거**:
- Push to main branch (k8s/**, argocd/** changed)

**작업**:
- ArgoCD 애플리케이션 생성/업데이트
- 강제 동기화
- 상태 확인

## Webhook 동작 확인

### 자동 트리거 테스트

1. **테스트 커밋 생성**:
```bash
cd D:\IGM\aks
echo "# Test CI/CD" >> TEST.md
git add TEST.md
git commit -m "Test CI/CD pipeline"
git push origin webapp
```

2. **GitHub Actions 확인**:
   - GitHub 리포지토리 → `Actions` 탭
   - 워크플로우 실행 상태 확인

3. **ArgoCD 동기화 확인**:
```bash
kubectl get application n8n -n argocd
kubectl get pods -n n8n
```

## CI/CD 파이프라인 흐름

```
┌─────────────────┐
│  Git Push to    │
│  webapp branch  │
└────────┬────────┘
         │
         ├─────────────────┐
         │                 │
         ▼                 ▼
┌────────────────┐  ┌──────────────┐
│   CI Workflow  │  │ ArgoCD Sync  │
│                │  │  Workflow    │
│ - Lint         │  │              │
│ - Validate     │  │ - Create App │
│ - Scan         │  │ - Sync       │
│ - Test         │  │ - Wait       │
└────────────────┘  └──────┬───────┘
                           │
                           ▼
                  ┌────────────────┐
                  │   ArgoCD       │
                  │   Auto Sync    │
                  │                │
                  │ - Pull from    │
                  │   GitHub       │
                  │ - Apply to AKS │
                  └────────┬───────┘
                           │
                           ▼
                  ┌────────────────┐
                  │  AKS Cluster   │
                  │  n8n Running   │
                  └────────────────┘
```

## ArgoCD 자동 동기화

ArgoCD는 다음과 같이 설정되어 있습니다:

```yaml
syncPolicy:
  automated:
    prune: true       # 삭제된 리소스 자동 제거
    selfHeal: true    # 수동 변경 시 Git 상태로 복구
    allowEmpty: false # 빈 커밋 무시
```

**동작**:
- 3분마다 Git 리포지토리 확인
- 변경 감지 시 자동 동기화
- 실패 시 재시도 (최대 5회, exponential backoff)

## 모니터링

### GitHub Actions
- https://github.com/martinjung2013/Tetris-AKS-IGM/actions

### ArgoCD UI
- http://20.249.152.142
- Username: admin
- Password: (ARGOCD_PASSWORD secret)

### Kubernetes
```bash
# Pod 상태
kubectl get pods -n n8n

# ArgoCD Application 상태
kubectl get application -n argocd

# 최근 이벤트
kubectl get events -n n8n --sort-by='.lastTimestamp'
```

## Webhook 수동 트리거

GitHub Actions는 수동으로도 실행할 수 있습니다:

1. GitHub 리포지토리 → `Actions` 탭
2. 원하는 워크플로우 선택
3. `Run workflow` 버튼 클릭
4. Branch 선택 (webapp)
5. `Run workflow` 실행

## 트러블슈팅

### Workflow가 실행되지 않는 경우

1. **Workflow 활성화 확인**:
   - GitHub 리포지토리 → `Actions` 탭
   - "Workflows aren't being run..." 메시지 확인
   - `Enable GitHub Actions` 클릭

2. **Branch 확인**:
   - 워크플로우가 webapp 브랜치를 모니터링하는지 확인
   - `.github/workflows/*.yaml` 파일의 `branches` 설정 확인

3. **Path 필터 확인**:
   - `paths` 필터에 맞는 파일이 변경되었는지 확인

### ArgoCD 동기화 실패

1. **Application 상태 확인**:
```bash
kubectl describe application n8n -n argocd
```

2. **Repository 접근 확인**:
```bash
# ArgoCD repo-server 로그
kubectl logs -n argocd deployment/argocd-repo-server
```

3. **수동 동기화**:
```bash
# ArgoCD UI에서 SYNC 버튼 클릭
# 또는 CLI로:
kubectl rollout restart deployment argocd-repo-server -n argocd
```

### Secrets 누락 오류

GitHub Actions 실행 시 Secrets 관련 오류가 발생하면:

1. Repository Settings → Secrets and variables → Actions
2. 필요한 모든 Secrets가 추가되어 있는지 확인
3. Secret 이름이 워크플로우 YAML과 일치하는지 확인

## 다음 단계

1. ✅ GitHub Secrets 설정 완료
2. ✅ ArgoCD Application 구성 완료
3. ✅ Webhook 자동 트리거 테스트
4. 🔄 Ingress Controller 설정 (선택사항)
5. 🔄 TLS/SSL 인증서 설정 (선택사항)
6. 🔄 N8N 워크플로우 백업 자동화

## 참고 자료

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
