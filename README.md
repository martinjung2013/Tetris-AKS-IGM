# Azure AKS Infrastructure with Terraform

이 Terraform 템플릿은 Azure Kubernetes Service (AKS)와 관련 인프라를 배포합니다.

## 아키텍처 구성요소

### 네트워크
- **Virtual Network (VNet)**: 10.0.0.0/8
- **AKS Subnet**: 10.224.0.0/16
- **Application Gateway Subnet**: 10.1.0.0/24
- **Database Subnet**: 10.2.0.0/24
- **Network Security Groups (NSG)**: AKS Subnet 보안

### 컴퓨팅
- **AKS Cluster**: 3개 노드 (Standard_B2s)
- **Application Gateway**: Standard_v2, 2 인스턴스

### 데이터베이스 (Keyless Authentication)
- **Azure Database for MySQL Flexible Server**
  - System Assigned Managed Identity 사용
  - AAD Authentication 활성화
  - Private Endpoint 연결

- **Azure Cosmos DB**
  - Local authentication 비활성화 (RBAC만 사용)
  - System Assigned Managed Identity
  - Private Endpoint 연결

- **Azure Cache for Redis**
  - AAD Authentication 활성화
  - System Assigned Managed Identity
  - Private Endpoint 연결

## Keyless Authentication 방식

모든 데이터베이스 서비스는 **Managed Identity**를 사용한 keyless 방식으로 구성됩니다:

1. **MySQL**: AAD Authentication + System Assigned Identity
2. **Cosmos DB**: RBAC 기반 인증 (local_authentication_disabled = true)
3. **Redis**: AAD Authentication 활성화

이 방식은 다음과 같은 장점이 있습니다:
- ✅ 비밀번호/키 관리 불필요
- ✅ 자동 키 로테이션
- ✅ Azure RBAC를 통한 세밀한 권한 제어
- ✅ 보안 강화

## 사용 방법

### 1. 변수 설정

`terraform.tfvars` 파일을 생성하고 MySQL 비밀번호를 설정:

```hcl
mysql_admin_password = "YourSecurePassword123!"
```

### 2. Terraform 초기화

```bash
cd D:\IGM\aks
terraform init
```

### 3. 배포 계획 확인

```bash
terraform plan
```

### 4. 인프라 배포

```bash
terraform apply
```

### 5. 출력 확인

```bash
terraform output
```

## 주요 출력값

- `appgw_public_ip`: Application Gateway 공개 IP
- `mysql_fqdn`: MySQL 서버 FQDN
- `cosmosdb_endpoint`: Cosmos DB 엔드포인트
- `redis_hostname`: Redis 호스트명
- `cosmosdb_identity_principal_id`: Cosmos DB Managed Identity ID
- `redis_identity_principal_id`: Redis Managed Identity ID
- `mysql_identity_principal_id`: MySQL Managed Identity ID

## AKS에서 데이터베이스 접근 설정

### MySQL 접근 (Keyless)

```yaml
# AKS Pod에 Managed Identity 할당 후
apiVersion: v1
kind: Pod
metadata:
  name: mysql-app
spec:
  serviceAccountName: workload-identity-sa
  containers:
  - name: app
    image: myapp:latest
    env:
    - name: MYSQL_HOST
      value: "<mysql_fqdn>"
    - name: AZURE_CLIENT_ID
      value: "<managed_identity_client_id>"
```

### Cosmos DB 접근 (Keyless RBAC)

```bash
# AKS Pod의 Managed Identity에 Cosmos DB 역할 할당
az cosmosdb sql role assignment create \
  --account-name <cosmosdb_account_name> \
  --resource-group <resource_group> \
  --scope "/" \
  --principal-id <pod_managed_identity_principal_id> \
  --role-definition-id 00000000-0000-0000-0000-000000000002
```

### Redis 접근 (Keyless AAD)

```bash
# Redis Data Contributor 역할 할당
az role assignment create \
  --role "Redis Cache Contributor" \
  --assignee <pod_managed_identity_principal_id> \
  --scope <redis_resource_id>
```

## 파일 구조

```
D:\IGM\aks\
├── main.tf              # AKS 클러스터 정의
├── providers.tf         # Provider 설정
├── variables.tf         # 변수 정의
├── outputs.tf           # 출력 정의
├── ssh.tf               # SSH 키 생성
├── network.tf           # VNet, Subnet, NSG
├── appgateway.tf        # Application Gateway
├── database.tf          # Azure MySQL (Keyless)
├── cosmosdb.tf          # Cosmos DB (Keyless)
├── redis.tf             # Redis Cache (Keyless)
└── README.md            # 이 파일
```

## 보안 고려사항

1. **Network Isolation**: 모든 데이터베이스는 Private Endpoint 사용
2. **Keyless Authentication**: Managed Identity 기반 인증
3. **NSG**: AKS Subnet에 네트워크 보안 그룹 적용
4. **TLS**: Redis는 TLS 1.2 이상 강제
5. **Public Access**: 모든 데이터베이스의 public access 비활성화

## 리소스 삭제

```bash
terraform destroy
```

## 참고사항

- MySQL 초기 비밀번호는 초기 설정용이며, 이후 AAD 인증 사용 권장
- Cosmos DB는 완전히 keyless로 구성됨 (RBAC만 사용)
- Redis는 AAD 인증과 Managed Identity 사용
- Application Gateway는 AKS LoadBalancer와 통합 필요
