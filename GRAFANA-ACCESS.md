# Grafana 외부 접속 정보

**버전**: 1.0
**최종 업데이트**: 2024-12-22
**상태**: ✅ 외부 접속 가능

## ✅ Grafana 외부 접속 설정 완료!

Grafana가 인터넷을 통해 외부에서 접속 가능하도록 설정되었습니다.

---

## 🌍 인터넷 접속 주소

### Public IP
**External IP**: `20.196.95.210`

### 접속 URL

**포트 80 (HTTP):**
```
http://20.196.95.210
```

**포트 3000 (Grafana 기본 포트):**
```
http://20.196.95.210:3000
```

### 로그인 정보

```
Username: admin
Password: ChangeMe123!
```

⚠️ **보안 주의**: 프로덕션 환경에서는 반드시 기본 비밀번호를 변경하세요!

---

## 📊 서비스 정보

### LoadBalancer 서비스
```yaml
Name:              grafana-loadbalancer
Namespace:         monitoring
Type:              LoadBalancer
External-IP:       20.196.95.210
Ports:
  - HTTP:       80   → Pod 3000
  - Grafana:    3000 → Pod 3000
```

### ClusterIP 서비스 (내부용)
```yaml
Name:              grafana
Namespace:         monitoring
Type:              ClusterIP
Port:              3000/TCP
```

---

## 🛡️ 보안 설정

### Network Security Groups (NSG)

**Node Pool NSG (`mc_rg-liked-yak_cluster-right-marmoset_koreacentral/aks-agentpool-37275767-nsg`)**
- ✅ allow-grafana: Port 3000 (Priority 1020)
- 소스 IP 제한: 125.128.9.105/32

### Public IP 리소스
```
Name:              grafana-public-ip
Resource Group:    mc_rg-liked-yak_cluster-right-marmoset_koreacentral
IP Address:        20.196.95.210
Allocation:        Static
SKU:               Standard
```

---

## ✅ 접속 검증

### 1. HTTP 연결 테스트
```bash
curl -I http://20.196.95.210
```

**예상 응답:**
```
HTTP/1.1 302 Found
Location: /login
```

### 2. Grafana UI 접속
```
http://20.196.95.210
```

브라우저에서 Grafana 로그인 페이지가 표시됩니다.

### 3. Grafana 3000 포트 접속
```
http://20.196.95.210:3000
```

---

## 🌐 접속 방법 비교

| 방법 | URL | 접근 범위 | 상태 | 용도 |
|------|-----|-----------|------|------|
| **Public LoadBalancer** | http://20.196.95.210 | 화이트리스트 IP | ✅ 사용 가능 | 외부 접속 (프로덕션) |
| Port Forward | http://localhost:3000 | 로컬만 | ✅ 사용 가능 | 개발/테스트 |
| ClusterIP | http://grafana.monitoring:3000 | 클러스터 내부 | ✅ 사용 가능 | 내부 서비스용 |

---

## 📈 AKS Nodes Overview 대시보드

### 대시보드 정보

**이름**: AKS Nodes Overview
**UID**: aks-nodes-overview
**접속 URL**: http://20.196.95.210/d/aks-nodes-overview/aks-nodes-overview

### 대시보드 패널

#### 1. AKS Cluster Nodes Information (Table)
노드의 전체 정보를 테이블 형태로 표시합니다.

**표시 항목:**
- Node Name (노드 이름)
- Hostname (호스트명)
- Internal IP (내부 IP)
- Status (상태: Ready/NotReady)
- Kubelet Version (Kubelet 버전)
- OS Image (OS 이미지)
- CPU Usage (%) - 색상 표시 (녹색/노란색/빨간색)
- Memory Usage (%) - 색상 표시 (녹색/노란색/빨간색)

**임계값:**
- CPU Usage:
  - 녹색: 0-60%
  - 노란색: 60-80%
  - 빨간색: 80% 이상
- Memory Usage:
  - 녹색: 0-70%
  - 노란색: 70-85%
  - 빨간색: 85% 이상

#### 2. CPU Usage by Node (Time Series)
각 노드별 CPU 사용률 추이를 그래프로 표시합니다.

**쿼리:**
```promql
sum(rate(container_cpu_usage_seconds_total{job="kubernetes-cadvisor", container!=""}[5m])) by (node) * 100
```

#### 3. Memory Usage by Node (Time Series)
각 노드별 메모리 사용량 추이를 그래프로 표시합니다.

**쿼리:**
```promql
sum(container_memory_working_set_bytes{job="kubernetes-cadvisor", container!=""}) by (node)
```

### 자동 새로고침
- 30초마다 자동 업데이트
- 우측 상단에서 새로고침 간격 변경 가능

---

## 🔗 Prometheus 데이터 소스

### Datasource 설정

Grafana는 자동으로 Prometheus 데이터 소스가 구성되어 있습니다.

```yaml
Name: Prometheus
Type: prometheus
URL: http://prometheus:9090
Access: Server (default)
```

### Prometheus 직접 접속
```
http://4.218.11.179
```

---

## 🔧 Grafana 사용법

### 대시보드 탐색

1. **메인 화면 접속**
   - URL: http://20.196.95.210
   - Username: admin
   - Password: ChangeMe123!

2. **AKS Nodes 대시보드 접속**
   - 좌측 메뉴 → Dashboards → Browse
   - "AKS Nodes Overview" 클릭
   - 또는 직접 URL: http://20.196.95.210/d/aks-nodes-overview/aks-nodes-overview

3. **시간 범위 설정**
   - 우측 상단 시간 선택기
   - 기본값: 최근 1시간
   - 변경 가능: 5분, 15분, 1시간, 6시간, 12시간, 24시간, 7일 등

### 쿼리 편집

1. 패널 클릭 → Edit
2. Query 탭에서 Prometheus 쿼리 수정 가능
3. Panel options에서 표시 형식 변경 가능

### 새 대시보드 생성

1. 좌측 메뉴 → Dashboards → New → New Dashboard
2. Add visualization 클릭
3. Prometheus 데이터 소스 선택
4. 쿼리 입력 및 패널 설정
5. Save dashboard

---

## 🔒 보안 권장사항

### 현재 상태
⚠️ **Public IP가 특정 IP(125.128.9.105)에만 접근 허용되어 있습니다**

### 추가 보안 강화 방법

#### 1. 비밀번호 변경 (권장)
Grafana UI에서 비밀번호 변경:
```
Profile → Change Password
```

또는 Secret 업데이트:
```bash
kubectl edit secret grafana-secrets -n monitoring
```

#### 2. TLS/HTTPS 설정
Application Gateway 또는 Ingress Controller를 통한 TLS 인증서 적용

#### 3. OAuth 인증 설정
Azure AD, Google, GitHub 등의 OAuth 제공자 연동

#### 4. 사용자 역할 관리
- Admin: 전체 권한
- Editor: 대시보드 편집 가능
- Viewer: 읽기 전용

#### 5. API Key 관리
BI 도구 연동을 위한 서비스 계정 API 키 생성

---

## 🔧 문제 해결

### 연결 거부 (Connection Refused)
```bash
# 1. Service 상태 확인
kubectl get svc grafana-loadbalancer -n monitoring

# 2. Pod 상태 확인
kubectl get pods -n monitoring -l app=grafana

# 3. NSG 규칙 확인
az network nsg rule list \
  --resource-group mc_rg-liked-yak_cluster-right-marmoset_koreacentral \
  --nsg-name aks-agentpool-37275767-nsg \
  -o table
```

### 로그인 실패
```bash
# Secret 확인
kubectl get secret grafana-secrets -n monitoring -o yaml

# 비밀번호 재설정 (필요시)
kubectl edit secret grafana-secrets -n monitoring
kubectl rollout restart deployment/grafana -n monitoring
```

### 대시보드가 표시되지 않음
```bash
# Pod 로그 확인
kubectl logs -n monitoring -l app=grafana --tail=100

# 대시보드 API 확인
curl -u "admin:ChangeMe123!" http://20.196.95.210/api/dashboards/uid/aks-nodes-overview
```

### Prometheus 데이터 소스 연결 실패
```bash
# Prometheus 서비스 확인
kubectl get svc -n monitoring prometheus

# 네트워크 테스트 (Grafana Pod에서)
kubectl exec -n monitoring -l app=grafana -- curl -s http://prometheus:9090/api/v1/query?query=up
```

### 메트릭이 표시되지 않음
```bash
# Prometheus에서 직접 쿼리 테스트
curl -G 'http://4.218.11.179/api/v1/query' \
  --data-urlencode 'query=up{job="kubernetes-nodes"}'

# kube-state-metrics 확인
kubectl get pods -n monitoring -l app=kube-state-metrics
```

---

## 📝 Port Forward 방법 (대체 접근)

외부 접속이 차단된 경우:

```bash
# 포트 3000 사용
kubectl port-forward -n monitoring svc/grafana 3000:3000

# 브라우저 접속
# http://localhost:3000
```

---

## 📚 관련 문서

- [PROMETHEUS-ACCESS.md](PROMETHEUS-ACCESS.md) - Prometheus 외부 접속
- [PROMETHEUS-AKS-NODES-SETUP.md](PROMETHEUS-AKS-NODES-SETUP.md) - AKS 노드 메트릭 설정
- [MONITORING-SUMMARY.md](MONITORING-SUMMARY.md) - 모니터링 스택 전체 요약
- [k8s/monitoring/README.md](k8s/monitoring/README.md) - 상세 배포 가이드

---

## 🎯 다음 단계

1. ✅ Grafana 외부 접속 테스트: http://20.196.95.210
2. ✅ AKS Nodes Overview 대시보드 확인
3. 🔄 기본 비밀번호 변경
4. 🔄 추가 대시보드 생성 (N8N, ArgoCD 등)
5. 🔄 알림 규칙 설정 (Alerting)
6. 🔄 TLS/HTTPS 인증서 적용
7. 🔄 BI 도구 연동 (Power BI, Tableau 등)

---

## 🔍 유용한 Prometheus 쿼리 (Grafana에서 사용)

### 노드 상태
```promql
up{job="kubernetes-nodes"}
```

### 노드별 CPU 사용률
```promql
sum(rate(container_cpu_usage_seconds_total{job="kubernetes-cadvisor", container!=""}[5m])) by (node) * 100
```

### 노드별 메모리 사용률
```promql
(1 - sum(node_memory_MemAvailable_bytes) by (node) / sum(node_memory_MemTotal_bytes) by (node)) * 100
```

### 노드 정보
```promql
kube_node_info
```

### Pod 수
```promql
count(kube_pod_info) by (node)
```

### 노드별 디스크 사용률
```promql
(1 - sum(node_filesystem_avail_bytes{fstype=~"ext4|xfs"}) by (node) / sum(node_filesystem_size_bytes{fstype=~"ext4|xfs"}) by (node)) * 100
```

### 노드별 네트워크 수신량
```promql
sum(rate(container_network_receive_bytes_total[5m])) by (node)
```

### 노드별 네트워크 송신량
```promql
sum(rate(container_network_transmit_bytes_total[5m])) by (node)
```

---

**생성일**: 2024-12-22
**Public IP**: 20.196.95.210
**상태**: ✅ 활성
**접속 URL**: http://20.196.95.210
**포트**: 80, 3000
**대시보드 URL**: http://20.196.95.210/d/aks-nodes-overview/aks-nodes-overview
