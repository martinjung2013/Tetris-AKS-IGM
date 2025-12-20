# Prometheus 외부 접속 정보

**버전**: 2.0
**최종 업데이트**: 2024-12-20
**상태**: ✅ 외부 접속 가능

## ✅ Prometheus 외부 접속 설정 완료!

Prometheus가 인터넷을 통해 외부에서 접속 가능하도록 설정되었습니다.

---

## 🌍 인터넷 접속 주소

### Public IP
**External IP**: `4.218.11.179`

### 접속 URL

**포트 80 (HTTP):**
```
http://4.218.11.179
```

**포트 9090 (Prometheus 기본 포트):**
```
http://4.218.11.179:9090
```

---

## 📊 서비스 정보

### LoadBalancer 서비스
```yaml
Name:              prometheus-loadbalancer
Namespace:         monitoring
Type:              LoadBalancer
External-IP:       4.218.11.179
Ports:
  - HTTP:       80   → Pod 9090
  - Prometheus: 9090 → Pod 9090
```

### ClusterIP 서비스 (내부용)
```yaml
Name:              prometheus
Namespace:         monitoring
Type:              ClusterIP
Port:              9090/TCP
```

---

## 🛡️ 보안 설정

### Network Security Groups (NSG)

**1. AKS Subnet NSG (`rg-liked-yak/aks-nsg`)**
- ✅ allow-prometheus: Port 9090 (Priority 130)

**2. Node Pool NSG (`mc_rg-liked-yak_cluster-right-marmoset_koreacentral/aks-agentpool-37275767-nsg`)**
- ✅ allow-prometheus: Port 9090 (Priority 1010)

### Public IP 리소스
```
Name:              prometheus-public-ip
Resource Group:    mc_rg-liked-yak_cluster-right-marmoset_koreacentral
IP Address:        4.218.11.179
Allocation:        Static
SKU:               Standard
```

---

## ✅ 접속 검증

### 1. HTTP 연결 테스트
```bash
curl http://4.218.11.179
```

**예상 응답:**
```html
<a href="/graph">Found</a>.
```

### 2. Prometheus UI 접속
```
http://4.218.11.179
```

브라우저에서 Prometheus 대시보드가 표시됩니다.

### 3. Prometheus 9090 포트 접속
```
http://4.218.11.179:9090
```

### 4. 메트릭 API 테스트
```bash
# 모든 메트릭 목록
curl http://4.218.11.179/api/v1/label/__name__/values

# 특정 메트릭 쿼리
curl 'http://4.218.11.179/api/v1/query?query=up'
```

---

## 🌐 접속 방법 비교

| 방법 | URL | 접근 범위 | 상태 | 용도 |
|------|-----|-----------|------|------|
| **Public LoadBalancer** | http://4.218.11.179 | 인터넷 전체 | ✅ 사용 가능 | 외부 접속 (프로덕션) |
| Port Forward | http://localhost:9090 | 로컬만 | ✅ 사용 가능 | 개발/테스트 |
| ClusterIP | http://prometheus.monitoring:9090 | 클러스터 내부 | ✅ 사용 가능 | 내부 서비스용 |

---

## 📊 Prometheus 사용법

### 기본 쿼리

브라우저에서 `http://4.218.11.179`로 접속 후:

1. **Graph 탭으로 이동**
2. **쿼리 입력:**

```promql
# 모든 타겟 상태 확인
up

# N8N 메트릭 확인
{job="n8n"}

# CPU 사용률
container_cpu_usage_seconds_total

# 메모리 사용률
container_memory_usage_bytes
```

### API를 통한 쿼리

```bash
# 현재 시점 쿼리
curl -G http://4.218.11.179/api/v1/query \
  --data-urlencode 'query=up'

# 범위 쿼리 (최근 1시간)
curl -G http://4.218.11.179/api/v1/query_range \
  --data-urlencode 'query=rate(container_cpu_usage_seconds_total[5m])' \
  --data-urlencode 'start=2024-12-20T05:00:00Z' \
  --data-urlencode 'end=2024-12-20T06:00:00Z' \
  --data-urlencode 'step=15s'
```

---

## 🔗 BI 도구 연동

### Power BI 연동

1. **Prometheus 데이터 소스 URL:**
   ```
   http://4.218.11.179
   ```

2. **쿼리 API 엔드포인트:**
   ```
   http://4.218.11.179/api/v1/query
   ```

3. **Power Query M 코드 예시:**
   ```m
   let
     Source = Json.Document(Web.Contents("http://4.218.11.179/api/v1/query?query=up")),
     data = Source[data],
     result = data[result]
   in
     result
   ```

### Tableau 연동

1. **Web Data Connector 사용**
2. **URL 입력:**
   ```
   http://4.218.11.179/api/v1/query
   ```

### Grafana 연동

Grafana에서 Prometheus 데이터 소스 추가:

```yaml
URL: http://4.218.11.179
Access: Browser (클라이언트에서 직접 접속)
```

자세한 내용: [MONITORING-SUMMARY.md](MONITORING-SUMMARY.md)

---

## 🔒 보안 권장사항

### 현재 상태
⚠️ **Public IP가 인터넷에 완전히 노출되어 있습니다!**

Prometheus는 기본적으로 **인증 기능이 없습니다**.

### 보안 강화 방법

#### 1. IP 화이트리스트 (권장)
특정 IP만 접근 허용:

```bash
# 회사 IP만 허용 예시
az network nsg rule update \
  --resource-group mc_rg-liked-yak_cluster-right-marmoset_koreacentral \
  --nsg-name aks-agentpool-37275767-nsg \
  --name allow-prometheus \
  --source-address-prefixes "YOUR_OFFICE_IP/32"
```

#### 2. Reverse Proxy with Authentication
NGINX 또는 Application Gateway를 통한 인증 추가:

```nginx
location / {
    auth_basic "Prometheus";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://4.218.11.179:9090;
}
```

#### 3. VPN 또는 Private Endpoint 사용
- Azure VPN Gateway를 통한 접근
- Private Link 설정 (내부 네트워크만)

#### 4. TLS/HTTPS 설정
Application Gateway 또는 Ingress Controller를 통한 TLS 인증서 적용

#### 5. Prometheus Alertmanager 설정
비정상적인 접근 패턴 감지 및 알림

---

## 🔧 문제 해결

### 연결 거부 (Connection Refused)
```bash
# 1. Service 상태 확인
kubectl get svc prometheus-loadbalancer -n monitoring

# 2. Pod 상태 확인
kubectl get pods -n monitoring

# 3. NSG 규칙 확인
az network nsg rule list \
  --resource-group mc_rg-liked-yak_cluster-right-marmoset_koreacentral \
  --nsg-name aks-agentpool-37275767-nsg \
  -o table
```

### 타임아웃 (Timeout)
```bash
# LoadBalancer 이벤트 확인
kubectl describe svc prometheus-loadbalancer -n monitoring

# Health Check 확인
kubectl logs -n monitoring deployment/prometheus --tail=50
```

### 502 Bad Gateway
```bash
# Pod 로그 확인
kubectl logs -n monitoring deployment/prometheus -f

# Pod 재시작
kubectl rollout restart deployment/prometheus -n monitoring
```

### 메트릭이 수집되지 않음
```bash
# Prometheus 설정 확인
kubectl get cm prometheus-config -n monitoring -o yaml

# Target 상태 확인 (Prometheus UI)
# http://4.218.11.179/targets
```

---

## 📝 Port Forward 방법 (대체 접근)

외부 접속이 차단된 경우:

```bash
# 포트 9090 사용
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# 브라우저 접속
# http://localhost:9090
```

---

## 📚 관련 문서

- [MONITORING-SUMMARY.md](MONITORING-SUMMARY.md) - 모니터링 스택 전체 요약
- [k8s/monitoring/README.md](k8s/monitoring/README.md) - 상세 배포 가이드
- [N8N-CONNECTION-INFO.md](N8N-CONNECTION-INFO.md) - N8N 접속 정보
- [PROJECT-README.md](PROJECT-README.md) - 프로젝트 개요

---

## 🎯 다음 단계

1. ✅ Prometheus 외부 접속 테스트: http://4.218.11.179
2. 🔄 Grafana 외부 접속 설정
3. 🔄 IP 화이트리스트 또는 인증 설정
4. 🔄 TLS/HTTPS 인증서 적용
5. 🔄 Alertmanager 설정
6. 🔄 BI 도구 연동 테스트

---

**생성일**: 2024-12-20
**Public IP**: 4.218.11.179
**상태**: ✅ 활성
**접속 URL**: http://4.218.11.179
**포트**: 80, 9090
