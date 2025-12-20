# N8N 외부 접속 가이드

**버전**: 2.0
**최종 업데이트**: 2024-12-20
**상태**: ✅ 외부 접속 가능

## 현재 상태

### Pod 상태
- ✅ **N8N Pod**: Running (정상 실행 중)
- ✅ **PostgreSQL Pod**: Running (정상 실행 중)
- **Port**: 5678

### 서비스 상태
- **Public LoadBalancer**: ✅ 4.217.223.153 (인터넷 접속 가능) ⭐
- **ClusterIP Service**: 10.0.8.104 (클러스터 내부용)
- **NodePort Service**: 30678 (대체 접근용)

### ✅ 외부 접속 활성화
Public IP가 할당되어 인터넷에서 접속 가능합니다.
```
접속 URL: http://4.217.223.153
로그인: admin / N8nAdmin2025!
```

## 접속 방법

### 방법 1: Public IP 외부 접속 (권장) ⭐

**가장 쉬운 방법!** 인터넷 어디서나 바로 접속할 수 있습니다.

```
http://4.217.223.153
```

**로그인:**
- 사용자명: `admin`
- 비밀번호: `N8nAdmin2025!`

**장점:**
- ✅ 인터넷 어디서나 접속 가능
- ✅ 설정 없이 바로 사용
- ✅ 안정적인 Static IP
- ✅ 프로덕션 환경 적합

**단점:**
- ⚠️ 보안 설정 필요 (IP 화이트리스트, TLS 등)
- ⚠️ 인터넷에 완전 노출

**자세한 정보**: [EXTERNAL-ACCESS.md](EXTERNAL-ACCESS.md)

---

### 방법 2: Port Forward (로컬 개발/테스트용)

로컬 머신에서 안전하게 접속하는 방법입니다.

**⚠️ 주의**: 포트 8080은 ArgoCD에서 사용 중입니다. 다른 포트를 사용하세요.

```bash
# 포트 5678 사용 (권장)
kubectl port-forward -n n8n svc/n8n 5678:80
# 브라우저: http://localhost:5678

# 포트 3000 사용
kubectl port-forward -n n8n svc/n8n 3000:80
# 브라우저: http://localhost:3000

# 포트 9000 사용
kubectl port-forward -n n8n svc/n8n 9000:80
# 브라우저: http://localhost:9000
```

**자동 스크립트:**
```powershell
# Windows
.\scripts\start-n8n.ps1

# Linux/macOS
./scripts/start-n8n.sh
```

**장점:**
- ✅ 즉시 사용 가능
- ✅ 안전한 로컬 접속
- ✅ 방화벽 설정 불필요

**단점:**
- ❌ 로컬 머신에서만 접속 가능
- ❌ 터미널을 계속 열어두어야 함

---

### 방법 3: NodePort 서비스 (대체 접근)

클러스터의 모든 노드에서 특정 포트로 접속 가능하게 합니다.

#### 3-1. NodePort 서비스 배포

파일: `k8s/n8n/service-nodeport.yaml` (이미 생성됨)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: n8n-nodeport
  namespace: n8n
  labels:
    app: n8n
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 5678
    nodePort: 30080  # 30000-32767 범위
    protocol: TCP
    name: http
  selector:
    app: n8n
```

#### 3-2. 접속
```bash
# 노드 External IP 확인
kubectl get nodes -o wide

# 접속 URL
# http://<NODE_EXTERNAL_IP>:30080
```

---

### 방법 4: Internal LoadBalancer (VNet 내부 전용)

VNet 내부에서만 접근 가능한 Private IP를 사용합니다.

#### 4-1. Internal LoadBalancer 배포
```bash
kubectl apply -f k8s/n8n/service-internal-lb.yaml

# Private IP 확인
kubectl get svc n8n-internal -n n8n -w
```

#### 4-2. 접속 (VNet 내부 또는 Bastion)
```bash
# Private IP로 접속
http://<INTERNAL-IP>
```

**자세한 정보**: [PRIVATE-ACCESS-SETUP.md](PRIVATE-ACCESS-SETUP.md)

---

### 방법 5: Ingress Controller (도메인 기반, 선택사항)

NGINX Ingress Controller를 사용하여 도메인 기반 라우팅을 구성합니다.

#### 5-1. NGINX Ingress Controller 설치
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-resource-group"=rg-useful-cougar
```

#### 5-2. Ingress 리소스 생성
파일: `k8s/n8n/ingress-nginx.yaml`
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: n8n-ingress
  namespace: n8n
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: n8n.igm.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: n8n
            port:
              number: 80
```

#### 5-3. 배포 및 확인
```bash
kubectl apply -f k8s/n8n/ingress-nginx.yaml

# Ingress External IP 확인
kubectl get svc -n ingress-nginx
```

#### 5-4. DNS 설정 또는 hosts 파일 수정
```bash
# Windows: C:\Windows\System32\drivers\etc\hosts
# Linux/Mac: /etc/hosts
<INGRESS_EXTERNAL_IP> n8n.igm.local
```

#### 5-5. 접속
```
http://n8n.igm.local
```

---

## 추천 접속 방법

### 프로덕션 환경 (외부 사용자)
**방법 1: Public IP 접속** ⭐ (현재 활성화)
```
http://4.217.223.153
```
- ✅ 즉시 사용 가능
- ✅ 인터넷 어디서나 접속
- ⚠️ 보안 설정 강화 필요

### 개발/테스트 환경
**방법 2: Port Forward** 사용
```bash
kubectl port-forward -n n8n svc/n8n 5678:80
# http://localhost:5678
```
- ✅ 안전한 로컬 접속
- ✅ 즉시 사용 가능

### 내부 서비스 환경
**방법 4: Internal LoadBalancer** 사용
- VNet 내부만 접근
- Private Link 지원
- 엔터프라이즈 보안

### 도메인 기반 라우팅 (선택사항)
**방법 5: Ingress Controller** 사용
- 도메인 기반 라우팅
- TLS/SSL 인증서 적용 가능
- 여러 서비스 통합 관리

## 현재 즉시 테스트 가능한 방법

### 방법 1: 인터넷 접속 (가장 쉬움) ⭐
```bash
# 브라우저에서 바로 접속
# http://4.217.223.153

# 또는 curl로 테스트
curl http://4.217.223.153/healthz
```

### 방법 2: Port Forward (로컬 테스트)
```bash
# 터미널에서 Port Forward 시작
kubectl port-forward -n n8n svc/n8n 5678:80

# 브라우저에서 http://localhost:5678 접속
```

## N8N 로그인 정보

n8n이 처음 시작되면 초기 설정 화면이 나타납니다.

**ConfigMap 설정 확인:**
```bash
kubectl get cm n8n-config -n n8n -o yaml
```

**Secret 확인:**
```bash
kubectl get secret n8n-secrets -n n8n -o yaml
```

**기본 인증 정보 (secret에 설정된 값):**
- Basic Auth가 활성화되어 있습니다
- 사용자명/비밀번호는 n8n-secrets에 저장되어 있습니다

```bash
# Secret 값 확인 (base64 디코딩 필요)
kubectl get secret n8n-secrets -n n8n -o jsonpath='{.data.N8N_BASIC_AUTH_USER}' | base64 -d
kubectl get secret n8n-secrets -n n8n -o jsonpath='{.data.N8N_BASIC_AUTH_PASSWORD}' | base64 -d
```

## 문제 해결

### Port Forward 연결이 끊김
```bash
# Pod 재시작 확인
kubectl get pods -n n8n

# 새로운 Port Forward 시작
kubectl port-forward -n n8n svc/n8n 8080:80
```

### LoadBalancer PENDING 상태 지속
```bash
# 이벤트 확인
kubectl describe svc n8n-loadbalancer -n n8n

# 권한 문제 해결 (방법 3 참조)
```

### "Connection Refused" 오류
```bash
# Pod 상태 확인
kubectl get pods -n n8n
kubectl logs -n n8n deployment/n8n

# Health Check 확인
kubectl exec -n n8n deployment/n8n -- curl http://localhost:5678/healthz
```

### N8N에 접속되지만 로그인 실패
```bash
# ConfigMap 확인
kubectl get cm n8n-config -n n8n -o yaml | grep AUTH

# Secret 확인
kubectl get secret n8n-secrets -n n8n -o jsonpath='{.data}' | jq
```

## 다음 단계

1. ✅ Port Forward로 즉시 테스트
2. 🔄 LoadBalancer 권한 수정 (방법 3)
3. 🔄 Ingress Controller 설치 (방법 4)
4. 🔄 도메인 및 TLS 인증서 설정
5. 🔄 방화벽 및 보안 그룹 설정

## 참고 사항

- n8n은 현재 포트 5678에서 정상 실행 중입니다
- ClusterIP 서비스는 정상 작동합니다
- LoadBalancer는 권한 문제로 Public IP 할당 대기 중입니다
- Port Forward는 언제든지 사용 가능합니다 (가장 빠른 테스트 방법)
