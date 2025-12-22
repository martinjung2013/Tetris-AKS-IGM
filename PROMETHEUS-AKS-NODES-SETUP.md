# Prometheus AKS 노드 정보 수집 설정

**버전**: 1.0
**최종 업데이트**: 2024-12-20
**상태**: ✅ 설정 완료

## 개요

AKS 클러스터의 노드 정보를 Prometheus가 수집하고 Grafana 테이블에 표시할 수 있도록 설정되었습니다.

---

## 🎯 수집되는 노드 정보

### 기본 노드 정보
- **노드 이름**: aks-agentpool-33847667-vmss000003/004/005
- **Kubernetes 버전**: v1.33.5
- **OS 이미지**: Ubuntu 22.04.5 LTS
- **커널 버전**: 5.15.0-1101-azure
- **컨테이너 런타임**: containerd://1.7.29-1
- **아키텍처**: amd64

### 클러스터 정보
```yaml
클러스터 이름: cluster-right-marmoset
리전: koreacentral (Korea Central)
리소스 그룹: rg-liked-yak
노드 리소스 그룹: MC_rg-liked-yak_cluster-right-marmoset_koreacentral
Kubernetes 버전: 1.33
노드 수: 3
```

### 노드 리소스 사용률
| 노드 | CPU (cores) | CPU (%) | Memory | Memory (%) |
|------|-------------|---------|--------|------------|
| vmss000003 | 192m | 10% | 1636Mi | 58% |
| vmss000004 | 204m | 10% | 2013Mi | 72% |
| vmss000005 | 232m | 12% | 2012Mi | 72% |

---

## 📊 Prometheus 설정 변경사항

### 1. Global Labels 업데이트

```yaml
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s
  external_labels:
    cluster: 'cluster-right-marmoset'      # 클러스터 이름
    environment: 'production'               # 환경
    region: 'koreacentral'                  # Azure 리전
    resource_group: 'rg-liked-yak'          # 리소스 그룹
```

### 2. kubernetes-nodes Job 개선

**추가된 레이블:**
- `node_name`: 노드 호스트명
- `internal_ip`: 노드 내부 IP 주소
- `hostname`: 노드 호스트명

```yaml
- job_name: 'kubernetes-nodes'
  kubernetes_sd_configs:
    - role: node
  relabel_configs:
    - action: labelmap
      regex: __meta_kubernetes_node_label_(.+)
    - source_labels: [__meta_kubernetes_node_name]
      target_label: node_name
    - source_labels: [__meta_kubernetes_node_address_InternalIP]
      target_label: internal_ip
    - source_labels: [__meta_kubernetes_node_address_Hostname]
      target_label: hostname
```

### 3. kubernetes-cadvisor Job 개선

**추가된 레이블:**
- `node`: 노드 이름 (리소스 메트릭용)
- `node_ip`: 노드 내부 IP

```yaml
- job_name: 'kubernetes-cadvisor'
  relabel_configs:
    - action: labelmap
      regex: __meta_kubernetes_node_label_(.+)
    - source_labels: [__meta_kubernetes_node_name]
      target_label: node
    - source_labels: [__meta_kubernetes_node_address_InternalIP]
      target_label: node_ip
```

---

## 🔍 사용 가능한 Prometheus 쿼리

### 노드 상태 확인
```promql
up{job="kubernetes-nodes"}
```

### 노드별 CPU 사용률
```promql
sum(rate(container_cpu_usage_seconds_total{job="kubernetes-cadvisor", container!=""}[5m])) by (node) * 100
```

### 노드별 메모리 사용률
```promql
sum(container_memory_working_set_bytes{job="kubernetes-cadvisor", container!=""}) by (node)
```

### 노드 정보 조회
```promql
kube_node_info
```

### 특정 노드의 레이블 조회
```promql
kube_node_labels{node="aks-agentpool-33847667-vmss000003"}
```

### CPU 코어 수
```promql
kube_node_status_capacity{resource="cpu"}
```

### 메모리 총량
```promql
kube_node_status_capacity{resource="memory"}
```

### Pod 수 확인
```promql
kube_node_status_capacity{resource="pods"}
```

---

## 📈 Grafana 대시보드

### AKS Nodes Overview 대시보드

**파일**: `k8s/monitoring/grafana-dashboard-aks-nodes.json`

**포함된 패널:**

1. **AKS Cluster Nodes Information (Table)**
   - 노드 이름
   - Hostname
   - Internal IP
   - Status (Ready/NotReady)
   - Kubelet Version
   - OS Image
   - CPU Usage (%)
   - Memory Usage (%)

2. **CPU Usage by Node (Time Series)**
   - 각 노드별 CPU 사용률 추이
   - 5분 평균 사용률

3. **Memory Usage by Node (Time Series)**
   - 각 노드별 메모리 사용량 추이
   - Working set bytes 기준

### 대시보드 Import 방법

1. **Grafana 접속**
   ```
   http://4.218.11.179:3000
   ```
   (Grafana 배포 후)

2. **Import 경로**
   - Dashboards → New → Import
   - Upload JSON file: `grafana-dashboard-aks-nodes.json`
   - Select Prometheus datasource
   - Import

3. **자동 새로고침**
   - 30초마다 자동 업데이트
   - 우측 상단에서 새로고침 간격 변경 가능

---

## 🔗 메트릭 접근 방법

### Prometheus 웹 UI

**접속 URL:**
```
http://4.218.11.179
```

**사용 방법:**
1. Graph 탭 클릭
2. 위 쿼리 중 하나를 입력
3. Execute 버튼 클릭
4. 결과 확인 (Table 또는 Graph)

### API를 통한 메트릭 조회

**현재 값 조회:**
```bash
curl -G 'http://4.218.11.179/api/v1/query' \
  --data-urlencode 'query=up{job="kubernetes-nodes"}'
```

**시간 범위 조회:**
```bash
curl -G 'http://4.218.11.179/api/v1/query_range' \
  --data-urlencode 'query=sum(rate(container_cpu_usage_seconds_total[5m])) by (node)' \
  --data-urlencode 'start=2024-12-20T00:00:00Z' \
  --data-urlencode 'end=2024-12-20T12:00:00Z' \
  --data-urlencode 'step=15s'
```

### BI 도구 연동

**Power BI:**
```
Data Source: Web
URL: http://4.218.11.179/api/v1/query
Query Parameter: query=kube_node_info
```

**Tableau:**
```
Web Data Connector
URL: http://4.218.11.179/api/v1/query?query=kube_node_info
```

---

## 📝 수집되는 주요 메트릭

### Node Metrics
- `kube_node_info`: 노드 기본 정보
- `kube_node_status_condition`: 노드 상태 (Ready, MemoryPressure, DiskPressure)
- `kube_node_status_capacity`: 노드 용량 (CPU, Memory, Pods)
- `kube_node_status_allocatable`: 할당 가능한 리소스

### Container Metrics (cAdvisor)
- `container_cpu_usage_seconds_total`: CPU 사용 시간
- `container_memory_working_set_bytes`: 메모리 사용량
- `container_network_receive_bytes_total`: 네트워크 수신량
- `container_network_transmit_bytes_total`: 네트워크 송신량
- `container_fs_usage_bytes`: 파일시스템 사용량

### Pod Metrics
- `kube_pod_info`: Pod 정보
- `kube_pod_status_phase`: Pod 상태 (Running, Pending, Failed)
- `kube_pod_container_status_running`: 실행 중인 컨테이너
- `kube_pod_container_resource_requests`: 리소스 요청량
- `kube_pod_container_resource_limits`: 리소스 제한량

---

## 🔧 문제 해결

### 노드 메트릭이 수집되지 않는 경우

1. **Prometheus Pod 확인**
   ```bash
   kubectl get pods -n monitoring
   kubectl logs -n monitoring -l app=prometheus
   ```

2. **RBAC 권한 확인**
   ```bash
   kubectl get clusterrole prometheus -o yaml
   kubectl get clusterrolebinding prometheus -o yaml
   ```

3. **ServiceAccount 확인**
   ```bash
   kubectl get sa prometheus -n monitoring
   ```

4. **Target 상태 확인**
   - Prometheus UI → Status → Targets
   - `http://4.218.11.179/targets`
   - kubernetes-nodes job 상태 확인

### cAdvisor 메트릭 누락

1. **API 서버 접근 확인**
   ```bash
   kubectl exec -n monitoring deployment/prometheus -- \
     curl -k https://kubernetes.default.svc:443/api/v1/nodes
   ```

2. **노드 프록시 경로 테스트**
   ```bash
   kubectl get --raw /api/v1/nodes/aks-agentpool-33847667-vmss000003/proxy/metrics/cadvisor | head -20
   ```

### ConfigMap 변경사항이 반영되지 않는 경우

1. **ConfigMap 확인**
   ```bash
   kubectl get cm prometheus-config -n monitoring -o yaml
   ```

2. **Prometheus 재시작**
   ```bash
   kubectl rollout restart deployment/prometheus -n monitoring
   ```

3. **설정 리로드 (재시작 없이)**
   ```bash
   kubectl exec -n monitoring deployment/prometheus -- \
     killall -HUP prometheus
   ```

---

## 📚 관련 문서

- [PROMETHEUS-ACCESS.md](PROMETHEUS-ACCESS.md) - Prometheus 외부 접속
- [MONITORING-SUMMARY.md](MONITORING-SUMMARY.md) - 모니터링 스택 요약
- [k8s/monitoring/README.md](k8s/monitoring/README.md) - 상세 배포 가이드

---

## ✅ 설정 완료 확인

다음 명령어로 설정이 올바르게 적용되었는지 확인:

```bash
# 1. Prometheus Pod 상태
kubectl get pods -n monitoring

# 2. ConfigMap 확인
kubectl get cm prometheus-config -n monitoring

# 3. 메트릭 수집 확인 (Prometheus UI)
# http://4.218.11.179/targets

# 4. 노드 메트릭 쿼리
curl -s 'http://4.218.11.179/api/v1/query?query=up{job="kubernetes-nodes"}' | grep -o '"value":\[[^]]*\]'
```

**예상 결과:**
- Prometheus Pod: Running
- Targets: 모두 UP 상태
- 쿼리 결과: value: [timestamp, "1"] (3개 노드)

---

**생성일**: 2024-12-20
**Prometheus IP**: http://4.218.11.179
**클러스터**: cluster-right-marmoset
**노드 수**: 3
**수집 간격**: 15초
