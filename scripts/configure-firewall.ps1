# N8N 포트 방화벽 설정 스크립트
# 관리자 권한으로 실행 필요

# 스크립트 시작
Write-Host "N8N 포트 방화벽 설정을 시작합니다..." -ForegroundColor Cyan

# 관리자 권한 확인
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️  이 스크립트는 관리자 권한이 필요합니다." -ForegroundColor Red
    Write-Host "PowerShell을 관리자 권한으로 다시 실행해주세요." -ForegroundColor Yellow
    exit 1
}

# 포트 목록
$ports = @{
    "5678" = "N8N Default Port"
    "3000" = "N8N Alternative Port 1"
    "9000" = "N8N Alternative Port 2"
}

# 기존 규칙 확인 및 삭제
Write-Host "`n기존 N8N 방화벽 규칙 확인 중..." -ForegroundColor Cyan
foreach ($port in $ports.Keys) {
    $ruleName = "N8N Port $port"
    $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

    if ($existingRule) {
        Write-Host "기존 규칙 '$ruleName' 발견. 삭제 중..." -ForegroundColor Yellow
        Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
        Write-Host "✓ 기존 규칙 삭제 완료" -ForegroundColor Green
    }
}

# 새로운 방화벽 규칙 생성
Write-Host "`n새로운 방화벽 규칙 생성 중..." -ForegroundColor Cyan

foreach ($port in $ports.Keys) {
    $description = $ports[$port]
    $ruleName = "N8N Port $port"

    # Inbound 규칙 (들어오는 연결)
    Write-Host "포트 $port ($description) Inbound 규칙 생성 중..." -ForegroundColor Yellow
    New-NetFirewallRule `
        -DisplayName "$ruleName - Inbound" `
        -Description "Allow inbound traffic on port $port for N8N" `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort $port `
        -Action Allow `
        -Enabled True `
        -Profile Any `
        -ErrorAction Stop | Out-Null
    Write-Host "✓ Inbound 규칙 생성 완료" -ForegroundColor Green

    # Outbound 규칙 (나가는 연결)
    Write-Host "포트 $port ($description) Outbound 규칙 생성 중..." -ForegroundColor Yellow
    New-NetFirewallRule `
        -DisplayName "$ruleName - Outbound" `
        -Description "Allow outbound traffic on port $port for N8N" `
        -Direction Outbound `
        -Protocol TCP `
        -LocalPort $port `
        -Action Allow `
        -Enabled True `
        -Profile Any `
        -ErrorAction Stop | Out-Null
    Write-Host "✓ Outbound 규칙 생성 완료" -ForegroundColor Green
}

# 방화벽 규칙 확인
Write-Host "`n생성된 방화벽 규칙 확인:" -ForegroundColor Cyan
Get-NetFirewallRule | Where-Object { $_.DisplayName -like "N8N Port*" } |
    Select-Object DisplayName, Enabled, Direction, Action |
    Format-Table -AutoSize

# 포트 사용 중 확인
Write-Host "`n현재 LISTEN 상태인 포트 확인:" -ForegroundColor Cyan
$listeningPorts = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object { $_.LocalPort -in @(5678, 3000, 8080, 9000) } |
    Select-Object LocalAddress, LocalPort, State,
        @{Name="Process";Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}}

if ($listeningPorts) {
    $listeningPorts | Format-Table -AutoSize
} else {
    Write-Host "5678, 3000, 9000 포트는 현재 사용 중이지 않습니다." -ForegroundColor Yellow
    Write-Host "Port Forward를 시작하면 포트가 활성화됩니다." -ForegroundColor Yellow
}

# 프록시 설정 확인
Write-Host "`n프록시 설정 확인:" -ForegroundColor Cyan
$proxySettings = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue

if ($proxySettings.ProxyEnable -eq 1) {
    Write-Host "⚠️  프록시가 활성화되어 있습니다:" -ForegroundColor Yellow
    Write-Host "   프록시 서버: $($proxySettings.ProxyServer)" -ForegroundColor Yellow
    Write-Host "   예외: $($proxySettings.ProxyOverride)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "localhost 접근이 차단될 수 있습니다. 다음 예외를 추가하세요:" -ForegroundColor Cyan
    Write-Host "   localhost;127.0.0.1;<local>" -ForegroundColor Green
} else {
    Write-Host "✓ 프록시가 비활성화되어 있습니다." -ForegroundColor Green
}

# kubectl port-forward 테스트 가능 여부 확인
Write-Host "`nkubectl 설치 확인:" -ForegroundColor Cyan
$kubectlPath = Get-Command kubectl -ErrorAction SilentlyContinue

if ($kubectlPath) {
    Write-Host "✓ kubectl이 설치되어 있습니다: $($kubectlPath.Source)" -ForegroundColor Green

    # Kubernetes 컨텍스트 확인
    Write-Host "`nKubernetes 컨텍스트 확인:" -ForegroundColor Cyan
    try {
        $context = kubectl config current-context 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ 현재 컨텍스트: $context" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Kubernetes 컨텍스트가 설정되지 않았습니다." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Kubernetes 컨텍스트를 확인할 수 없습니다." -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  kubectl이 설치되지 않았습니다." -ForegroundColor Yellow
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✅ 방화벽 설정이 완료되었습니다!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "`n다음 단계:" -ForegroundColor Cyan
Write-Host "1. Port Forward 시작:" -ForegroundColor White
Write-Host "   kubectl port-forward -n n8n svc/n8n 5678:80" -ForegroundColor Green
Write-Host ""
Write-Host "2. 브라우저에서 접속:" -ForegroundColor White
Write-Host "   http://localhost:5678" -ForegroundColor Green
Write-Host ""
Write-Host "3. 로그인 정보:" -ForegroundColor White
Write-Host "   사용자명: admin" -ForegroundColor Green
Write-Host "   비밀번호: N8nAdmin2025!" -ForegroundColor Green
Write-Host ""

# 선택 메뉴
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "추가 작업을 선택하세요:" -ForegroundColor Cyan
Write-Host "1. Port Forward 바로 시작 (포트 5678)" -ForegroundColor White
Write-Host "2. Port Forward 바로 시작 (포트 3000)" -ForegroundColor White
Write-Host "3. 방화벽 규칙만 적용하고 종료" -ForegroundColor White
Write-Host ""
$choice = Read-Host "선택 (1-3)"

switch ($choice) {
    "1" {
        Write-Host "`nPort Forward를 시작합니다 (포트 5678)..." -ForegroundColor Cyan
        Write-Host "종료하려면 Ctrl+C를 누르세요." -ForegroundColor Yellow
        Write-Host ""
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n n8n svc/n8n 5678:80"
        Start-Sleep -Seconds 2
        Write-Host "브라우저를 엽니다: http://localhost:5678" -ForegroundColor Green
        Start-Process "http://localhost:5678"
    }
    "2" {
        Write-Host "`nPort Forward를 시작합니다 (포트 3000)..." -ForegroundColor Cyan
        Write-Host "종료하려면 Ctrl+C를 누르세요." -ForegroundColor Yellow
        Write-Host ""
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n n8n svc/n8n 3000:80"
        Start-Sleep -Seconds 2
        Write-Host "브라우저를 엽니다: http://localhost:3000" -ForegroundColor Green
        Start-Process "http://localhost:3000"
    }
    "3" {
        Write-Host "`n방화벽 규칙만 적용되었습니다." -ForegroundColor Green
        Write-Host "수동으로 Port Forward를 시작해주세요." -ForegroundColor Yellow
    }
    default {
        Write-Host "`n방화벽 규칙만 적용되었습니다." -ForegroundColor Green
    }
}

Write-Host ""
