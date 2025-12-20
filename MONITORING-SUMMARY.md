# 모니터링 스택 구성 요약

**버전**: 2.0
**최종 업데이트**: 2024-12-20
**상태**: ✅ 구성 완료

## 개요

AKS 클러스터에 Prometheus와 Grafana 기반의 완전한 모니터링 스택을 구성하였으며, Power BI, Tableau, Looker 등의 BI 도구와 연동할 수 있도록 설정되었습니다.

## 구성 요소

### 1. Prometheus (메트릭 수집)
- **버전**: v2.48.0
- **네임스페이스**: monitoring
- **스토리지**: 100Gi (Premium SSD)
- **보존 기간**: 30일
- **접속**: https://prometheus.igm.local

#### 수집 메트릭
- Kubernetes API 서버
- Kubernetes 노드
- Kubernetes Pods
- cAdvisor (컨테이너 메트릭)
- N8N 애플리케이션
- Kubernetes Services

### 2. Grafana (시각화)
- **버전**: 10.2.2
- **네임스페이스**: monitoring
- **스토리지**: 10Gi (Premium SSD)
- **접속**: https://grafana.igm.local

#### 설치된 플러그인
- grafana-azure-monitor-datasource
- grafana-clock-panel
- grafana-simple-json-datasource
- grafana-piechart-panel

#### 데이터 소스
- Prometheus (기본)
- Azure Monitor

### 3. N8N 모니터링
- **메트릭 엔드포인트**: /metrics (포트 5678)
- **수집 방법**: Prometheus annotation 기반 자동 스크랩
- **ServiceMonitor**: 있음

#### N8N 메트릭 설정
```yaml
N8N_METRICS: "true"
N8N_METRICS_PREFIX: "n8n_"
N8N_DIAGNOSTICS_ENABLED: "true"
```

#### 주요 N8N 메트릭
- `n8n_executions_total`: 총 실행 횟수
- `n8n_active_workflows`: 활성 워크플로우 수
- `n8n_workflow_execution_duration_seconds`: 실행 시간
- `n8n_execution_errors_total`: 에러 발생 횟수

### 4. BI 도구 연동

#### Power BI
- **연동 방법**: REST API를 통한 직접 쿼리
- **엔드포인트**: https://prometheus.igm.local/api/v1/query
- **인증**: Bearer Token 또는 Basic Auth
- **새로고침 주기**: 설정 가능 (기본 1시간)

#### Tableau
- **연동 방법**: Web Data Connector
- **데이터 소스**: Grafana Dashboard
- **지원 형식**: JSON

#### Looker
- **연동 방법**: Grafana Plugin
- **직접 연결**: Prometheus API 지원

## 배포 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                        AKS Cluster                           │
│                                                              │
│  ┌────────────────┐         ┌──────────────────┐           │
│  │   N8N Pod      │◄────────│   Prometheus     │           │
│  │   :5678/metrics│ scrape  │   :9090          │           │
│  └────────────────┘         └──────────────────┘           │
│                                      ▲                       │
│  ┌────────────────┐                  │                      │
│  │ Kubernetes     │──────────────────┘                      │
│  │ Components     │ metrics                                 │
│  └────────────────┘                  │                      │
│                                      ▼                       │
│                             ┌──────────────────┐            │
│                             │    Grafana       │            │
│                             │    :3000         │            │
│                             └──────────────────┘            │
│                                      │                       │
└──────────────────────────────────────┼───────────────────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    │                  │                  │
                    ▼                  ▼                  ▼
            ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
            │  Power BI    │  │   Tableau    │  │   Looker     │
            │              │  │              │  │              │
            └──────────────┘  └──────────────┘  └──────────────┘
```

## 주요 대시보드

### N8N Monitoring Dashboard
- Workflow Executions (실행 횟수)
- Active Workflows (활성 워크플로우)
- Execution Duration (실행 시간)
- Error Rate (에러율)
- Pod CPU Usage (CPU 사용량)
- Pod Memory Usage (메모리 사용량)

### Kubernetes Cluster Overview
- Cluster CPU Usage (클러스터 CPU)
- Cluster Memory Usage (클러스터 메모리)
- Pod Status (Pod 상태)
- Node Status (노드 상태)
- Persistent Volume Usage (볼륨 사용량)
- Network I/O (네트워크)

## 배포 방법

### 방법 1: Kustomize (권장)
```bash
kubectl apply -k k8s/monitoring/
```

### 방법 2: ArgoCD (GitOps)
```bash
kubectl apply -f argocd/monitoring-application.yaml
```

### 방법 3: kubectl (개별 배포)
```bash
kubectl apply -f k8s/monitoring/namespace.yaml
kubectl apply -f k8s/monitoring/prometheus-rbac.yaml
kubectl apply -f k8s/monitoring/prometheus-configmap.yaml
# ... (전체 파일 목록은 DEPLOYMENT.md 참조)
```

## 사전 요구사항

1. **grafana-secret.yaml 업데이트**
   - admin-password: 강력한 비밀번호로 변경
   - azure-subscription-id: 실제 Azure 구독 ID
   - azure-tenant-id: Azure 테넌트 ID
   - azure-client-id: Azure 클라이언트 ID
   - azure-client-secret: Azure 클라이언트 시크릿

2. **DNS 설정**
   - prometheus.igm.local → Application Gateway IP
   - grafana.igm.local → Application Gateway IP

3. **TLS 인증서 (선택사항)**
   - cert-manager 설치
   - Let's Encrypt 설정

## 주요 프로메테우스 쿼리

### N8N 메트릭
```promql
# 초당 실행 비율
rate(n8n_executions_total[5m])

# 95 percentile 실행 시간
histogram_quantile(0.95, rate(n8n_workflow_execution_duration_seconds_bucket[5m]))

# 에러율
rate(n8n_execution_errors_total[5m])
```

### Kubernetes 메트릭
```promql
# Pod CPU 사용량
rate(container_cpu_usage_seconds_total{namespace="n8n"}[5m])

# Pod 메모리 사용량
container_memory_usage_bytes{namespace="n8n"}

# Pod 상태
kube_pod_status_phase{namespace="n8n"}
```

## 접속 정보

### Port Forward (로컬 테스트용)
```bash
# Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# http://localhost:9090

# Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000
# http://localhost:3000
```

### Ingress (프로덕션)
- Prometheus: https://prometheus.igm.local
- Grafana: https://grafana.igm.local

## BI 도구 연동 예제

### Power BI - Prometheus 쿼리
```
GET https://prometheus.igm.local/api/v1/query?query=rate(n8n_executions_total[5m])
```

### Power BI - Grafana Dashboard
1. Grafana에서 API 키 생성
2. Power BI → Get Data → Web
3. URL: Grafana Dashboard 공개 URL
4. Authorization: Bearer {API_KEY}

### Tableau - Web Data Connector
1. Tableau → Connect to Data → Web Data Connector
2. URL: https://grafana.igm.local
3. API Token 입력

## 문제 해결

### Prometheus가 N8N 메트릭을 수집하지 못함
```bash
# 1. N8N 메트릭 엔드포인트 확인
kubectl exec -n n8n deployment/n8n -- curl http://localhost:5678/metrics

# 2. Service 어노테이션 확인
kubectl get svc -n n8n n8n -o yaml | grep prometheus

# 3. Prometheus 타겟 확인
# http://prometheus.igm.local/targets
```

### Grafana 대시보드에 데이터 없음
```bash
# 1. Prometheus 연결 확인
kubectl exec -n monitoring deployment/grafana -- curl http://prometheus:9090/api/v1/query?query=up

# 2. Grafana 로그 확인
kubectl logs -n monitoring deployment/grafana

# 3. 데이터 소스 재설정
# Grafana UI → Configuration → Data Sources → Prometheus → Test
```

## 파일 구조

```
d:/IGM/aks/
├── k8s/
│   ├── monitoring/
│   │   ├── namespace.yaml
│   │   ├── prometheus-*.yaml (7개 파일)
│   │   ├── grafana-*.yaml (6개 파일)
│   │   ├── bi-integration-configmap.yaml
│   │   ├── n8n-servicemonitor.yaml
│   │   ├── kustomization.yaml
│   │   ├── README.md
│   │   └── DEPLOYMENT.md
│   └── n8n/
│       ├── configmap.yaml (업데이트됨)
│       └── service.yaml (업데이트됨)
├── argocd/
│   ├── n8n-application.yaml
│   └── monitoring-application.yaml (신규)
├── CI-CD-SETUP-GUIDE.md (업데이트됨)
├── CHANGELOG.md (신규)
└── MONITORING-SUMMARY.md (이 문서)
```

## 보안 고려사항

1. ✅ Grafana 비밀번호는 Kubernetes Secret에 저장
2. ✅ Prometheus RBAC 최소 권한 설정
3. ⚠️ Prometheus Ingress에 Basic Auth 추가 권장
4. ⚠️ TLS/SSL 인증서 설정 권장
5. ⚠️ Network Policy로 접근 제한 권장

## 다음 단계

1. [ ] grafana-secret.yaml 실제 값으로 업데이트
2. [ ] 모니터링 스택 배포
3. [ ] DNS 설정 (prometheus.igm.local, grafana.igm.local)
4. [ ] Grafana 초기 로그인 및 비밀번호 변경
5. [ ] 커스텀 대시보드 생성
6. [ ] BI 도구 연동 테스트
7. [ ] 알람 설정 (Alertmanager 추가)
8. [ ] 장기 메트릭 보관 전략 수립

## 참고 문서

- [README.md](k8s/monitoring/README.md) - 전체 가이드
- [DEPLOYMENT.md](k8s/monitoring/DEPLOYMENT.md) - 배포 가이드
- [CI-CD-SETUP-GUIDE.md](CI-CD-SETUP-GUIDE.md) - CI/CD 통합
- [Prometheus 공식 문서](https://prometheus.io/docs/)
- [Grafana 공식 문서](https://grafana.com/docs/)

---

**작성일**: 2024-12-20
**작성자**: Claude Code
**버전**: 1.0
