# AKS 모니터링 스택 배포 가이드

이 디렉토리는 Azure Kubernetes Service (AKS)에 Prometheus와 Grafana를 배포하고 BI 도구와 연동하기 위한 설정 파일들을 포함합니다.

## 구성 요소

### 1. Prometheus
- **역할**: 메트릭 수집 및 저장
- **포트**: 9090
- **저장소**: 100Gi PVC
- **보존 기간**: 30일

### 2. Grafana
- **역할**: 메트릭 시각화 및 대시보드
- **포트**: 3000
- **기본 자격증명**: admin / ChangeMe123! (변경 필요)
- **저장소**: 10Gi PVC

### 3. BI 통합
- Power BI, Tableau, Looker 등과 연동 가능
- Grafana API 및 Prometheus 쿼리 엔드포인트 제공

## 배포 순서

### 1. Secret 설정 업데이트
배포 전에 실제 값으로 업데이트해야 합니다:

```bash
# grafana-secret.yaml 편집
# - admin-password: 강력한 비밀번호로 변경
# - azure-subscription-id, azure-tenant-id, azure-client-id, azure-client-secret: 실제 Azure 자격증명으로 변경
```

### 2. Namespace 생성
```bash
kubectl apply -f namespace.yaml
```

### 3. Prometheus 배포
```bash
kubectl apply -f prometheus-rbac.yaml
kubectl apply -f prometheus-configmap.yaml
kubectl apply -f prometheus-pvc.yaml
kubectl apply -f prometheus-deployment.yaml
kubectl apply -f prometheus-service.yaml
kubectl apply -f prometheus-ingress.yaml
```

### 4. Grafana 배포
```bash
kubectl apply -f grafana-secret.yaml
kubectl apply -f grafana-configmap.yaml
kubectl apply -f grafana-dashboards.yaml
kubectl apply -f grafana-pvc.yaml
kubectl apply -f grafana-deployment.yaml
kubectl apply -f grafana-service.yaml
kubectl apply -f grafana-ingress.yaml
```

### 5. BI 통합 설정
```bash
kubectl apply -f bi-integration-configmap.yaml
```

### 6. ArgoCD를 사용한 자동 배포 (권장)
```bash
kubectl apply -f ../../argocd/monitoring-application.yaml
```

## 접속 정보

### Prometheus
- URL: https://prometheus.igm.local
- 기본 인증 필요 (prometheus-basic-auth secret 설정 필요)

### Grafana
- URL: https://grafana.igm.local
- 사용자명: admin
- 비밀번호: grafana-secrets에 설정된 값

## BI 도구 연동

### Power BI 연동
1. Grafana에서 API 키 생성:
   - Grafana UI → Configuration → API Keys → New API Key

2. Power BI에서 데이터 소스 추가:
   - Get Data → Web → Advanced
   - URL: `https://prometheus.igm.local/api/v1/query?query=YOUR_QUERY`
   - 또는 Grafana Dashboard URL 사용

3. 예제 쿼리:
   ```
   # N8N 실행 메트릭
   https://prometheus.igm.local/api/v1/query?query=rate(n8n_executions_total[5m])

   # Kubernetes Pod CPU
   https://prometheus.igm.local/api/v1/query?query=sum(rate(container_cpu_usage_seconds_total[5m]))by(pod,namespace)
   ```

### Tableau 연동
1. Grafana Web Data Connector 사용
2. Connection URL: `https://grafana.igm.local`
3. API Token으로 인증

### Looker 연동
1. Grafana Plugin 설치
2. Prometheus 데이터 소스 직접 연결 가능
3. LookML로 메트릭 모델링

## 주요 대시보드

### N8N 모니터링 대시보드
- Workflow 실행 횟수
- 실행 시간 분포
- 에러 발생률
- Pod 리소스 사용량

### Kubernetes 클러스터 대시보드
- 전체 클러스터 CPU/메모리 사용량
- Pod 상태
- 노드 상태
- 네트워크 I/O

## 데이터 내보내기

BI 도구로 데이터를 주기적으로 내보내기:

```bash
# ConfigMap의 export-config.sh 스크립트 사용
kubectl exec -n monitoring deployment/prometheus -- /bin/sh -c "export 스크립트 실행"
```

## 보안 고려사항

1. **Grafana 비밀번호 변경**: 기본 비밀번호 반드시 변경
2. **Prometheus 인증**: Ingress에 기본 인증 설정
3. **TLS 인증서**: cert-manager로 Let's Encrypt 인증서 자동 발급
4. **RBAC**: Prometheus ServiceAccount에 최소 권한 부여
5. **네트워크 정책**: 필요시 NetworkPolicy로 접근 제어

## 문제 해결

### Prometheus 메트릭 수집 안됨
```bash
# Prometheus 로그 확인
kubectl logs -n monitoring deployment/prometheus

# ServiceAccount 권한 확인
kubectl get clusterrolebinding prometheus -o yaml
```

### Grafana 대시보드 표시 안됨
```bash
# Grafana 로그 확인
kubectl logs -n monitoring deployment/grafana

# 데이터 소스 연결 확인
kubectl exec -n monitoring deployment/grafana -- curl http://prometheus:9090/api/v1/query?query=up
```

### PVC 생성 안됨
```bash
# StorageClass 확인
kubectl get storageclass

# PVC 상태 확인
kubectl get pvc -n monitoring
```

## 확장 옵션

### Alertmanager 추가
알림 기능이 필요한 경우 Alertmanager를 추가로 배포할 수 있습니다.

### 추가 Exporter
- Node Exporter: 노드 레벨 메트릭
- Blackbox Exporter: 엔드포인트 모니터링
- MySQL Exporter: 데이터베이스 메트릭

## 참고 자료

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Azure Monitor Integration](https://grafana.com/grafana/plugins/grafana-azure-monitor-datasource/)
- [Power BI REST API](https://learn.microsoft.com/en-us/power-bi/developer/embedded/rest-api-reference)
