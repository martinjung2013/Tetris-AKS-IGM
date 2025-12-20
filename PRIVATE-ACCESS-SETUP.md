# N8N Private Access 설정 가이드

## 개요

이 가이드는 Azure Private Link를 사용하여 N8N에 안전하게 접근하는 방법을 설명합니다.

## 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                        VNet: 10.0.0.0/8                         │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ AKS Subnet: 10.224.0.0/16                                │  │
│  │                                                           │  │
│  │  ┌─────────────┐                                         │  │
│  │  │  N8N Pod    │                                         │  │
│  │  │  :5678      │                                         │  │
│  │  └──────┬──────┘                                         │  │
│  │         │                                                 │  │
│  │         ▼                                                 │  │
│  │  ┌─────────────┐                                         │  │
│  │  │ Internal LB │ ◄── Private Link Service               │  │
│  │  │ 10.224.x.x  │                                         │  │
│  │  └─────────────┘                                         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          │                                      │
│                          │ Private Link                         │
│                          ▼                                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Private Endpoint Subnet: 10.3.0.0/24                     │  │
│  │                                                           │  │
│  │  ┌─────────────────┐                                     │  │
│  │  │ Private Endpoint│                                     │  │
│  │  │ 10.3.0.x        │                                     │  │
│  │  └────────┬────────┘                                     │  │
│  │           │                                               │  │
│  │           │ DNS: n8n.n8n.internal → 10.3.0.x             │  │
│  │           ▼                                               │  │
│  │  ┌─────────────────┐                                     │  │
│  │  │ Private DNS     │                                     │  │
│  │  │ n8n.internal    │                                     │  │
│  │  └─────────────────┘                                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                          │
                          │ VPN / ExpressRoute / Bastion
                          ▼
                    ┌──────────┐
                    │   User   │
                    └──────────┘
```

## 접근 방법 비교

| 방법 | 보안 | 성능 | 비용 | 복잡도 | 용도 |
|------|------|------|------|--------|------|
| Port Forward | 낮음 | 낮음 | 무료 | 낮음 | 개발/테스트 |
| Internal LB | 중간 | 높음 | 낮음 | 중간 | VNet 내부 |
| Private Endpoint | 높음 | 높음 | 중간 | 높음 | 프로덕션 |
| Public LB | 낮음 | 높음 | 낮음 | 낮음 | 비권장 |

## 배포 단계

### 1단계: Internal LoadBalancer 배포

Internal LoadBalancer는 VNet 내부에서만 접근 가능한 Private IP를 할당합니다.

#### 배포
```bash
kubectl apply -f k8s/n8n/service-internal-lb.yaml
```

#### 확인
```bash
# Service 상태 확인
kubectl get svc n8n-internal -n n8n

# 예상 출력:
# NAME           TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)
# n8n-internal   LoadBalancer   10.0.x.x       10.224.x.x    80:xxxxx/TCP,443:xxxxx/TCP

# Private IP 확인
kubectl get svc n8n-internal -n n8n -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

#### 테스트 (VNet 내부 VM에서)
```bash
# Private IP 가져오기
PRIVATE_IP=$(kubectl get svc n8n-internal -n n8n -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# 접속 테스트
curl http://$PRIVATE_IP/healthz
```

### 2단계: Private Link Service 확인

Internal LoadBalancer 배포 시 Private Link Service가 자동으로 생성됩니다.

#### 확인 (Azure CLI)
```bash
# AKS Node Resource Group 가져오기
NODE_RG=$(az aks show \
  --resource-group rg-useful-cougar \
  --name <AKS_CLUSTER_NAME> \
  --query nodeResourceGroup -o tsv)

# Private Link Service 확인
az network private-link-service list \
  --resource-group $NODE_RG \
  --query "[?contains(name, 'n8n-pls')]" \
  -o table

# Private Link Service ID 가져오기
PLS_ID=$(az network private-link-service list \
  --resource-group $NODE_RG \
  --query "[?contains(name, 'n8n-pls')].id" -o tsv)

echo "Private Link Service ID: $PLS_ID"
```

### 3단계: Private Endpoint 생성

#### 방법 A: Terraform (권장)

**1. Terraform 변수 파일 업데이트**

`terraform/terraform.tfvars` 또는 환경 변수:
```hcl
resource_group_name = "rg-useful-cougar"
resource_group_location = "koreacentral"
```

**2. Terraform 실행**
```bash
cd d:/IGM/aks

# Private Endpoint만 배포
terraform plan -target=azurerm_private_endpoint.n8n
terraform apply -target=azurerm_private_endpoint.n8n

# 또는 전체 배포
terraform plan
terraform apply
```

**3. 확인**
```bash
# Private Endpoint IP 확인
terraform output n8n_private_endpoint_ip

# Private URL 확인
terraform output n8n_private_url
```

#### 방법 B: Azure CLI

**1. Private Endpoint 생성**
```bash
# Private Link Service ID 확인 (2단계에서 가져온 값 사용)
PLS_ID="<YOUR_PLS_ID>"

# Private Endpoint 생성
az network private-endpoint create \
  --name n8n-private-endpoint \
  --resource-group rg-useful-cougar \
  --vnet-name rg-useful-cougar-vnet \
  --subnet private-endpoints-subnet \
  --private-connection-resource-id $PLS_ID \
  --connection-name n8n-privatelink-connection \
  --location koreacentral \
  --group-id "" \
  --manual-request false
```

**2. Private DNS Zone 생성**
```bash
# DNS Zone 생성
az network private-dns zone create \
  --resource-group rg-useful-cougar \
  --name n8n.internal

# VNet에 연결
az network private-dns link vnet create \
  --resource-group rg-useful-cougar \
  --zone-name n8n.internal \
  --name n8n-dns-link \
  --virtual-network rg-useful-cougar-vnet \
  --registration-enabled false
```

**3. DNS A 레코드 생성**
```bash
# Private Endpoint IP 가져오기
PE_IP=$(az network private-endpoint show \
  --name n8n-private-endpoint \
  --resource-group rg-useful-cougar \
  --query 'customDnsConfigs[0].ipAddresses[0]' -o tsv)

echo "Private Endpoint IP: $PE_IP"

# A 레코드 생성
az network private-dns record-set a create \
  --name n8n \
  --zone-name n8n.internal \
  --resource-group rg-useful-cougar

az network private-dns record-set a add-record \
  --record-set-name n8n \
  --zone-name n8n.internal \
  --resource-group rg-useful-cougar \
  --ipv4-address $PE_IP
```

### 4단계: 접속 테스트

#### VNet 내부 VM에서 테스트

**1. Bastion 또는 VPN으로 VNet 내부 VM 접속**

**2. DNS 확인**
```bash
# n8n.n8n.internal 도메인 확인
nslookup n8n.n8n.internal

# 또는
dig n8n.n8n.internal
```

**3. HTTP 접속 테스트**
```bash
curl http://n8n.n8n.internal/healthz
```

**4. 브라우저 접속**
```
http://n8n.n8n.internal
```

**5. 로그인**
- 사용자명: `admin`
- 비밀번호: `N8nAdmin2025!`

## 추가 설정

### HTTPS 설정 (선택사항)

#### 1. 자체 서명 인증서 생성
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=n8n.n8n.internal/O=n8n"

kubectl create secret tls n8n-tls \
  --cert=tls.crt \
  --key=tls.key \
  -n n8n
```

#### 2. Ingress 생성 (Internal)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: n8n-internal-ingress
  namespace: n8n
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx-internal
  tls:
  - hosts:
    - n8n.n8n.internal
    secretName: n8n-tls
  rules:
  - host: n8n.n8n.internal
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

### VPN 설정

#### Azure VPN Gateway 설정
```bash
# VPN Gateway Subnet 생성
az network vnet subnet create \
  --resource-group rg-useful-cougar \
  --vnet-name rg-useful-cougar-vnet \
  --name GatewaySubnet \
  --address-prefixes 10.0.255.0/27

# Public IP 생성
az network public-ip create \
  --resource-group rg-useful-cougar \
  --name vpn-gateway-pip \
  --allocation-method Static \
  --sku Standard

# VPN Gateway 생성 (약 30-45분 소요)
az network vnet-gateway create \
  --resource-group rg-useful-cougar \
  --name n8n-vpn-gateway \
  --vnet rg-useful-cougar-vnet \
  --public-ip-address vpn-gateway-pip \
  --gateway-type Vpn \
  --vpn-type RouteBased \
  --sku VpnGw1 \
  --no-wait
```

## 포트 정보

| 포트 | 프로토콜 | 용도 | 비고 |
|------|---------|------|------|
| 5678 | HTTP | N8N 웹 UI | 기본 포트 |
| 80 | HTTP | HTTP 접속 | LoadBalancer |
| 443 | HTTPS | HTTPS 접속 | TLS 설정 필요 |
| 8080 | HTTP | **사용 불가** | ArgoCD 사용 중 |

## 로컬 개발 환경 Port Forward

ArgoCD가 8080을 사용하므로 다른 포트 사용:

```bash
# 권장: 5678 (n8n 기본 포트)
kubectl port-forward -n n8n svc/n8n 5678:80
# 접속: http://localhost:5678

# 대체 1: 3000
kubectl port-forward -n n8n svc/n8n 3000:80
# 접속: http://localhost:3000

# 대체 2: 9000
kubectl port-forward -n n8n svc/n8n 9000:80
# 접속: http://localhost:9000
```

## 문제 해결

### Internal LoadBalancer가 Private IP를 할당받지 못함

```bash
# Service 이벤트 확인
kubectl describe svc n8n-internal -n n8n

# 가능한 원인:
# 1. Subnet이 존재하지 않음
az network vnet subnet show \
  --resource-group rg-useful-cougar \
  --vnet-name rg-useful-cougar-vnet \
  --name aks-subnet

# 2. RBAC 권한 부족
# AKS Managed Identity에 Network Contributor 역할 필요
```

### Private Link Service가 생성되지 않음

```bash
# Service annotation 확인
kubectl get svc n8n-internal -n n8n -o yaml | grep azure-pls

# Private Link Service 확인
az network private-link-service list \
  --resource-group $NODE_RG
```

### Private Endpoint 연결 실패

```bash
# Private Endpoint 상태 확인
az network private-endpoint show \
  --name n8n-private-endpoint \
  --resource-group rg-useful-cougar

# Connection 상태 확인
az network private-endpoint show \
  --name n8n-private-endpoint \
  --resource-group rg-useful-cougar \
  --query 'privateLinkServiceConnections[0].privateLinkServiceConnectionState'
```

### DNS 조회 실패

```bash
# Private DNS Zone 확인
az network private-dns zone show \
  --resource-group rg-useful-cougar \
  --name n8n.internal

# VNet Link 확인
az network private-dns link vnet list \
  --resource-group rg-useful-cougar \
  --zone-name n8n.internal

# A 레코드 확인
az network private-dns record-set a list \
  --resource-group rg-useful-cougar \
  --zone-name n8n.internal
```

## 비용 추정

### Azure 리소스 비용 (월간)

| 리소스 | 용도 | 예상 비용 (USD) |
|--------|------|-----------------|
| Internal LoadBalancer | 기본 LB | ~$18 |
| Private Link Service | PLS (데이터 전송 별도) | ~$7.30 |
| Private Endpoint | PE | ~$7.30 |
| Private DNS Zone | DNS | ~$0.50 |
| VPN Gateway (선택) | P2S VPN | ~$140 |

**총 예상 비용**: ~$33/월 (VPN 제외), ~$173/월 (VPN 포함)

## 보안 권장사항

1. **Network Security Group 규칙 추가**
   - Private Endpoint Subnet에 NSG 적용
   - 필요한 IP 범위만 허용

2. **Private DNS Zone 보호**
   - RBAC으로 접근 제어
   - DNS 변경 로깅 활성화

3. **VPN 또는 ExpressRoute 사용**
   - 인터넷을 통한 접근 차단
   - 기업 네트워크에서만 접근 허용

4. **Application Gateway WAF 통합** (선택)
   - SQL Injection, XSS 방어
   - Rate Limiting

## 관련 문서

- [N8N-CONNECTION-INFO.md](N8N-CONNECTION-INFO.md) - 접속 정보
- [N8N-ACCESS-GUIDE.md](N8N-ACCESS-GUIDE.md) - 전체 접속 방법
- [network.tf](network.tf) - VNet 구성
- [terraform/n8n-private-endpoint.tf](terraform/n8n-private-endpoint.tf) - Terraform 코드

---

**작성일**: 2024-12-20
**버전**: 1.0
