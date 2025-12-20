# N8N 외부 접속 정보 🌐

## ✅ 외부 접속 설정 완료!

N8N이 인터넷을 통해 외부에서 접속 가능하도록 설정되었습니다.

---

## 🌍 인터넷 접속 주소

### Public IP
**External IP**: `4.217.223.153`

### 접속 URL
```
http://4.217.223.153
```

---

## 🔐 로그인 정보

- **사용자명**: `admin`
- **비밀번호**: `N8nAdmin2025!`

---

## 📊 서비스 정보

### LoadBalancer 서비스
```yaml
Name:              n8n-loadbalancer
Namespace:         n8n
Type:              LoadBalancer
External-IP:       4.217.223.153
Ports:
  - HTTP:  80  → Pod 5678
  - HTTPS: 443 → Pod 5678
```

### NodePort 서비스 (대체 접근)
```yaml
Name:              n8n-nodeport
Namespace:         n8n
Type:              NodePort
NodePort:          30678
```

---

## 🛡️ 보안 설정

### Network Security Groups (NSG)

**1. AKS Subnet NSG (`rg-liked-yak/aks-nsg`)**
- ✅ allow-http: Port 80 (Priority 110)
- ✅ allow-https: Port 443 (Priority 100)
- ✅ allow-n8n-nodeport: Port 30678 (Priority 120)

**2. Node Pool NSG (`mc_rg-liked-yak_cluster-right-marmoset_koreacentral/aks-agentpool-37275767-nsg`)**
- ✅ allow-n8n-nodeport: Port 30678 (Priority 1000)

### Public IP 리소스
```
Name:              n8n-public-ip
Resource Group:    mc_rg-liked-yak_cluster-right-marmoset_koreacentral
IP Address:        4.217.223.153
Allocation:        Static
SKU:               Standard
```

---

## ✅ 접속 검증

### 1. HTTP 연결 테스트
```bash
curl -I http://4.217.223.153
```

**예상 응답:**
```
HTTP/1.1 307 Temporary Redirect
Location: https://n8n.local/
```

### 2. Health Check 테스트
```bash
curl http://4.217.223.153/healthz
```

**예상 응답:**
```json
{"status":"ok"}
```

### 3. 브라우저 접속
```
http://4.217.223.153
```

---

## 🌐 다양한 접속 방법 비교

| 방법 | URL | 접근 범위 | 상태 | 용도 |
|------|-----|-----------|------|------|
| **Public LoadBalancer** | http://4.217.223.153 | 인터넷 전체 | ✅ 사용 가능 | 외부 접속 (프로덕션) |
| Port Forward | http://localhost:5678 | 로컬만 | ✅ 사용 가능 | 개발/테스트 |
| NodePort | http://<NODE-IP>:30678 | VNet 또는 인터넷 | ✅ 사용 가능 | 대체 접근 |
| Internal LB | http://10.224.x.x | VNet 내부 | 미배포 | 내부 서비스용 |
| Private Endpoint | http://n8n.n8n.internal | VNet 내부 | 미배포 | 프라이빗 접속용 |

---

## 🔒 보안 권장사항

### 현재 상태
⚠️ **Public IP가 인터넷에 완전히 노출되어 있습니다!**

### 보안 강화 방법

#### 1. IP 화이트리스트 (권장)
특정 IP만 접근 허용:

```bash
# 회사 IP만 허용 예시
az network nsg rule update \
  --resource-group mc_rg-liked-yak_cluster-right-marmoset_koreacentral \
  --nsg-name aks-agentpool-37275767-nsg \
  --name allow-n8n-nodeport \
  --source-address-prefixes "YOUR_OFFICE_IP/32"
```

#### 2. Azure Firewall 사용
- Application Gateway WAF 설정
- Azure Front Door 설정

#### 3. TLS/HTTPS 설정
Let's Encrypt 인증서 적용:

```bash
# cert-manager 설치
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# ClusterIssuer 생성
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: azure-application-gateway
EOF
```

#### 4. Basic Auth 강화
더 강력한 비밀번호로 변경:

```bash
# Secret 업데이트
kubectl create secret generic n8n-secrets \
  --from-literal=N8N_BASIC_AUTH_USER=admin \
  --from-literal=N8N_BASIC_AUTH_PASSWORD='YOUR_STRONG_PASSWORD' \
  --dry-run=client -o yaml | kubectl apply -f - -n n8n

# N8N Pod 재시작
kubectl rollout restart deployment/n8n -n n8n
```

#### 5. Rate Limiting
Application Gateway에서 설정:
- 분당 요청 수 제한
- DDoS 방어 활성화

---

## 📝 DNS 설정 (선택사항)

### 1. Azure DNS Zone 생성
```bash
az network dns zone create \
  --resource-group rg-liked-yak \
  --name yourdomain.com
```

### 2. A 레코드 추가
```bash
az network dns record-set a add-record \
  --resource-group rg-liked-yak \
  --zone-name yourdomain.com \
  --record-set-name n8n \
  --ipv4-address 4.217.223.153
```

### 3. 도메인 접속
```
http://n8n.yourdomain.com
```

---

## 🔧 문제 해결

### 연결 거부 (Connection Refused)
```bash
# 1. Service 상태 확인
kubectl get svc n8n-loadbalancer -n n8n

# 2. Pod 상태 확인
kubectl get pods -n n8n

# 3. NSG 규칙 확인
az network nsg rule list \
  --resource-group mc_rg-liked-yak_cluster-right-marmoset_koreacentral \
  --nsg-name aks-agentpool-37275767-nsg \
  -o table
```

### 타임아웃 (Timeout)
```bash
# LoadBalancer 이벤트 확인
kubectl describe svc n8n-loadbalancer -n n8n

# Health Check 확인
kubectl logs -n n8n deployment/n8n --tail=50
```

### 502 Bad Gateway
```bash
# Pod 로그 확인
kubectl logs -n n8n deployment/n8n -f

# Pod 재시작
kubectl rollout restart deployment/n8n -n n8n
```

---

## 📊 모니터링

### Prometheus 메트릭
N8N 메트릭은 `http://4.217.223.153/metrics`에서 확인 가능합니다.

### Grafana 대시보드
모니터링 스택 배포 후 Grafana에서 실시간 모니터링이 가능합니다.

자세한 내용: [MONITORING-SUMMARY.md](MONITORING-SUMMARY.md)

---

## 🎯 다음 단계

1. ✅ 외부 접속 테스트: http://4.217.223.153
2. 🔄 TLS/HTTPS 인증서 적용
3. 🔄 IP 화이트리스트 설정
4. 🔄 도메인 이름 설정
5. 🔄 WAF (Web Application Firewall) 설정
6. 🔄 모니터링 및 알림 설정

---

## 📚 관련 문서

- [N8N-CONNECTION-INFO.md](N8N-CONNECTION-INFO.md) - 전체 접속 방법
- [N8N-ACCESS-GUIDE.md](N8N-ACCESS-GUIDE.md) - 상세 가이드
- [FIREWALL-SETUP.md](FIREWALL-SETUP.md) - 방화벽 설정
- [PRIVATE-ACCESS-SETUP.md](PRIVATE-ACCESS-SETUP.md) - Private Access

---

**생성일**: 2024-12-20
**Public IP**: 4.217.223.153
**상태**: ✅ 활성
**접속 URL**: http://4.217.223.153
