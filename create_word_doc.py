#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from datetime import datetime
import os

def add_heading_custom(doc, text, level=1):
    """커스텀 헤딩 추가"""
    heading = doc.add_heading(text, level=level)
    if level == 1:
        heading.runs[0].font.color.rgb = RGBColor(0, 51, 102)
        heading.runs[0].font.size = Pt(24)
    elif level == 2:
        heading.runs[0].font.color.rgb = RGBColor(0, 102, 204)
        heading.runs[0].font.size = Pt(18)
    return heading

def add_code_block(doc, code, language=""):
    """코드 블록 추가"""
    paragraph = doc.add_paragraph()
    paragraph.style = 'Normal'
    run = paragraph.add_run(code)
    run.font.name = 'Consolas'
    run.font.size = Pt(9)
    paragraph.paragraph_format.left_indent = Inches(0.5)
    paragraph.paragraph_format.space_before = Pt(6)
    paragraph.paragraph_format.space_after = Pt(6)
    # 배경색 효과 (약간의 회색)
    shading = paragraph._element.get_or_add_pPr()

def add_table_data(doc, headers, rows):
    """표 추가"""
    table = doc.add_table(rows=1, cols=len(headers))
    table.style = 'Light Grid Accent 1'

    # 헤더 추가
    hdr_cells = table.rows[0].cells
    for i, header in enumerate(headers):
        hdr_cells[i].text = header
        for paragraph in hdr_cells[i].paragraphs:
            for run in paragraph.runs:
                run.font.bold = True

    # 데이터 추가
    for row_data in rows:
        row_cells = table.add_row().cells
        for i, cell_data in enumerate(row_data):
            row_cells[i].text = str(cell_data)

    return table

def create_infrastructure_document():
    """인프라 구성 문서 생성"""
    doc = Document()

    # 문서 제목
    title = doc.add_heading('Azure AKS 인프라 구성 문서', 0)
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER

    # 부제목
    subtitle = doc.add_paragraph('Terraform 기반 Infrastructure as Code')
    subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
    subtitle.runs[0].font.size = Pt(14)
    subtitle.runs[0].font.color.rgb = RGBColor(100, 100, 100)

    # 작성일
    date_para = doc.add_paragraph(f'작성일: {datetime.now().strftime("%Y년 %m월 %d일")}')
    date_para.alignment = WD_ALIGN_PARAGRAPH.CENTER

    doc.add_page_break()

    # 목차 (수동)
    add_heading_custom(doc, '목차', 1)
    toc_items = [
        "1. 개요",
        "2. 인프라 아키텍처",
        "3. Terraform 구성",
        "4. 네트워크 구성",
        "5. 데이터베이스 구성",
        "6. N8N Workflow Automation",
        "7. ArgoCD GitOps",
        "8. GitHub Actions CI/CD",
        "9. 보안 및 인증",
        "10. 배포 가이드",
        "11. 운영 가이드",
    ]
    for item in toc_items:
        doc.add_paragraph(item, style='List Number')

    doc.add_page_break()

    # 1. 개요
    add_heading_custom(doc, '1. 개요', 1)
    doc.add_paragraph(
        '본 문서는 Azure Kubernetes Service (AKS)를 중심으로 한 클라우드 인프라 구성에 대한 '
        '상세 내역을 담고 있습니다. Terraform을 사용한 Infrastructure as Code (IaC) 방식으로 '
        '구축되었으며, GitOps 패턴을 적용한 자동화된 배포 파이프라인을 포함합니다.'
    )

    # 주요 구성 요소
    add_heading_custom(doc, '1.1 주요 구성 요소', 2)
    components = [
        ['구성 요소', '수량', 'SKU/크기', '비고'],
        ['AKS Cluster', '1', 'Standard_B2s x3', 'Kubernetes 1.33.5'],
        ['MySQL Master', '1', 'GP_Standard_D2ds_v4', 'Zone Redundant HA'],
        ['MySQL Replicas', '2', 'GP_Standard_D2ds_v4', 'Read-Only'],
        ['Cosmos DB', '1', 'Serverless', 'Private Link'],
        ['Redis Cache', '1', 'Standard C1', 'AAD Authentication'],
        ['Application Gateway', '1', 'Standard_v2', 'Capacity: 2'],
        ['N8N Pods', '2', '512Mi/250m', 'High Availability'],
    ]
    add_table_data(doc, components[0], components[1:])

    doc.add_page_break()

    # 2. 인프라 아키텍처
    add_heading_custom(doc, '2. 인프라 아키텍처', 1)

    doc.add_paragraph(
        '전체 인프라는 다음과 같은 계층 구조로 구성되어 있습니다:'
    )

    arch_text = """
    Internet
       ↓
Application Gateway (Public IP: 20.249.157.190)
       ↓
   ┌───┴────┐
   ↓        ↓
Load     ArgoCD
Balancer  Server
   ↓
AKS Cluster (3 Nodes)
   ↓
   └──┬──┬──┬───┐
      ↓  ↓  ↓   ↓
    MySQL Cosmos Redis N8N
    Master  DB   Cache (x2)
      ↓
   ┌──┴──┐
Replica Replica
   1      2
    """
    add_code_block(doc, arch_text)

    # 아키텍처 이미지 추가 시도
    image_path1 = r"D:\IGM\matchup\martinjung2013\terraform\Copilot_20251213_140323-구성도.png"
    image_path2 = r"D:\IGM\matchup\martinjung2013\terraform\KakaoTalk_20251213_143320742-구성도2.png"

    if os.path.exists(image_path1):
        doc.add_paragraph('아키텍처 다이어그램 1:', style='Heading 3')
        try:
            doc.add_picture(image_path1, width=Inches(6))
        except:
            doc.add_paragraph('(이미지 로드 실패)')

    if os.path.exists(image_path2):
        doc.add_paragraph('아키텍처 다이어그램 2:', style='Heading 3')
        try:
            doc.add_picture(image_path2, width=Inches(6))
        except:
            doc.add_paragraph('(이미지 로드 실패)')

    doc.add_page_break()

    # 3. Terraform 구성
    add_heading_custom(doc, '3. Terraform 구성', 1)

    add_heading_custom(doc, '3.1 기본 Terraform 파일 (D:\\IGM\\matchup\\martinjung2013\\terraform)', 2)

    doc.add_paragraph('main.tf - AKS 클러스터 정의', style='Heading 3')
    main_tf_code = """resource "azurerm_kubernetes_cluster" "k8s" {
  location            = azurerm_resource_group.rg.location
  name                = random_pet.azurerm_kubernetes_cluster_name.id
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = random_pet.azurerm_kubernetes_cluster_dns_prefix.id

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_D2_v2"
    node_count = var.node_count
  }
}"""
    add_code_block(doc, main_tf_code, "hcl")

    add_heading_custom(doc, '3.2 확장 Terraform 파일 (D:\\IGM\\aks)', 2)

    terraform_files = [
        ['파일명', '설명', '주요 리소스'],
        ['network.tf', 'VNet, Subnet, NSG 구성', 'VNet (10.0.0.0/8), 3개 Subnet'],
        ['database.tf', 'MySQL Master-Replica', '1 Master + 2 Read Replicas'],
        ['cosmosdb.tf', 'Cosmos DB Private Link', 'Java SDK 호환 Private Endpoint'],
        ['redis.tf', 'Redis Cache', 'AAD Authentication'],
        ['appgateway.tf', 'Application Gateway', 'Standard_v2'],
    ]
    add_table_data(doc, terraform_files[0], terraform_files[1:])

    doc.add_page_break()

    # 4. 네트워크 구성
    add_heading_custom(doc, '4. 네트워크 구성', 1)

    add_heading_custom(doc, '4.1 VNet 구조', 2)
    network_config = """VNet: 10.0.0.0/8
├── AKS Subnet: 10.224.0.0/16
│   └── AKS Nodes, N8N Pods
├── Application Gateway Subnet: 10.1.0.0/24
│   └── App Gateway
└── Database Subnet: 10.2.0.0/24
    └── Private Endpoints"""
    add_code_block(doc, network_config)

    add_heading_custom(doc, '4.2 Private DNS Zones', 2)
    dns_zones = [
        ['DNS Zone', '용도'],
        ['mysql.database.azure.com', 'MySQL Flexible Server'],
        ['privatelink.documents.azure.com', 'Cosmos DB'],
        ['privatelink.redis.cache.windows.net', 'Redis Cache'],
    ]
    add_table_data(doc, dns_zones[0], dns_zones[1:])

    doc.add_page_break()

    # 5. 데이터베이스 구성
    add_heading_custom(doc, '5. 데이터베이스 구성', 1)

    add_heading_custom(doc, '5.1 MySQL Master-Replica 구성', 2)
    doc.add_paragraph(
        'MySQL은 1개의 Master 노드와 2개의 Read Replica로 구성되어 읽기 성능을 3배 향상시켰습니다.'
    )

    mysql_info = [
        ['노드', 'FQDN', '역할', '특징'],
        ['Master', 'mysql-master-rg-useful-cougar.mysql.database.azure.com', 'Read/Write', 'Zone Redundant HA'],
        ['Replica 1', 'mysql-replica1-rg-useful-cougar.mysql.database.azure.com', 'Read-Only', 'Async Replication'],
        ['Replica 2', 'mysql-replica2-rg-useful-cougar.mysql.database.azure.com', 'Read-Only', 'Async Replication'],
    ]
    add_table_data(doc, mysql_info[0], mysql_info[1:])

    add_heading_custom(doc, '5.2 Cosmos DB (Java SDK Private Link)', 2)
    doc.add_paragraph(
        'Cosmos DB는 Java SDK와 호환되는 Private Link Endpoint로 구성되어 있으며, '
        '완전한 Keyless 인증 (RBAC)을 사용합니다.'
    )

    cosmos_code = """// Java SDK 연결 예제
import com.azure.cosmos.*;
import com.azure.identity.*;

DefaultAzureCredential credential = new DefaultAzureCredentialBuilder().build();

CosmosClient client = new CosmosClientBuilder()
    .endpoint("https://cosmos-rg-useful-cougar.documents.azure.com:443/")
    .credential(credential)
    .gatewayMode()  // Private Link 사용
    .consistencyLevel(ConsistencyLevel.SESSION)
    .buildClient();"""
    add_code_block(doc, cosmos_code, "java")

    doc.add_page_break()

    # 6. N8N Workflow Automation
    add_heading_custom(doc, '6. N8N Workflow Automation', 1)

    doc.add_paragraph(
        'N8N은 워크플로우 자동화 도구로, ArgoCD를 통해 GitOps 방식으로 배포됩니다.'
    )

    add_heading_custom(doc, '6.1 N8N 구성', 2)
    n8n_config = [
        ['항목', '값'],
        ['Replicas', '2 (고가용성)'],
        ['인증 방식', '기존 AKS 인증키 재사용'],
        ['Username', 'admin'],
        ['Password', 'HEeG57YwIUD8qE9r'],
        ['데이터베이스', 'MySQL Master'],
        ['큐', 'Redis Cache'],
        ['스토리지', 'Azure Premium Managed Disk (10Gi)'],
    ]
    add_table_data(doc, n8n_config[0], n8n_config[1:])

    add_heading_custom(doc, '6.2 Kubernetes Manifests', 2)
    n8n_manifests = [
        ['파일', '설명'],
        ['namespace.yaml', 'N8N 네임스페이스'],
        ['configmap.yaml', '환경 설정'],
        ['secret.yaml', '인증 정보 (기존 키 재사용)'],
        ['deployment.yaml', 'N8N Pod 정의 (2 replicas)'],
        ['service.yaml', 'ClusterIP 서비스'],
        ['pvc.yaml', 'Persistent Volume Claim (10Gi)'],
        ['ingress.yaml', 'Application Gateway 연동'],
    ]
    add_table_data(doc, n8n_manifests[0], n8n_manifests[1:])

    doc.add_page_break()

    # 7. ArgoCD GitOps
    add_heading_custom(doc, '7. ArgoCD GitOps', 1)

    doc.add_paragraph(
        'ArgoCD는 GitOps 패턴을 구현하여 Git 저장소의 변경사항을 자동으로 Kubernetes 클러스터에 반영합니다.'
    )

    add_heading_custom(doc, '7.1 ArgoCD 접속 정보', 2)
    argocd_info = [
        ['항목', '값'],
        ['URL', 'https://20.249.157.190'],
        ['Username', 'admin'],
        ['Password', 'HEeG57YwIUD8qE9r'],
        ['CLI 위치', '~/argocd.exe (v3.2.1)'],
    ]
    add_table_data(doc, argocd_info[0], argocd_info[1:])

    add_heading_custom(doc, '7.2 N8N Application 정의', 2)
    argocd_app = """apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: n8n
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/<YOUR-ORG>/<YOUR-REPO>.git
    targetRevision: main
    path: k8s/n8n
  destination:
    server: https://kubernetes.default.svc
    namespace: n8n
  syncPolicy:
    automated:
      prune: true
      selfHeal: true"""
    add_code_block(doc, argocd_app, "yaml")

    doc.add_page_break()

    # 8. GitHub Actions CI/CD
    add_heading_custom(doc, '8. GitHub Actions CI/CD', 1)

    doc.add_paragraph(
        'GitHub Actions를 사용하여 완전 자동화된 CI/CD 파이프라인을 구축했습니다.'
    )

    add_heading_custom(doc, '8.1 Workflow 구성', 2)
    workflows = [
        ['Workflow', '트리거', '주요 작업'],
        ['aks-deploy.yaml', '*.tf, k8s/** 파일 변경', 'Terraform validate/plan/apply, K8s 배포'],
        ['argocd-sync.yaml', 'k8s/**, argocd/** 파일 변경', 'ArgoCD 동기화, Health Check'],
    ]
    add_table_data(doc, workflows[0], workflows[1:])

    add_heading_custom(doc, '8.2 필요한 GitHub Secrets', 2)
    secrets = [
        ['Secret 이름', '설명', '예시 값'],
        ['AZURE_CREDENTIALS', 'Azure Service Principal JSON', '{...}'],
        ['MYSQL_ADMIN_PASSWORD', 'MySQL 관리자 비밀번호', 'YourSecurePassword123!'],
        ['ARGOCD_PASSWORD', 'ArgoCD admin 비밀번호', 'HEeG57YwIUD8qE9r'],
    ]
    add_table_data(doc, secrets[0], secrets[1:])

    doc.add_page_break()

    # 9. 보안 및 인증
    add_heading_custom(doc, '9. 보안 및 인증', 1)

    add_heading_custom(doc, '9.1 Keyless Authentication', 2)
    doc.add_paragraph(
        '모든 데이터베이스 서비스는 Managed Identity를 사용한 Keyless 인증 방식을 채택했습니다:'
    )

    keyless_auth = [
        ['서비스', '인증 방식', '특징'],
        ['MySQL', 'AAD Authentication', 'System Assigned Identity'],
        ['Cosmos DB', 'RBAC', 'local_authentication_disabled = true'],
        ['Redis', 'AAD Authentication', 'System Assigned Identity'],
    ]
    add_table_data(doc, keyless_auth[0], keyless_auth[1:])

    add_heading_custom(doc, '9.2 공통 인증키', 2)
    doc.add_paragraph(
        '기존 AKS에서 사용하던 인증키를 N8N과 ArgoCD에서 재사용하여 관리를 간소화했습니다.'
    )

    auth_key_usage = [
        ['서비스', '사용처', '키 값'],
        ['ArgoCD', 'Admin Password', 'HEeG57YwIUD8qE9r'],
        ['N8N', 'Basic Auth Password', 'HEeG57YwIUD8qE9r'],
        ['N8N', 'Encryption Key', 'HEeG57YwIUD8qE9r'],
    ]
    add_table_data(doc, auth_key_usage[0], auth_key_usage[1:])

    doc.add_page_break()

    # 10. 배포 가이드
    add_heading_custom(doc, '10. 배포 가이드', 1)

    add_heading_custom(doc, '10.1 Terraform 인프라 배포', 2)
    terraform_deploy = """# 1. 디렉토리 이동
cd D:\\IGM\\aks

# 2. 변수 설정
export TF_VAR_mysql_admin_password="YourSecurePassword123!"

# 3. Terraform 초기화
terraform init

# 4. 배포 계획 확인
terraform plan

# 5. 인프라 배포
terraform apply"""
    add_code_block(doc, terraform_deploy, "bash")

    add_heading_custom(doc, '10.2 ArgoCD를 통한 N8N 배포', 2)
    argocd_deploy = """# 1. ArgoCD 로그인
./argocd.exe login 20.249.157.190 \\
  --username admin \\
  --password HEeG57YwIUD8qE9r \\
  --insecure

# 2. N8N Application 생성
kubectl apply -f argocd/n8n-application.yaml

# 3. 동기화
./argocd.exe app sync n8n

# 4. 상태 확인
./argocd.exe app get n8n"""
    add_code_block(doc, argocd_deploy, "bash")

    doc.add_page_break()

    # 11. 운영 가이드
    add_heading_custom(doc, '11. 운영 가이드', 1)

    add_heading_custom(doc, '11.1 모니터링 명령어', 2)
    monitoring_cmds = """# N8N Pod 상태
kubectl get pods -n n8n

# N8N 로그
kubectl logs -n n8n deployment/n8n -f

# ArgoCD Application 상태
./argocd.exe app get n8n

# MySQL Master 상태
az mysql flexible-server show \\
  --resource-group rg-useful-cougar \\
  --name mysql-master-rg-useful-cougar"""
    add_code_block(doc, monitoring_cmds, "bash")

    add_heading_custom(doc, '11.2 트러블슈팅', 2)
    troubleshooting = [
        ['문제', '진단 방법', '해결 방법'],
        ['N8N Pod 시작 실패', 'kubectl describe pod -n n8n <pod-name>', 'Secret, ConfigMap 확인'],
        ['ArgoCD 동기화 실패', './argocd.exe app get n8n --show-operation', '수동 sync 재시도'],
        ['MySQL 연결 실패', 'kubectl exec -it <pod> -- ping <mysql-fqdn>', 'Private DNS 확인'],
        ['Cosmos DB 연결 실패', 'nslookup cosmos-*.documents.azure.com', 'Private Endpoint 확인'],
    ]
    add_table_data(doc, troubleshooting[0], troubleshooting[1:])

    doc.add_page_break()

    # 부록
    add_heading_custom(doc, '부록 A: 파일 구조', 1)
    file_structure = """D:\\IGM\\aks\\
├── Terraform 구성
│   ├── main.tf              # AKS 클러스터
│   ├── providers.tf         # Provider 설정
│   ├── variables.tf         # 변수
│   ├── outputs.tf           # 출력
│   ├── network.tf           # VNet, Subnet, NSG
│   ├── appgateway.tf        # Application Gateway
│   ├── database.tf          # MySQL Master-Replica
│   ├── cosmosdb.tf          # Cosmos DB
│   ├── redis.tf             # Redis Cache
│   └── ssh.tf               # SSH 키
│
├── Kubernetes Manifests
│   └── k8s/n8n/
│       ├── namespace.yaml
│       ├── configmap.yaml
│       ├── secret.yaml
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── pvc.yaml
│       └── ingress.yaml
│
├── ArgoCD
│   └── argocd/
│       └── n8n-application.yaml
│
└── GitHub Actions
    └── .github/workflows/
        ├── aks-deploy.yaml
        └── argocd-sync.yaml

D:\\IGM\\matchup\\martinjung2013\\terraform\\
├── main.tf
├── providers.tf
├── variables.tf
├── outputs.tf
├── ssh.tf
└── aks-store-quickstart.yaml"""
    add_code_block(doc, file_structure)

    # 문서 저장
    output_path = r"D:\IGM\aks\Azure_AKS_Infrastructure_Documentation.docx"
    doc.save(output_path)
    print(f"문서가 성공적으로 생성되었습니다: {output_path}")
    return output_path

if __name__ == "__main__":
    try:
        output_file = create_infrastructure_document()
        print(f"\n✅ 문서 생성 완료!")
        print(f"📄 파일 위치: {output_file}")
    except Exception as e:
        print(f"❌ 오류 발생: {e}")
        import traceback
        traceback.print_exc()
