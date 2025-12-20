# AKS N8N 배포 프로젝트

**버전**: 2.0
**최종 업데이트**: 2024-12-20
**상태**: ✅ 프로덕션 준비 완료

Azure Kubernetes Service (AKS)에 N8N 워크플로우 자동화 플랫폼을 배포하고 모니터링하는 Infrastructure as Code 프로젝트입니다.

## 📋 목차

- [빠른 시작](#빠른-시작)
- [프로젝트 구조](#프로젝트-구조)
- [인프라 구성](#인프라-구성)
- [배포 가이드](#배포-가이드)
- [모니터링](#모니터링)
- [문서](#문서)

## 🚀 빠른 시작

### N8N 인터넷 접속 (가장 쉬움) ⭐

**Public IP**: `4.217.223.153`

```
http://4.217.223.153
```

**로그인 정보:**
- 사용자명: `admin`
- 비밀번호: `N8nAdmin2025!`

### 로컬 개발 환경 (Port Forward)

```bash
# 방법 1: 자동 스크립트
cd d:\IGM\aks
.\scripts\start-n8n.ps1

# 방법 2: 수동 Port Forward
kubectl port-forward -n n8n svc/n8n 5678:80
# 브라우저: http://localhost:5678
```

**자세한 내용**: [QUICK-START.md](QUICK-START.md)

## 📁 프로젝트 구조

```
d:\IGM\aks\
├── *.tf                        # Terraform 인프라 코드
├── k8s/
│   ├── n8n/                   # N8N Kubernetes 매니페스트
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── service-internal-lb.yaml  # Internal LoadBalancer
│   │   ├── ingress.yaml
│   │   └── ...
│   └── monitoring/            # Prometheus & Grafana
│       ├── prometheus-*.yaml
│       ├── grafana-*.yaml
│       └── ...
├── argocd/                    # ArgoCD GitOps 설정
│   ├── n8n-application.yaml
│   └── monitoring-application.yaml
├── scripts/                   # 유틸리티 스크립트
│   ├── start-n8n.ps1          # N8N 빠른 시작 (Windows)
│   ├── start-n8n.sh           # N8N 빠른 시작 (Linux/Mac)
│   ├── configure-firewall.ps1 # 방화벽 설정 (Windows)
│   └── configure-firewall.sh  # 방화벽 설정 (Linux/Mac)
└── terraform/                 # 추가 Terraform 모듈
    └── n8n-private-endpoint.tf
```

## 🏗️ 인프라 구성

### Azure 리소스

- **AKS 클러스터**: 3-node cluster (Korea Central)
- **VNet**: 10.0.0.0/8
  - AKS Subnet: 10.224.0.0/16
  - Application Gateway Subnet: 10.1.0.0/24
  - Database Subnet: 10.2.0.0/24
  - Private Endpoints Subnet: 10.3.0.0/24
- **MySQL Flexible Server**: Master + 2 Replicas
- **CosmosDB**: MongoDB API with Private Link
- **Redis Cache**: Premium tier with AAD auth
- **Application Gateway**: L7 load balancer

### Kubernetes 애플리케이션

- **N8N**: Workflow automation platform
- **PostgreSQL**: N8N database
- **Prometheus**: Metrics collection
- **Grafana**: Visualization
- **ArgoCD**: GitOps deployment

## 📖 배포 가이드

### 1. 인프라 배포 (Terraform)

```bash
cd d:\IGM\aks

# 초기화
terraform init

# 계획 확인
terraform plan

# 배포
terraform apply
```

### 2. N8N 배포 (Kubernetes)

```bash
# Namespace 생성
kubectl apply -f k8s/n8n/namespace.yaml

# N8N 배포
kubectl apply -f k8s/n8n/
```

### 3. 모니터링 스택 배포

```bash
# Kustomize로 배포
kubectl apply -k k8s/monitoring/

# 또는 ArgoCD로 배포
kubectl apply -f argocd/monitoring-application.yaml
```

**자세한 내용**: [CI-CD-SETUP-GUIDE.md](CI-CD-SETUP-GUIDE.md)

## 📊 모니터링

### Prometheus & Grafana

모니터링 스택이 구성되어 있습니다:
- Prometheus: 메트릭 수집 (30일 보존)
- Grafana: 시각화 대시보드
- N8N 메트릭: 워크플로우 실행, 에러율
- Kubernetes 메트릭: CPU, 메모리, 네트워크

**자세한 내용**: [MONITORING-SUMMARY.md](MONITORING-SUMMARY.md)

### BI 도구 연동

Power BI, Tableau, Looker 연동 지원:
- Prometheus API를 통한 직접 쿼리
- Grafana 대시보드 임베딩
- 자동 데이터 내보내기

**자세한 내용**: [k8s/monitoring/README.md](k8s/monitoring/README.md)

## 📚 문서

### 빠른 시작
- [QUICK-START.md](QUICK-START.md) - 3단계로 N8N 시작하기

### N8N 접속
- [N8N-CONNECTION-INFO.md](N8N-CONNECTION-INFO.md) - N8N 접속 정보 및 로그인
- [N8N-ACCESS-GUIDE.md](N8N-ACCESS-GUIDE.md) - 다양한 접속 방법
- [PRIVATE-ACCESS-SETUP.md](PRIVATE-ACCESS-SETUP.md) - Private Link 설정

### 네트워크 및 보안
- [FIREWALL-SETUP.md](FIREWALL-SETUP.md) - 방화벽 및 프록시 설정

### 모니터링
- [MONITORING-SUMMARY.md](MONITORING-SUMMARY.md) - 모니터링 스택 요약
- [k8s/monitoring/README.md](k8s/monitoring/README.md) - 상세 가이드
- [k8s/monitoring/DEPLOYMENT.md](k8s/monitoring/DEPLOYMENT.md) - 배포 가이드

### CI/CD
- [CI-CD-SETUP-GUIDE.md](CI-CD-SETUP-GUIDE.md) - GitHub Actions & ArgoCD

### 변경 이력
- [CHANGELOG.md](CHANGELOG.md) - 전체 변경 이력

## 🛠️ 유틸리티 스크립트

### N8N 빠른 시작

**Windows (PowerShell):**
```powershell
.\scripts\start-n8n.ps1           # 포트 5678
.\scripts\start-n8n.ps1 -Port 3000  # 포트 3000
```

**Linux/macOS (Bash):**
```bash
./scripts/start-n8n.sh           # 포트 5678
./scripts/start-n8n.sh 3000      # 포트 3000
```

### 방화벽 설정

**Windows (관리자 권한 필요):**
```powershell
.\scripts\configure-firewall.ps1
```

**Linux/macOS (sudo 필요):**
```bash
sudo ./scripts/configure-firewall.sh
```

## 🔐 보안

### 자격증명 관리

모든 민감한 정보는 Kubernetes Secret으로 관리:
- N8N 인증 정보
- 데이터베이스 비밀번호
- Azure 연동 자격증명

### 네트워크 보안

- Internal LoadBalancer (VNet 내부만 접근)
- Private Endpoint (Private Link)
- Network Security Groups
- Application Gateway WAF (선택사항)

## 🌐 접속 방법 요약

| 방법 | URL | 접근 범위 | 상태 | 용도 |
|------|-----|-----------|------|------|
| **Public LoadBalancer** ⭐ | http://4.217.223.153 | **인터넷 전체** | ✅ **활성** | **프로덕션 (권장)** |
| Port Forward | http://localhost:5678 | 로컬만 | ✅ 사용 가능 | 개발/테스트 |
| NodePort | http://NODE-IP:30678 | VNet/인터넷 | ✅ 사용 가능 | 대체 접근 |
| Internal LB | http://10.224.x.x | VNet 내부 | 미배포 | 내부 서비스 |
| Private Endpoint | http://n8n.n8n.internal | VNet 내부 | 미배포 | 엔터프라이즈 |

## 📞 지원

### 문제 해결

일반적인 문제는 각 가이드의 "문제 해결" 섹션을 참조하세요:
- [QUICK-START.md](QUICK-START.md#문제-해결)
- [FIREWALL-SETUP.md](FIREWALL-SETUP.md#문제-해결)
- [N8N-ACCESS-GUIDE.md](N8N-ACCESS-GUIDE.md#문제-해결)

### 로그 확인

```bash
# N8N 로그
kubectl logs -n n8n deployment/n8n -f

# PostgreSQL 로그
kubectl logs -n n8n deployment/postgres

# Prometheus 로그
kubectl logs -n monitoring deployment/prometheus

# Grafana 로그
kubectl logs -n monitoring deployment/grafana
```

## 🎯 다음 단계

1. ✅ N8N 접속 테스트 - 완료
2. ✅ 모니터링 스택 배포 - 완료
3. ✅ Public IP 외부 접속 - 완료
4. ✅ NSG 방화벽 설정 - 완료
5. 🔄 TLS/HTTPS 인증서 적용
6. 🔄 IP 화이트리스트 보안 설정
7. 🔄 도메인 이름 연결
8. 🔄 BI 도구 연동
9. 🔄 Private Endpoint 설정 (선택사항)

## 📄 라이선스

이 프로젝트는 내부 사용을 위한 것입니다.

---

**마지막 업데이트**: 2024-12-20
**버전**: 1.0
**담당자**: IGM AKS Team
