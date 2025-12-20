#!/bin/bash
# N8N 빠른 시작 스크립트 (Linux/macOS)
# Port Forward를 시작하고 브라우저를 엽니다

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 포트 파라미터
PORT=${1:-5678}

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}          N8N 빠른 시작 스크립트         ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# kubectl 확인
echo -e "${YELLOW}kubectl 확인 중...${NC}"
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl이 설치되어 있지 않습니다.${NC}"
    echo -e "${YELLOW}kubectl을 설치 후 다시 시도하세요.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ kubectl 확인 완료: $(which kubectl)${NC}"

# Kubernetes 컨텍스트 확인
echo -e "\n${YELLOW}Kubernetes 컨텍스트 확인 중...${NC}"
CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
if [ -z "$CONTEXT" ]; then
    echo -e "${RED}❌ Kubernetes 컨텍스트를 확인할 수 없습니다.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 현재 컨텍스트: $CONTEXT${NC}"

# N8N Pod 상태 확인
echo -e "\n${YELLOW}N8N Pod 상태 확인 중...${NC}"
POD_STATUS=$(kubectl get pods -n n8n -l app=n8n -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "")

if [ -z "$POD_STATUS" ]; then
    echo -e "${RED}❌ N8N Pod를 찾을 수 없습니다.${NC}"
    echo -e "${YELLOW}먼저 N8N을 배포하세요.${NC}"
    exit 1
fi

if [ "$POD_STATUS" != "Running" ]; then
    echo -e "${YELLOW}⚠️  N8N Pod가 Running 상태가 아닙니다: $POD_STATUS${NC}"
    echo -e "${YELLOW}Pod가 시작될 때까지 기다리는 중...${NC}"

    # Pod가 Running 상태가 될 때까지 대기 (최대 60초)
    TIMEOUT=60
    ELAPSED=0
    while [ "$POD_STATUS" != "Running" ] && [ $ELAPSED -lt $TIMEOUT ]; do
        sleep 5
        ELAPSED=$((ELAPSED + 5))
        POD_STATUS=$(kubectl get pods -n n8n -l app=n8n -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "")
        echo -n "."
    done
    echo ""

    if [ "$POD_STATUS" != "Running" ]; then
        echo -e "${RED}❌ Pod가 시작되지 않았습니다. 수동으로 확인하세요:${NC}"
        echo -e "${YELLOW}   kubectl get pods -n n8n${NC}"
        echo -e "${YELLOW}   kubectl logs -n n8n deployment/n8n${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ N8N Pod: Running${NC}"

# 포트 사용 중 확인
echo -e "\n${YELLOW}포트 $PORT 사용 중 확인...${NC}"
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    PID=$(lsof -Pi :$PORT -sTCP:LISTEN -t)
    PROCESS=$(ps -p $PID -o comm= || echo "unknown")

    echo -e "${YELLOW}⚠️  포트 $PORT 가 이미 사용 중입니다.${NC}"
    echo -e "${YELLOW}   프로세스: $PROCESS (PID: $PID)${NC}"
    echo ""

    read -p "프로세스를 종료하고 계속하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kill -9 $PID 2>/dev/null || true
        echo -e "${GREEN}✓ 프로세스 종료됨${NC}"
        sleep 2
    else
        echo -e "${YELLOW}다른 포트를 사용하세요:${NC}"
        echo -e "${GREEN}   ./start-n8n.sh 3000${NC}"
        echo -e "${GREEN}   ./start-n8n.sh 9000${NC}"
        exit 0
    fi
fi

echo -e "${GREEN}✓ 포트 $PORT 사용 가능${NC}"

# Port Forward 시작
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Port Forward를 시작합니다...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "포트: ${PORT}"
echo -e "${GREEN}URL: http://localhost:${PORT}${NC}"
echo ""
echo -e "${CYAN}로그인 정보:${NC}"
echo -e "${GREEN}  사용자명: admin${NC}"
echo -e "${GREEN}  비밀번호: N8nAdmin2025!${NC}"
echo ""
echo -e "${YELLOW}⚠️  이 창을 닫으면 연결이 끊깁니다.${NC}"
echo -e "${YELLOW}종료하려면 Ctrl+C를 누르세요.${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 브라우저 자동 열기
echo -e "${YELLOW}3초 후 브라우저가 자동으로 열립니다...${NC}"
sleep 3

# OS에 따라 브라우저 열기
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    open "http://localhost:${PORT}" &
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    xdg-open "http://localhost:${PORT}" &
fi

# Port Forward 실행
kubectl port-forward -n n8n svc/n8n "${PORT}:80"

# Port Forward 종료 후 정리
echo ""
echo -e "${YELLOW}Port Forward가 종료되었습니다.${NC}"
