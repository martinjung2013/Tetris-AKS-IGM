#!/usr/bin/env pwsh
<#
.SYNOPSIS
AKS 배포 준비 자동화 스크립트

.DESCRIPTION
D:\IGM\aks 프로젝트의 배포를 위한 사전 체크 및 준비 작업을 자동화합니다.

.USAGE
.\prepare-deployment.ps1

.NOTES
작성자: AI 배포 준비 도구
작성일: 2025-12-20
#>

param(
    [string]$AksPath = "D:\IGM\aks",
    [string]$Action = "check" # check, setup, validate, deploy
)

# 색상 정의
$colors = @{
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "Cyan"
    Header = "Magenta"
}

function Write-Status {
    param(
        [string]$Message,
        [string]$Status = "Info"
    )
    
    $color = $colors[$Status]
    $prefix = switch($Status) {
        "Success" { "✅" }
        "Warning" { "⚠️ " }
        "Error" { "❌" }
        "Info" { "ℹ️ " }
        "Header" { "📋" }
    }
    
    Write-Host "$prefix $Message" -ForegroundColor $color
}

function Check-Prerequisites {
    Write-Host "`n" + ("=" * 60) -ForegroundColor $colors.Header
    Write-Status "사전 조건 확인" "Header"
    Write-Host ("=" * 60) -ForegroundColor $colors.Header
    
    $prerequisites = @{
        "Azure CLI" = { Get-Command az -ErrorAction SilentlyContinue }
        "Terraform" = { Get-Command terraform -ErrorAction SilentlyContinue }
        "kubectl" = { Get-Command kubectl -ErrorAction SilentlyContinue }
        "Git" = { Get-Command git -ErrorAction SilentlyContinue }
    }
    
    $allChecks = $true
    foreach ($tool in $prerequisites.Keys) {
        $installed = & $prerequisites[$tool]
        if ($installed) {
            Write-Status "$tool: 설치됨" "Success"
        } else {
            Write-Status "$tool: 미설치 (설치 필요)" "Error"
            $allChecks = $false
        }
    }
    
    return $allChecks
}

function Check-DirectoryStructure {
    Write-Host "`n" + ("=" * 60) -ForegroundColor $colors.Header
    Write-Status "디렉토리 구조 확인" "Header"
    Write-Host ("=" * 60) -ForegroundColor $colors.Header
    
    $requiredFiles = @(
        "main.tf",
        "providers.tf",
        "variables.tf",
        "outputs.tf",
        "network.tf",
        "database.tf",
        "cosmosdb.tf",
        "redis.tf",
        "appgateway.tf",
        "k8s/n8n/deployment.yaml",
        "k8s/n8n/service.yaml",
        "argocd/n8n-application.yaml"
    )
    
    $allExist = $true
    foreach ($file in $requiredFiles) {
        $fullPath = Join-Path $AksPath $file
        if (Test-Path $fullPath) {
            Write-Status "$file: ✓" "Success"
        } else {
            Write-Status "$file: 누락됨" "Error"
            $allExist = $false
        }
    }
    
    return $allExist
}

function Validate-TerraformConfig {
    Write-Host "`n" + ("=" * 60) -ForegroundColor $colors.Header
    Write-Status "Terraform 구성 검증" "Header"
    Write-Host ("=" * 60) -ForegroundColor $colors.Header
    
    Push-Location $AksPath
    
    # terraform init 확인
    if (Test-Path ".terraform") {
        Write-Status "Terraform 초기화됨" "Success"
    } else {
        Write-Status "Terraform 초기화 필요" "Warning"
        Write-Host "  실행: terraform init`n"
    }
    
    # terraform validate
    Write-Status "Terraform 구성 검증 중..." "Info"
    $output = terraform validate 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Status "Terraform 검증 통과" "Success"
    } else {
        Write-Status "Terraform 검증 실패" "Error"
        Write-Host $output
    }
    
    Pop-Location
}

function Check-RequiredVariables {
    Write-Host "`n" + ("=" * 60) -ForegroundColor $colors.Header
    Write-Status "필수 변수 확인" "Header"
    Write-Host ("=" * 60) -ForegroundColor $colors.Header
    
    $tfvarsPath = Join-Path $AksPath "terraform.tfvars"
    $tfvarsExamplePath = Join-Path $AksPath "terraform.tfvars.example"
    
    if (Test-Path $tfvarsPath) {
        Write-Status "terraform.tfvars: 존재함" "Success"
        
        # 파일 내용 확인
        $content = Get-Content $tfvarsPath
        if ($content -match "mysql_admin_password") {
            Write-Status "MySQL 비밀번호: 설정됨" "Success"
        } else {
            Write-Status "MySQL 비밀번호: 미설정" "Warning"
        }
    } else {
        Write-Status "terraform.tfvars: 누락됨 (생성 필요)" "Error"
        if (Test-Path $tfvarsExamplePath) {
            Write-Status "생성 방법: copy terraform.tfvars.example terraform.tfvars" "Info"
        }
    }
}

function Check-KubernetesManifests {
    Write-Host "`n" + ("=" * 60) -ForegroundColor $colors.Header
    Write-Status "Kubernetes 매니페스트 검증" "Header"
    Write-Host ("=" * 60) -ForegroundColor $colors.Header
    
    $k8sDir = Join-Path $AksPath "k8s/n8n"
    $yamlFiles = Get-ChildItem -Path $k8sDir -Filter "*.yaml"
    
    Write-Status "매니페스트 파일:" "Info"
    foreach ($file in $yamlFiles) {
        Write-Host "  ✓ $($file.Name)"
    }
    
    # secret.yaml 확인
    $secretFile = Join-Path $k8sDir "secret.yaml"
    if (Test-Path $secretFile) {
        $secretContent = Get-Content $secretFile
        
        # 플레이스홀더 확인
        if ($secretContent -match "<.*>") {
            Write-Status "Secret 파일: 플레이스홀더 있음 (수정 필요)" "Warning"
            Write-Host "  필수 값:"
            Write-Host "    - DB_MYSQLDB_USER"
            Write-Host "    - DB_MYSQLDB_PASSWORD"
            Write-Host "    - DB_MYSQLDB_HOST"
            Write-Host "    - REDIS_PASSWORD`n"
        } else {
            Write-Status "Secret 파일: 구성됨" "Success"
        }
    }
}

function Check-ArgoCD {
    Write-Host "`n" + ("=" * 60) -ForegroundColor $colors.Header
    Write-Status "ArgoCD 설정 확인" "Header"
    Write-Host ("=" * 60) -ForegroundColor $colors.Header
    
    $argoCdFile = Join-Path $AksPath "argocd/n8n-application.yaml"
    
    if (Test-Path $argoCdFile) {
        $content = Get-Content $argoCdFile
        
        if ($content -match "<YOUR-ORG>|<YOUR-REPO>") {
            Write-Status "ArgoCD 설정: 플레이스홀더 있음 (수정 필요)" "Error"
            Write-Host "  필수 수정:"
            Write-Host "    repoURL: https://github.com/<YOUR-ORG>/<YOUR-REPO>.git`n"
        } else {
            Write-Status "ArgoCD 설정: 구성됨" "Success"
        }
    }
}

function Show-TerraformOutputs {
    Write-Host "`n" + ("=" * 60) -ForegroundColor $colors.Header
    Write-Status "배포된 리소스 정보" "Header"
    Write-Host ("=" * 60) -ForegroundColor $colors.Header
    
    Push-Location $AksPath
    
    if (Test-Path ".terraform/environment") {
        $outputs = terraform output -json | ConvertFrom-Json
        
        Write-Status "리소스 그룹: $($outputs.resource_group_name.value)" "Info"
        Write-Status "AKS 클러스터: $($outputs.kubernetes_cluster_name.value)" "Info"
        Write-Status "Application Gateway IP: $($outputs.appgw_public_ip.value)" "Info"
    } else {
        Write-Status "Terraform 상태 파일을 찾을 수 없습니다" "Warning"
    }
    
    Pop-Location
}

function Setup-DeploymentEnvironment {
    Write-Host "`n" + ("=" * 60) -ForegroundColor $colors.Header
    Write-Status "배포 환경 설정" "Header"
    Write-Host ("=" * 60) -ForegroundColor $colors.Header
    
    Push-Location $AksPath
    
    # 1. terraform.tfvars 생성
    $tfvarsPath = "terraform.tfvars"
    if (-not (Test-Path $tfvarsPath)) {
        Write-Status "terraform.tfvars 생성 중..." "Info"
        
        @"
# MySQL Administrator Password
# 강력한 비밀번호를 사용하세요 (12자 이상, 대문자/소문자/숫자/특수문자 포함)
mysql_admin_password = "ChangeMe123!@#"

# AKS 노드 수 (기본값: 3)
node_count = 3

# 리소스 그룹 위치 (기본값: koreacentral)
resource_group_location = "koreacentral"
"@ | Out-File -Encoding UTF8 $tfvarsPath
        
        Write-Status "terraform.tfvars 생성됨" "Success"
        Write-Status "⚠️  MySQL 비밀번호를 변경하세요!" "Warning"
    }
    
    # 2. Terraform 초기화
    Write-Status "Terraform 초기화 중..." "Info"
    terraform init -upgrade
    
    # 3. 형식 검증
    Write-Status "Terraform 형식 검증..." "Info"
    terraform fmt -recursive
    
    # 4. 구성 검증
    Write-Status "Terraform 구성 검증..." "Info"
    terraform validate
    
    Pop-Location
    
    Write-Status "배포 환경 설정 완료" "Success"
}

function Show-DeploymentGuide {
    Write-Host "`n" + ("=" * 60) -ForegroundColor $colors.Header
    Write-Status "배포 절차 안내" "Header"
    Write-Host ("=" * 60) -ForegroundColor $colors.Header
    
    $guide = @"

📋 배포 단계별 절차:

[1단계] 사전 준비
  ✓ Azure CLI 로그인
    az login
    
  ✓ Terraform 변수 설정
    terraform.tfvars 파일 편집 (MySQL 비밀번호 설정)

[2단계] Terraform 배포
  ✓ 배포 계획 검토
    terraform plan -out=tfplan
    
  ✓ 인프라 배포 실행
    terraform apply tfplan
    
  예상 소요 시간: 15-20분

[3단계] AKS 연결 설정
  ✓ 클러스터 인증서 다운로드
    az aks get-credentials `
      --resource-group rg-useful-cougar `
      --name cluster-crucial-terrapin
    
  ✓ 연결 확인
    kubectl get nodes

[4단계] 쿠버네티스 리소스 배포
  ✓ 네임스페이스 생성
    kubectl apply -f k8s/n8n/namespace.yaml
    
  ✓ Secret 업데이트 (필수)
    kubectl apply -f k8s/n8n/secret.yaml
    
  ✓ 나머지 리소스 배포
    kubectl apply -f k8s/n8n/

[5단계] ArgoCD 설정 (선택사항)
  ✓ ArgoCD 애플리케이션 설정
    kubectl apply -f argocd/n8n-application.yaml
    
  ✓ 동기화 확인
    argocd app get n8n

[6단계] 배포 검증
  ✓ n8n 파드 상태 확인
    kubectl get pods -n n8n
    
  ✓ 로그 확인
    kubectl logs -n n8n deployment/n8n -f

"@
    
    Write-Host $guide -ForegroundColor $colors.Info
}

# 메인 실행
function Main {
    Write-Host "`n" + ("*" * 60) -ForegroundColor $colors.Header
    Write-Host "*" + (" " * 58) + "*" -ForegroundColor $colors.Header
    Write-Host "*  AKS 배포 준비 자동화 스크립트" + (" " * 30) + "*" -ForegroundColor $colors.Header
    Write-Host "*" + (" " * 58) + "*" -ForegroundColor $colors.Header
    Write-Host ("*" * 60) -ForegroundColor $colors.Header
    
    Write-Status "작업 경로: $AksPath" "Info"
    Write-Status "실행 모드: $Action" "Info"
    
    switch ($Action) {
        "check" {
            Check-Prerequisites | Out-Null
            Check-DirectoryStructure | Out-Null
            Validate-TerraformConfig
            Check-RequiredVariables
            Check-KubernetesManifests
            Check-ArgoCD
            Show-TerraformOutputs
        }
        
        "setup" {
            Check-Prerequisites | Out-Null
            Setup-DeploymentEnvironment
        }
        
        "validate" {
            Validate-TerraformConfig
            Check-KubernetesManifests
            Check-ArgoCD
        }
        
        "guide" {
            Show-DeploymentGuide
        }
        
        default {
            Write-Host "`n사용법:`n"
            Write-Host "  .\prepare-deployment.ps1 -Action check    # 배포 준비 상태 확인"
            Write-Host "  .\prepare-deployment.ps1 -Action setup    # 배포 환경 설정"
            Write-Host "  .\prepare-deployment.ps1 -Action validate # 구성 검증"
            Write-Host "  .\prepare-deployment.ps1 -Action guide    # 배포 절차 안내`n"
        }
    }
    
    Write-Host "`n" + ("=" * 60) -ForegroundColor $colors.Header
    Write-Status "스크립트 실행 완료" "Success"
    Write-Host ("=" * 60) -ForegroundColor $colors.Header
    Write-Host ""
}

# 실행
Main
