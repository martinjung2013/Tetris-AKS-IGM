# 방화벽 및 프록시 설정 가이드

**버전**: 2.0
**최종 업데이트**: 2024-12-20

## 개요

N8N에 접근하기 위해 로컬 포트를 열고 방화벽 및 프록시 설정을 구성하는 가이드입니다.

**참고**: Public IP (http://4.217.223.153)를 통한 외부 접속이 활성화되어 있어 방화벽 설정 없이도 인터넷에서 직접 접속 가능합니다. 이 가이드는 Port Forward를 사용하는 로컬 개발 환경에 적용됩니다.

## 포트 정보

| 포트 | 용도 | 상태 | 비고 |
|------|------|------|------|
| 5678 | N8N 기본 포트 | 권장 ✅ | Port Forward 기본 포트 |
| 3000 | N8N 대체 포트 1 | 사용 가능 | Grafana와 충돌 가능성 |
| 8080 | ~~N8N 대체 포트~~ | ❌ 사용 불가 | **ArgoCD 사용 중** |
| 9000 | N8N 대체 포트 2 | 사용 가능 | |

## Windows 방화벽 설정

### 방법 1: 자동 스크립트 실행 (권장)

**관리자 권한으로 PowerShell을 실행하고:**

```powershell
# 스크립트 실행
cd d:\IGM\aks
.\scripts\configure-firewall.ps1
```

스크립트가 자동으로:
- 기존 N8N 방화벽 규칙 확인 및 삭제
- 포트 5678, 3000, 9000에 대한 Inbound/Outbound 규칙 생성
- 프록시 설정 확인
- kubectl 설치 및 컨텍스트 확인
- Port Forward 바로 시작 옵션 제공

### 방법 2: 수동 설정

#### PowerShell 명령어 (관리자 권한 필요)

**1. 포트 5678 허용 (Inbound)**
```powershell
New-NetFirewallRule `
    -DisplayName "N8N Port 5678 - Inbound" `
    -Description "Allow inbound traffic on port 5678 for N8N" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5678 `
    -Action Allow `
    -Enabled True `
    -Profile Any
```

**2. 포트 5678 허용 (Outbound)**
```powershell
New-NetFirewallRule `
    -DisplayName "N8N Port 5678 - Outbound" `
    -Description "Allow outbound traffic on port 5678 for N8N" `
    -Direction Outbound `
    -Protocol TCP `
    -LocalPort 5678 `
    -Action Allow `
    -Enabled True `
    -Profile Any
```

**3. 포트 3000 허용**
```powershell
# Inbound
New-NetFirewallRule -DisplayName "N8N Port 3000 - Inbound" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow -Enabled True -Profile Any

# Outbound
New-NetFirewallRule -DisplayName "N8N Port 3000 - Outbound" -Direction Outbound -Protocol TCP -LocalPort 3000 -Action Allow -Enabled True -Profile Any
```

**4. 포트 9000 허용**
```powershell
# Inbound
New-NetFirewallRule -DisplayName "N8N Port 9000 - Inbound" -Direction Inbound -Protocol TCP -LocalPort 9000 -Action Allow -Enabled True -Profile Any

# Outbound
New-NetFirewallRule -DisplayName "N8N Port 9000 - Outbound" -Direction Outbound -Protocol TCP -LocalPort 9000 -Action Allow -Enabled True -Profile Any
```

#### 방화벽 규칙 확인

```powershell
# N8N 관련 규칙 확인
Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*N8N*" } |
    Select-Object DisplayName, Enabled, Direction, Action |
    Format-Table -AutoSize
```

#### 방화벽 규칙 삭제 (필요시)

```powershell
# 특정 규칙 삭제
Remove-NetFirewallRule -DisplayName "N8N Port 5678 - Inbound"
Remove-NetFirewallRule -DisplayName "N8N Port 5678 - Outbound"

# 또는 모든 N8N 규칙 삭제
Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*N8N*" } | Remove-NetFirewallRule
```

### 방법 3: Windows Defender 방화벽 GUI

1. **Windows 보안 센터 열기**
   - Windows 키 → "Windows 보안" 검색

2. **방화벽 및 네트워크 보호**
   - "방화벽 및 네트워크 보호" 클릭

3. **고급 설정**
   - "고급 설정" 클릭

4. **인바운드 규칙 추가**
   - 왼쪽 "인바운드 규칙" 클릭
   - 오른쪽 "새 규칙..." 클릭
   - 규칙 유형: "포트" 선택
   - 프로토콜: TCP
   - 특정 로컬 포트: `5678, 3000, 9000` 입력
   - 작업: "연결 허용"
   - 프로필: 모두 선택
   - 이름: "N8N Ports"

5. **아웃바운드 규칙 추가**
   - 동일한 방법으로 "아웃바운드 규칙" 추가

## Linux 방화벽 설정

### 자동 스크립트 실행 (권장)

```bash
# 스크립트 실행 권한 부여
chmod +x scripts/configure-firewall.sh

# 스크립트 실행 (sudo 필요)
sudo ./scripts/configure-firewall.sh
```

### ufw (Ubuntu/Debian)

```bash
# 포트 허용
sudo ufw allow 5678/tcp comment "N8N Default Port"
sudo ufw allow 3000/tcp comment "N8N Alternative Port"
sudo ufw allow 9000/tcp comment "N8N Alternative Port"

# 상태 확인
sudo ufw status

# 규칙 확인
sudo ufw status numbered
```

### iptables (CentOS/RHEL)

```bash
# 포트 허용
sudo iptables -A INPUT -p tcp --dport 5678 -j ACCEPT -m comment --comment "N8N Default Port"
sudo iptables -A OUTPUT -p tcp --sport 5678 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 3000 -j ACCEPT -m comment --comment "N8N Alt Port 1"
sudo iptables -A INPUT -p tcp --dport 9000 -j ACCEPT -m comment --comment "N8N Alt Port 2"

# 규칙 저장
sudo service iptables save

# 또는 (systemd)
sudo iptables-save > /etc/iptables/rules.v4
```

### firewalld (Fedora/RHEL 7+)

```bash
# 포트 허용
sudo firewall-cmd --permanent --add-port=5678/tcp
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --permanent --add-port=9000/tcp

# 재로드
sudo firewall-cmd --reload

# 확인
sudo firewall-cmd --list-ports
```

## macOS 방화벽 설정

macOS는 기본적으로 localhost 연결을 허용하므로 추가 설정이 필요하지 않습니다.

### 확인 (선택사항)

```bash
# 방화벽 상태 확인
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# 특정 앱 허용 (필요시)
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/bin/kubectl
```

## 프록시 설정

### Windows 프록시 확인

**PowerShell:**
```powershell
# 프록시 설정 확인
Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' |
    Select-Object ProxyEnable, ProxyServer, ProxyOverride
```

**프록시가 활성화되어 있는 경우:**
```powershell
# localhost 예외 추가
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' `
    -Name ProxyOverride -Value "localhost;127.0.0.1;<local>"
```

### 환경 변수 확인

```powershell
# Windows (PowerShell)
$env:HTTP_PROXY
$env:HTTPS_PROXY
$env:NO_PROXY

# Linux/macOS (Bash)
echo $HTTP_PROXY
echo $HTTPS_PROXY
echo $NO_PROXY
```

**localhost를 프록시에서 제외:**

```bash
# Bash (.bashrc 또는 .zshrc)
export NO_PROXY="localhost,127.0.0.1"

# PowerShell ($PROFILE)
$env:NO_PROXY = "localhost,127.0.0.1"
```

### kubectl 프록시 설정

kubectl은 시스템 프록시 설정을 따르므로, localhost는 제외해야 합니다.

```bash
# kubectl 프록시 우회 설정
export NO_PROXY="localhost,127.0.0.1,.cluster.local,.svc"
```

## 포트 사용 확인

### Windows

```powershell
# LISTEN 상태 포트 확인
Get-NetTCPConnection -State Listen |
    Where-Object { $_.LocalPort -in @(5678, 3000, 8080, 9000) } |
    Select-Object LocalAddress, LocalPort, State,
        @{Name="Process";Expression={(Get-Process -Id $_.OwningProcess).ProcessName}} |
    Format-Table -AutoSize

# 또는 netstat
netstat -ano | findstr ":5678 :3000 :9000"
```

### Linux/macOS

```bash
# netstat
netstat -tuln | grep -E ":(5678|3000|9000) "

# 또는 ss
ss -tuln | grep -E ":(5678|3000|9000) "

# 또는 lsof
lsof -i :5678
lsof -i :3000
lsof -i :9000
```

## 연결 테스트

### Port Forward 시작 전 테스트

```powershell
# Windows
Test-NetConnection -ComputerName localhost -Port 5678

# Linux/macOS
nc -zv localhost 5678
```

### Port Forward 시작 후 테스트

```bash
# HTTP 요청 테스트
curl http://localhost:5678/healthz

# 또는 PowerShell
Invoke-WebRequest -Uri http://localhost:5678/healthz
```

## 문제 해결

### 포트가 이미 사용 중

```powershell
# Windows: 포트 사용 중인 프로세스 확인
Get-Process -Id (Get-NetTCPConnection -LocalPort 5678).OwningProcess

# 프로세스 종료 (주의!)
Stop-Process -Id <PROCESS_ID> -Force
```

```bash
# Linux/macOS: 포트 사용 중인 프로세스 확인
lsof -ti:5678

# 프로세스 종료
kill -9 $(lsof -ti:5678)
```

### 방화벽 규칙이 적용되지 않음

```powershell
# Windows: 방화벽 서비스 재시작
Restart-Service mpssvc

# Linux: 방화벽 재시작
sudo systemctl restart firewalld  # firewalld
sudo systemctl restart ufw        # ufw
```

### kubectl port-forward 연결 실패

1. **Kubernetes 컨텍스트 확인**
   ```bash
   kubectl config current-context
   kubectl get pods -n n8n
   ```

2. **Pod 상태 확인**
   ```bash
   kubectl get pods -n n8n
   kubectl logs -n n8n deployment/n8n
   ```

3. **네트워크 연결 확인**
   ```bash
   kubectl cluster-info
   ```

### 브라우저에서 연결 거부

1. **Port Forward가 실행 중인지 확인**
2. **방화벽 규칙 확인**
3. **프록시 설정 확인**
4. **브라우저 캐시 삭제**
5. **다른 브라우저로 시도**

## 보안 권장사항

1. **필요한 포트만 열기**
   - 사용하지 않는 포트는 닫아두기

2. **localhost만 허용**
   - 외부 IP에서의 접근 차단
   - Port Forward는 기본적으로 localhost만 바인딩

3. **Port Forward 종료**
   - 사용 후 Port Forward 프로세스 종료
   - Ctrl+C 또는 프로세스 Kill

4. **방화벽 로깅**
   - 의심스러운 연결 시도 모니터링

## 빠른 시작 명령어

### 포트 5678 사용

```bash
# 1. Port Forward 시작
kubectl port-forward -n n8n svc/n8n 5678:80

# 2. 새 터미널에서 테스트
curl http://localhost:5678/healthz

# 3. 브라우저 접속
# http://localhost:5678
```

### 포트 3000 사용

```bash
# Port Forward
kubectl port-forward -n n8n svc/n8n 3000:80

# 브라우저 접속
# http://localhost:3000
```

## 관련 문서

- [N8N-CONNECTION-INFO.md](N8N-CONNECTION-INFO.md) - N8N 접속 정보
- [N8N-ACCESS-GUIDE.md](N8N-ACCESS-GUIDE.md) - 전체 접속 방법
- [PRIVATE-ACCESS-SETUP.md](PRIVATE-ACCESS-SETUP.md) - Private Access 설정

---

**버전**: 2.0
**최종 업데이트**: 2024-12-20
**적용 대상**: Port Forward 사용 시 로컬 방화벽 설정
