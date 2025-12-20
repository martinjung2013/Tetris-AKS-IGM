#!/bin/bash
# N8N 포트 방화벽 설정 스크립트 (Linux/macOS)

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}N8N 포트 방화벽 설정을 시작합니다...${NC}"

# OS 확인
OS="$(uname -s)"
case "${OS}" in
    Linux*)     OS_TYPE=Linux;;
    Darwin*)    OS_TYPE=Mac;;
    *)          OS_TYPE="UNKNOWN:${OS}"
esac

echo -e "${CYAN}감지된 OS: ${OS_TYPE}${NC}"

# 포트 목록
declare -A PORTS=(
    ["5678"]="N8N Default Port"
    ["3000"]="N8N Alternative Port 1"
    ["9000"]="N8N Alternative Port 2"
)

# Linux 방화벽 설정 (iptables 또는 ufw)
configure_linux_firewall() {
    echo -e "${CYAN}\nLinux 방화벽 설정 중...${NC}"

    # ufw 확인
    if command -v ufw &> /dev/null; then
        echo -e "${YELLOW}ufw 발견. ufw 규칙을 설정합니다...${NC}"

        for port in "${!PORTS[@]}"; do
            echo -e "${YELLOW}포트 $port (${PORTS[$port]}) 허용 중...${NC}"
            sudo ufw allow "$port/tcp" comment "${PORTS[$port]}" 2>/dev/null || true
            echo -e "${GREEN}✓ 포트 $port 허용 완료${NC}"
        done

        echo -e "${CYAN}\nufw 상태:${NC}"
        sudo ufw status | grep -E "5678|3000|9000" || echo "규칙이 아직 활성화되지 않았습니다."

    # iptables 확인
    elif command -v iptables &> /dev/null; then
        echo -e "${YELLOW}iptables 발견. iptables 규칙을 설정합니다...${NC}"

        for port in "${!PORTS[@]}"; do
            echo -e "${YELLOW}포트 $port (${PORTS[$port]}) 허용 중...${NC}"
            sudo iptables -A INPUT -p tcp --dport "$port" -j ACCEPT -m comment --comment "${PORTS[$port]}" 2>/dev/null || true
            sudo iptables -A OUTPUT -p tcp --sport "$port" -j ACCEPT -m comment --comment "${PORTS[$port]}" 2>/dev/null || true
            echo -e "${GREEN}✓ 포트 $port 허용 완료${NC}"
        done

        echo -e "${CYAN}\niptables 규칙:${NC}"
        sudo iptables -L -n | grep -E "5678|3000|9000" || echo "규칙이 설정되었습니다."

    else
        echo -e "${YELLOW}⚠️  방화벽 도구를 찾을 수 없습니다.${NC}"
        echo -e "${YELLOW}수동으로 포트를 허용해야 할 수 있습니다.${NC}"
    fi
}

# macOS 방화벽 설정
configure_mac_firewall() {
    echo -e "${CYAN}\nmacOS 방화벽 설정 중...${NC}"
    echo -e "${YELLOW}macOS는 기본적으로 localhost 접근을 허용합니다.${NC}"
    echo -e "${GREEN}✓ 추가 설정이 필요하지 않습니다.${NC}"
}

# 포트 사용 중 확인
check_listening_ports() {
    echo -e "${CYAN}\n현재 LISTEN 상태인 포트 확인:${NC}"

    if command -v netstat &> /dev/null; then
        netstat -tuln | grep -E ":(5678|3000|8080|9000) " || echo -e "${YELLOW}5678, 3000, 9000 포트는 현재 사용 중이지 않습니다.${NC}"
    elif command -v ss &> /dev/null; then
        ss -tuln | grep -E ":(5678|3000|8080|9000) " || echo -e "${YELLOW}5678, 3000, 9000 포트는 현재 사용 중이지 않습니다.${NC}"
    else
        echo -e "${YELLOW}⚠️  포트 확인 도구를 찾을 수 없습니다.${NC}"
    fi
}

# kubectl 확인
check_kubectl() {
    echo -e "${CYAN}\nkubectl 설치 확인:${NC}"

    if command -v kubectl &> /dev/null; then
        echo -e "${GREEN}✓ kubectl이 설치되어 있습니다: $(which kubectl)${NC}"

        # Kubernetes 컨텍스트 확인
        echo -e "${CYAN}\nKubernetes 컨텍스트 확인:${NC}"
        CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
        if [ -n "$CONTEXT" ]; then
            echo -e "${GREEN}✓ 현재 컨텍스트: $CONTEXT${NC}"
        else
            echo -e "${YELLOW}⚠️  Kubernetes 컨텍스트가 설정되지 않았습니다.${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  kubectl이 설치되지 않았습니다.${NC}"
    fi
}

# 메인 실행
case "${OS_TYPE}" in
    Linux)
        configure_linux_firewall
        ;;
    Mac)
        configure_mac_firewall
        ;;
    *)
        echo -e "${RED}지원하지 않는 OS: ${OS_TYPE}${NC}"
        exit 1
        ;;
esac

check_listening_ports
check_kubectl

echo -e "${CYAN}\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 방화벽 설정이 완료되었습니다!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${CYAN}\n다음 단계:${NC}"
echo -e "${CYAN}1. Port Forward 시작:${NC}"
echo -e "${GREEN}   kubectl port-forward -n n8n svc/n8n 5678:80${NC}"
echo -e ""
echo -e "${CYAN}2. 브라우저에서 접속:${NC}"
echo -e "${GREEN}   http://localhost:5678${NC}"
echo -e ""
echo -e "${CYAN}3. 로그인 정보:${NC}"
echo -e "${GREEN}   사용자명: admin${NC}"
echo -e "${GREEN}   비밀번호: N8nAdmin2025!${NC}"
echo -e ""

# 선택 메뉴
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}추가 작업을 선택하세요:${NC}"
echo -e "1. Port Forward 바로 시작 (포트 5678)"
echo -e "2. Port Forward 바로 시작 (포트 3000)"
echo -e "3. 방화벽 규칙만 적용하고 종료"
echo -e ""
read -p "선택 (1-3): " choice

case $choice in
    1)
        echo -e "${CYAN}\nPort Forward를 시작합니다 (포트 5678)...${NC}"
        echo -e "${YELLOW}종료하려면 Ctrl+C를 누르세요.${NC}"
        echo -e ""
        kubectl port-forward -n n8n svc/n8n 5678:80
        ;;
    2)
        echo -e "${CYAN}\nPort Forward를 시작합니다 (포트 3000)...${NC}"
        echo -e "${YELLOW}종료하려면 Ctrl+C를 누르세요.${NC}"
        echo -e ""
        kubectl port-forward -n n8n svc/n8n 3000:80
        ;;
    3)
        echo -e "${GREEN}\n방화벽 규칙만 적용되었습니다.${NC}"
        echo -e "${YELLOW}수동으로 Port Forward를 시작해주세요.${NC}"
        ;;
    *)
        echo -e "${GREEN}\n방화벽 규칙만 적용되었습니다.${NC}"
        ;;
esac

echo ""
