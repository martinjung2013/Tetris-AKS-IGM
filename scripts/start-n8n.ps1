# N8N 빠른 시작 스크립트
# Port Forward를 시작하고 브라우저를 엽니다

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("5678", "3000", "9000")]
    [string]$Port = "5678"
)

$ErrorActionPreference = "Stop"

# 색상 정의
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
Write-ColorOutput "          N8N 빠른 시작 스크립트         " "Cyan"
Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
Write-Host ""

# kubectl 확인
Write-ColorOutput "kubectl 확인 중..." "Yellow"
$kubectl = Get-Command kubectl -ErrorAction SilentlyContinue

if (-not $kubectl) {
    Write-ColorOutput "❌ kubectl이 설치되어 있지 않습니다." "Red"
    Write-ColorOutput "kubectl을 설치 후 다시 시도하세요." "Yellow"
    exit 1
}
Write-ColorOutput "✓ kubectl 확인 완료: $($kubectl.Source)" "Green"

# Kubernetes 컨텍스트 확인
Write-ColorOutput "`nKubernetes 컨텍스트 확인 중..." "Yellow"
try {
    $context = kubectl config current-context 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✓ 현재 컨텍스트: $context" "Green"
    } else {
        Write-ColorOutput "⚠️  컨텍스트를 확인할 수 없습니다." "Red"
        exit 1
    }
} catch {
    Write-ColorOutput "❌ Kubernetes 연결 실패" "Red"
    exit 1
}

# N8N Pod 상태 확인
Write-ColorOutput "`nN8N Pod 상태 확인 중..." "Yellow"
$pods = kubectl get pods -n n8n -l app=n8n -o json 2>$null | ConvertFrom-Json

if ($pods.items.Count -eq 0) {
    Write-ColorOutput "❌ N8N Pod를 찾을 수 없습니다." "Red"
    Write-ColorOutput "먼저 N8N을 배포하세요." "Yellow"
    exit 1
}

$podStatus = $pods.items[0].status.phase
if ($podStatus -ne "Running") {
    Write-ColorOutput "⚠️  N8N Pod가 Running 상태가 아닙니다: $podStatus" "Yellow"
    Write-ColorOutput "Pod가 시작될 때까지 기다리는 중..." "Yellow"

    # Pod가 Running 상태가 될 때까지 대기 (최대 60초)
    $timeout = 60
    $elapsed = 0
    while ($podStatus -ne "Running" -and $elapsed -lt $timeout) {
        Start-Sleep -Seconds 5
        $elapsed += 5
        $pods = kubectl get pods -n n8n -l app=n8n -o json 2>$null | ConvertFrom-Json
        $podStatus = $pods.items[0].status.phase
        Write-Host "." -NoNewline
    }
    Write-Host ""

    if ($podStatus -ne "Running") {
        Write-ColorOutput "❌ Pod가 시작되지 않았습니다. 수동으로 확인하세요:" "Red"
        Write-ColorOutput "   kubectl get pods -n n8n" "Yellow"
        Write-ColorOutput "   kubectl logs -n n8n deployment/n8n" "Yellow"
        exit 1
    }
}

Write-ColorOutput "✓ N8N Pod: Running" "Green"

# 포트 사용 중 확인
Write-ColorOutput "`n포트 $Port 사용 중 확인..." "Yellow"
$portInUse = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue

if ($portInUse) {
    $processId = $portInUse.OwningProcess
    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue

    Write-ColorOutput "⚠️  포트 $Port 가 이미 사용 중입니다." "Yellow"
    Write-ColorOutput "   프로세스: $($process.ProcessName) (PID: $processId)" "Yellow"
    Write-Host ""

    $response = Read-Host "프로세스를 종료하고 계속하시겠습니까? (y/N)"
    if ($response -eq "y" -or $response -eq "Y") {
        try {
            Stop-Process -Id $processId -Force
            Write-ColorOutput "✓ 프로세스 종료됨" "Green"
            Start-Sleep -Seconds 2
        } catch {
            Write-ColorOutput "❌ 프로세스를 종료할 수 없습니다." "Red"
            Write-ColorOutput "다른 포트를 사용하세요: .\start-n8n.ps1 -Port 3000" "Yellow"
            exit 1
        }
    } else {
        Write-ColorOutput "다른 포트를 사용하세요:" "Yellow"
        Write-ColorOutput "   .\start-n8n.ps1 -Port 3000" "Green"
        Write-ColorOutput "   .\start-n8n.ps1 -Port 9000" "Green"
        exit 0
    }
}

Write-ColorOutput "✓ 포트 $Port 사용 가능" "Green"

# Port Forward 시작
Write-Host ""
Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
Write-ColorOutput "Port Forward를 시작합니다..." "Cyan"
Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
Write-Host ""
Write-ColorOutput "포트: $Port" "White"
Write-ColorOutput "URL: http://localhost:$Port" "Green"
Write-Host ""
Write-ColorOutput "로그인 정보:" "Cyan"
Write-ColorOutput "  사용자명: admin" "Green"
Write-ColorOutput "  비밀번호: N8nAdmin2025!" "Green"
Write-Host ""
Write-ColorOutput "⚠️  이 창을 닫으면 연결이 끊깁니다." "Yellow"
Write-ColorOutput "종료하려면 Ctrl+C를 누르세요." "Yellow"
Write-Host ""
Write-ColorOutput "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
Write-Host ""

# 3초 후 브라우저 자동 열기
Start-Sleep -Seconds 1
Write-ColorOutput "3초 후 브라우저가 자동으로 열립니다..." "Yellow"
Start-Sleep -Seconds 2

# 백그라운드로 브라우저 열기
Start-Process "http://localhost:$Port"

# Port Forward 실행
kubectl port-forward -n n8n svc/n8n "${Port}:80"

# Port Forward 종료 후 정리
Write-Host ""
Write-ColorOutput "Port Forward가 종료되었습니다." "Yellow"
