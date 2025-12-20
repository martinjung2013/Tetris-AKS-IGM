# N8N 빠른 시작 가이드 🚀

**버전**: 2.0
**최종 업데이트**: 2024-12-20

## ✅ 사전 준비 완료 확인

- [x] N8N Pod: Running
- [x] PostgreSQL: 연결됨
- [x] Public IP: 4.217.223.153 할당됨
- [x] 방화벽 규칙: 포트 5678, 3000, 30678 허용됨
- [x] kubectl: 설치 및 AKS 연결됨
- [x] **외부 접속**: 인터넷에서 접근 가능 ✅

## 🌍 가장 쉬운 방법: 인터넷 접속 (권장) ⭐

### 브라우저에서 바로 접속

```
http://4.217.223.153
```

**로그인**:
- 사용자명: `admin`
- 비밀번호: `N8nAdmin2025!`

✅ 완료! 설정 없이 바로 사용할 수 있습니다.

---

## 💻 로컬 개발 환경 (Port Forward)

### 3단계로 시작하기

### 1단계: Port Forward 시작

**PowerShell 또는 CMD를 열고:**

```bash
kubectl port-forward -n n8n svc/n8n 5678:80
```

**출력 예시:**
```
Forwarding from 127.0.0.1:5678 -> 5678
Forwarding from [::1]:5678 -> 5678
```

✅ **이 창은 열어두세요!** (닫으면 연결이 끊김)

### 2단계: 브라우저 접속

새 브라우저 탭에서 다음 주소로 이동:

```
http://localhost:5678
```

### 3단계: 로그인

**로그인 정보:**
- **사용자명**: `admin`
- **비밀번호**: `N8nAdmin2025!`

## 🎉 완료!

N8N 대시보드가 표시되면 성공입니다.

---

## 📝 추가 정보

### 다른 포트 사용하기

**포트 8080이 ArgoCD에서 사용 중이므로 사용할 수 없습니다.**

**포트 3000 사용:**
```bash
kubectl port-forward -n n8n svc/n8n 3000:80
# 접속: http://localhost:3000
```

**포트 9000 사용:**
```bash
kubectl port-forward -n n8n svc/n8n 9000:80
# 접속: http://localhost:9000
```

### Port Forward 종료

Port Forward를 중지하려면:
- **Ctrl + C** 키를 누르세요
- 또는 PowerShell 창을 닫으세요

### 문제 해결

**"connection refused" 오류:**
1. N8N Pod 상태 확인:
   ```bash
   kubectl get pods -n n8n
   ```

2. Pod 로그 확인:
   ```bash
   kubectl logs -n n8n deployment/n8n
   ```

**포트가 이미 사용 중:**
1. 다른 포트로 시도 (3000 또는 9000)
2. 사용 중인 프로세스 확인:
   ```powershell
   Get-NetTCPConnection -LocalPort 5678
   ```

**방화벽 차단:**
- 자동 설정 스크립트 실행:
  ```powershell
  cd d:\IGM\aks
  .\scripts\configure-firewall.ps1
  ```

## 🔗 관련 문서

- **상세 접속 가이드**: [N8N-CONNECTION-INFO.md](N8N-CONNECTION-INFO.md)
- **방화벽 설정**: [FIREWALL-SETUP.md](FIREWALL-SETUP.md)
- **Private Access**: [PRIVATE-ACCESS-SETUP.md](PRIVATE-ACCESS-SETUP.md)
- **전체 가이드**: [N8N-ACCESS-GUIDE.md](N8N-ACCESS-GUIDE.md)

## 💡 팁

### 백그라운드에서 Port Forward 실행

```powershell
# 새 PowerShell 창에서 실행
Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward -n n8n svc/n8n 5678:80"
```

### 자동으로 브라우저 열기

```powershell
# Port Forward 시작 후 브라우저 자동 열기
kubectl port-forward -n n8n svc/n8n 5678:80 &
Start-Sleep -Seconds 3
Start-Process "http://localhost:5678"
```

### 연결 상태 확인

```bash
# N8N Health Check
curl http://localhost:5678/healthz

# 또는 PowerShell
Invoke-WebRequest http://localhost:5678/healthz
```

---

**문제가 발생하면**: [FIREWALL-SETUP.md](FIREWALL-SETUP.md)의 문제 해결 섹션을 참조하세요.
