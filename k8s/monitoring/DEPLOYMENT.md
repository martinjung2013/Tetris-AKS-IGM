# 모니터링 스택 배포 가이드

## 배포 순서

AKS 클러스터에 프로메테우스와 그라파나 모니터링 스택을 배포합니다.

### 사전 요구사항

1. **Kubectl 설정**
```bash
az aks get-credentials --resource-group <your-rg> --name <your-aks-cluster>
```

2. **Secret 값 업데이트**

[grafana-secret.yaml](grafana-secret.yaml) 파일에서 다음 값을 실제 값으로 변경:
- `admin-password`: 강력한 비밀번호
- `azure-subscription-id`: Azure 구독 ID
- `azure-tenant-id`: Azure 테넌트 ID
- `azure-client-id`: Azure 클라이언트 ID
- `azure-client-secret`: Azure 클라이언트 시크릿

### 방법 1: kubectl로 직접 배포

```bash
# 1. Namespace 생성
kubectl apply -f namespace.yaml

# 2. Prometheus 배포
kubectl apply -f prometheus-rbac.yaml
kubectl apply -f prometheus-configmap.yaml
kubectl apply -f prometheus-pvc.yaml
kubectl apply -f prometheus-deployment.yaml
kubectl apply -f prometheus-service.yaml
kubectl apply -f prometheus-ingress.yaml

# 3. Grafana 배포
kubectl apply -f grafana-secret.yaml
kubectl apply -f grafana-configmap.yaml
kubectl apply -f grafana-dashboards.yaml
kubectl apply -f grafana-pvc.yaml
kubectl apply -f grafana-deployment.yaml
kubectl apply -f grafana-service.yaml
kubectl apply -f grafana-ingress.yaml

# 4. BI Integration 및 N8N 모니터링
kubectl apply -f bi-integration-configmap.yaml
kubectl apply -f n8n-servicemonitor.yaml

# 5. 배포 상태 확인
kubectl get all -n monitoring
kubectl get pvc -n monitoring
```

### 방법 2: Kustomize로 배포 (권장)

```bash
# 모든 리소스를 한 번에 배포
kubectl apply -k .

# 또는 특정 디렉토리 지정
kubectl apply -k d:/IGM/aks/k8s/monitoring/

# 배포 상태 확인
kubectl get all -n monitoring
```

### 방법 3: ArgoCD로 배포 (GitOps, 가장 권장)

```bash
# ArgoCD Application 생성
kubectl apply -f ../../argocd/monitoring-application.yaml

# ArgoCD에서 동기화 확인
argocd app get monitoring
argocd app sync monitoring
```

## 배포 확인

### Pod 상태 확인
```bash
kubectl get pods -n monitoring
```

예상 출력:
```
NAME                          READY   STATUS    RESTARTS   AGE
prometheus-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
grafana-xxxxxxxxxx-xxxxx      1/1     Running   0          2m
```

### PVC 상태 확인
```bash
kubectl get pvc -n monitoring
```

예상 출력:
```
NAME             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS
prometheus-pvc   Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   100Gi      RWO            managed-csi-premium
grafana-pvc      Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   10Gi       RWO            managed-csi-premium
```

### Service 확인
```bash
kubectl get svc -n monitoring
```

### Ingress 확인
```bash
kubectl get ingress -n monitoring
```

## 접속 방법

### Port Forward로 로컬 접속

**Prometheus:**
```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# http://localhost:9090 접속
```

**Grafana:**
```bash
kubectl port-forward -n monitoring svc/grafana 3000:3000
# http://localhost:3000 접속
# 사용자명: admin
# 비밀번호: grafana-secret.yaml에 설정한 값
```

### Ingress를 통한 접속

DNS 설정 후:
- Prometheus: https://prometheus.igm.local
- Grafana: https://grafana.igm.local

## N8N 메트릭 확인

### Prometheus에서 N8N 메트릭 조회

1. Prometheus UI 접속
2. Graph 탭에서 쿼리 실행:

```promql
# N8N 실행 비율
rate(n8n_executions_total[5m])

# N8N 활성 워크플로우
n8n_active_workflows

# N8N 실행 시간 (95 percentile)
histogram_quantile(0.95, rate(n8n_workflow_execution_duration_seconds_bucket[5m]))

# N8N 에러율
rate(n8n_execution_errors_total[5m])

# N8N Pod CPU 사용량
rate(container_cpu_usage_seconds_total{namespace="n8n",pod=~"n8n-.*"}[5m])

# N8N Pod 메모리 사용량
container_memory_usage_bytes{namespace="n8n",pod=~"n8n-.*"}
```

### Grafana 대시보드 설정

1. Grafana 로그인
2. Dashboards → Import
3. [grafana-dashboards.yaml](grafana-dashboards.yaml)의 JSON을 임포트
4. 또는 직접 대시보드 생성

## BI 도구 연동

### Power BI

1. **Grafana API 키 생성**
```bash
# Grafana UI에서: Configuration → API Keys → New API Key
```

2. **Power BI에서 데이터 가져오기**
- Get Data → Web → Advanced
- URL 예시:
```
https://prometheus.igm.local/api/v1/query?query=rate(n8n_executions_total[5m])
```

3. **인증 설정**
- Bearer Token 또는 Basic Auth 사용

### Tableau

1. Web Data Connector 사용
2. Grafana URL 연결: `https://grafana.igm.local`
3. API Token으로 인증

### Looker

1. Prometheus 데이터 소스 직접 연결
2. Custom SQL로 메트릭 쿼리

## 문제 해결

### Prometheus가 메트릭을 수집하지 못함

```bash
# Prometheus 로그 확인
kubectl logs -n monitoring deployment/prometheus

# ServiceAccount 권한 확인
kubectl get clusterrolebinding prometheus -o yaml

# n8n 서비스 어노테이션 확인
kubectl get svc -n n8n n8n -o yaml | grep prometheus
```

### Grafana 대시보드에 데이터가 표시되지 않음

```bash
# Grafana 로그 확인
kubectl logs -n monitoring deployment/grafana

# Prometheus 연결 확인
kubectl exec -n monitoring deployment/grafana -- curl http://prometheus:9090/api/v1/query?query=up

# Grafana 데이터 소스 확인
# Grafana UI → Configuration → Data Sources → Prometheus
```

### N8N 메트릭이 보이지 않음

1. **N8N 메트릭 활성화 확인**
```bash
kubectl get cm -n n8n n8n-config -o yaml | grep N8N_METRICS
# N8N_METRICS: "true" 확인
```

2. **N8N Pod에서 직접 메트릭 확인**
```bash
kubectl exec -n n8n deployment/n8n -- curl http://localhost:5678/metrics
```

3. **Service 어노테이션 확인**
```bash
kubectl get svc -n n8n n8n -o yaml
# annotations에 prometheus.io/scrape: "true" 확인
```

### PVC가 Pending 상태

```bash
# StorageClass 확인
kubectl get storageclass

# PVC 이벤트 확인
kubectl describe pvc -n monitoring prometheus-pvc
kubectl describe pvc -n monitoring grafana-pvc

# StorageClass가 없는 경우 생성
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-csi-premium
provisioner: disk.csi.azure.com
parameters:
  skuName: Premium_LRS
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF
```

## 업그레이드

### Prometheus 업그레이드
```bash
# deployment.yaml에서 이미지 버전 변경 후
kubectl apply -f prometheus-deployment.yaml

# 또는 직접 이미지 변경
kubectl set image deployment/prometheus -n monitoring prometheus=prom/prometheus:v2.49.0
```

### Grafana 업그레이드
```bash
kubectl set image deployment/grafana -n monitoring grafana=grafana/grafana:10.3.0
```

## 정리

```bash
# 모든 모니터링 리소스 삭제
kubectl delete -k .

# 또는 개별 삭제
kubectl delete namespace monitoring
```

## 참고 사항

- Warning: namespace "monitoring"이 없다는 경고는 정상입니다. namespace.yaml을 먼저 적용하면 해결됩니다.
- PVC는 삭제해도 데이터는 보존됩니다 (reclaimPolicy: Retain인 경우)
- 프로덕션 환경에서는 RBAC 권한을 최소화하세요
- TLS 인증서는 cert-manager를 사용하여 자동 갱신하세요
