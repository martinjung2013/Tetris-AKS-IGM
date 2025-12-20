# N8N 접속 정보 📋

**버전**: 2.0
**최종 업데이트**: 2024-12-20
**상태**: ✅ 외부 접속 가능

## ✅ N8N 상태: 정상 실행 중

### 현재 확인된 정보

- **Pod 상태**: Running ✅
- **Health Check**: 응답 정상 ✅
- **데이터베이스**: PostgreSQL 연결됨 ✅
- **네임스페이스**: n8n
- **외부 접속**: Public IP 할당됨 ✅

---

## 🌍 인터넷 접속 (권장) ⭐

### Public IP를 통한 외부 접속
**External IP**: `4.217.223.153`

**접속 URL**:
```
http://4.217.223.153
```

**특징**:
- ✅ 인터넷 어디서나 접속 가능
- ✅ 안정적인 Static IP
- ✅ 프로덕션 사용 권장
- ⚠️ 보안 설정 필요 (IP 화이트리스트, TLS 등)

**자세한 정보**: [EXTERNAL-ACCESS.md](EXTERNAL-ACCESS.md)

---

## 🌐 기타 접속 방법

### 방법 1: Port Forward (로컬 개발/테스트)

**⚠️ 주의**: 포트 8080은 ArgoCD에서 사용 중입니다. 다른 포트를 사용하세요.

**권장 포트 - 5678 (n8n 기본 포트):**
```bash
kubectl port-forward -n n8n svc/n8n 5678:80
```
브라우저 접속:
```
http://localhost:5678
```

**대체 포트 - 3000:**
```bash
kubectl port-forward -n n8n svc/n8n 3000:80
```
브라우저 접속:
```
http://localhost:3000
```

**대체 포트 - 9000:**
```bash
kubectl port-forward -n n8n svc/n8n 9000:80
```
브라우저 접속:
```
http://localhost:9000
```

### 방법 2: NodePort (대체 접근)

NodePort를 통한 접근:

**NodePort**: `30678`

#### 접속 방법
```bash
# VNet 내부 또는 NSG 규칙으로 허용된 IP에서
http://<NODE-IP>:30678
```

#### 서비스 확인
```bash
kubectl get svc n8n-nodeport -n n8n
```

### 방법 3: Internal LoadBalancer (VNet 내부 전용)

VNet 내부에서만 접근 가능한 Private IP:

#### 배포
```bash
kubectl apply -f k8s/n8n/service-internal-lb.yaml
```

#### 접속
```bash
http://<INTERNAL-IP>
```

### 방법 4: Private Endpoint + Private DNS (엔터프라이즈)

Private Link를 통해 `http://n8n.n8n.internal` 도메인으로 접근:

#### 사전 요구사항
1. N8N Internal LoadBalancer 배포 완료
2. Private Link Service 자동 생성 확인

#### 배포 방법 A: Azure CLI
```bash
# k8s/n8n/private-endpoint.yaml 파일의 명령어 참조
# 단계별로 실행
```

#### 배포 방법 B: Terraform (권장)
```bash
# terraform/n8n-private-endpoint.tf 파일을 main Terraform에 통합
cd d:/IGM/aks
terraform plan
terraform apply
```

#### 접속
VNet 내부 또는 VPN/Bastion을 통해:
```
http://n8n.n8n.internal
```

---

## 🔐 로그인 정보

### Basic Authentication
- **사용자명**: `admin`
- **비밀번호**: `N8nAdmin2025!`

### 초기 설정
처음 접속 시 n8n 초기 설정 화면이 나타날 수 있습니다.
- 이메일 및 추가 사용자 정보를 입력하세요
- Basic Auth는 이미 활성화되어 있습니다

---

## 📊 서비스 정보

### Public LoadBalancer (인터넷 접근) ⭐
- **서비스명**: n8n-loadbalancer
- **타입**: LoadBalancer
- **External IP**: `4.217.223.153`
- **포트**:
  - HTTP: 80 → Pod 5678
  - HTTPS: 443 → Pod 5678
- **상태**: ✅ 정상

### ClusterIP 서비스 (내부 접근)
- **서비스명**: n8n
- **네임스페이스**: n8n
- **ClusterIP**: 10.0.8.104
- **포트**: 80 → 5678

### NodePort 서비스 (대체 접근)
- **서비스명**: n8n-nodeport
- **타입**: NodePort
- **NodePort**: 30678 (HTTP), 30679 (HTTPS)
- **ClusterIP**: 10.0.228.159

---

## 🚀 빠른 시작 가이드

### 개발/테스트 환경 (로컬 접속)

#### 1단계: Port Forward 시작
```bash
# 포트 5678 사용 (권장)
kubectl port-forward -n n8n svc/n8n 5678:80
```

**출력 예시:**
```
Forwarding from 127.0.0.1:5678 -> 5678
Forwarding from [::1]:5678 -> 5678
```

#### 2단계: 브라우저 접속
```
http://localhost:5678
```

### 프로덕션 환경 (VNet 내부 접속)

#### 1단계: Internal LoadBalancer 배포
```bash
kubectl apply -f k8s/n8n/service-internal-lb.yaml
```

#### 2단계: Internal IP 확인
```bash
kubectl get svc n8n-internal -n n8n -w
# EXTERNAL-IP가 10.224.x.x 형태의 Private IP로 할당될 때까지 대기
```

#### 3단계: Private Endpoint 구성 (선택사항, 도메인 사용)
```bash
# Terraform 사용
cd d:/IGM/aks
terraform apply -target=azurerm_private_endpoint.n8n

# 또는 Azure CLI 사용
# k8s/n8n/private-endpoint.yaml 파일 참조
```

#### 4단계: 접속
**Private IP 직접 접속:**
```bash
# VNet 내부 VM 또는 Bastion에서
http://<INTERNAL-IP>
```

**Private DNS 사용 (Private Endpoint 구성 후):**
```bash
# VNet 내부에서
http://n8n.n8n.internal
```

### 3단계: 로그인
- **사용자명**: admin
- **비밀번호**: N8nAdmin2025!

### 4단계: n8n 사용 시작
- Workflow 생성
- 노드 추가
- 실행 및 테스트

---

## 🔧 추가 명령어

### Pod 상태 확인
```bash
kubectl get pods -n n8n
```

### n8n 로그 확인
```bash
kubectl logs -n n8n deployment/n8n -f
```

### PostgreSQL 연결 확인
```bash
kubectl get pods -n n8n
kubectl logs -n n8n deployment/postgres
```

### 서비스 확인
```bash
kubectl get svc -n n8n
```

### ConfigMap 확인
```bash
kubectl get cm n8n-config -n n8n -o yaml
```

### Secret 확인
```bash
kubectl get secret n8n-secrets -n n8n -o yaml
```

---

## 📈 모니터링

### Prometheus 메트릭
n8n은 메트릭을 `/metrics` 엔드포인트에서 노출합니다:
```bash
kubectl port-forward -n n8n svc/n8n 5678:80
curl http://localhost:5678/metrics
```

### Grafana 대시보드
모니터링 스택이 배포되면 Grafana에서 n8n 대시보드를 확인할 수 있습니다:
- Workflow 실행 횟수
- 실행 시간
- 에러율
- Pod 리소스 사용량

자세한 내용은 [k8s/monitoring/README.md](k8s/monitoring/README.md)를 참조하세요.

---

## 🔐 보안 고려사항

### 현재 설정
- ✅ Basic Authentication 활성화
- ✅ Secret으로 자격증명 관리
- ✅ HTTPS 프로토콜 설정 (N8N_PROTOCOL=https)
- ⚠️ Secure Cookie 비활성화 (개발 환경)

### 프로덕션 권장 설정
1. **HTTPS 인증서 적용**
   - Let's Encrypt 사용
   - cert-manager 설치

2. **Secure Cookie 활성화**
   ```yaml
   N8N_SECURE_COOKIE: "true"
   ```

3. **강력한 비밀번호**
   - 현재: N8nAdmin2025!
   - 프로덕션에서는 더 복잡한 비밀번호 사용

4. **Network Policy 적용**
   - Pod 간 통신 제한
   - 필요한 트래픽만 허용

5. **Ingress 보안**
   - Rate Limiting
   - IP Whitelist
   - WAF (Web Application Firewall)

---

## 🌍 외부 접속 설정 (프로덕션)

현재 Port Forward는 로컬 개발/테스트용입니다. 외부에서 접속하려면:

### 옵션 1: LoadBalancer 권한 수정
자세한 내용은 [N8N-ACCESS-GUIDE.md](N8N-ACCESS-GUIDE.md)의 "방법 3" 참조

### 옵션 2: Ingress Controller 설치
자세한 내용은 [N8N-ACCESS-GUIDE.md](N8N-ACCESS-GUIDE.md)의 "방법 4" 참조 (권장)

### 옵션 3: Application Gateway 통합
Azure Application Gateway를 사용한 고급 라우팅

---

## 📁 관련 문서

- [N8N-ACCESS-GUIDE.md](N8N-ACCESS-GUIDE.md) - 상세한 접속 방법 가이드
- [MONITORING-SUMMARY.md](MONITORING-SUMMARY.md) - 모니터링 스택 정보
- [CI-CD-SETUP-GUIDE.md](CI-CD-SETUP-GUIDE.md) - CI/CD 파이프라인
- [k8s/n8n/README.md](k8s/n8n/README.md) - n8n 배포 설정

---

## 🆘 문제 해결

### Port Forward가 작동하지 않음
```bash
# Pod 상태 확인
kubectl get pods -n n8n

# Port Forward 재시작
kubectl port-forward -n n8n svc/n8n 8080:80
```

### 로그인 실패
```bash
# Secret 확인
kubectl get secret n8n-secrets -n n8n -o jsonpath='{.data.N8N_BASIC_AUTH_USER}' | base64 -d
kubectl get secret n8n-secrets -n n8n -o jsonpath='{.data.N8N_BASIC_AUTH_PASSWORD}' | base64 -d
```

### "502 Bad Gateway" 오류
```bash
# n8n Pod 재시작
kubectl rollout restart deployment/n8n -n n8n

# 로그 확인
kubectl logs -n n8n deployment/n8n
```

### 데이터베이스 연결 오류
```bash
# PostgreSQL Pod 확인
kubectl get pods -n n8n
kubectl logs -n n8n deployment/postgres

# Secret 확인
kubectl get secret n8n-secrets -n n8n -o yaml
```

---

## 📞 지원

문제가 계속되면:
1. n8n 로그 확인: `kubectl logs -n n8n deployment/n8n`
2. Pod 이벤트 확인: `kubectl describe pod -n n8n <pod-name>`
3. 서비스 상태 확인: `kubectl get all -n n8n`

---

**마지막 업데이트**: 2024-12-20
**버전**: 1.0
**상태**: ✅ 정상 실행 중
