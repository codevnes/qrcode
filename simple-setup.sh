#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Cài đặt đơn giản cho QR Code Generator ===${NC}"

# Kiểm tra Docker
if ! command -v docker >/dev/null 2>&1; then
  echo -e "${RED}Docker chưa được cài đặt. Vui lòng cài đặt Docker trước.${NC}"
  echo -e "Truy cập https://docs.docker.com/get-docker/ để xem hướng dẫn cài đặt."
  exit 1
fi

if ! command -v docker-compose >/dev/null 2>&1; then
  if command -v docker && docker compose version >/dev/null 2>&1; then
    echo -e "${GREEN}Đã phát hiện Docker Compose plugin.${NC}"
  else
    echo -e "${RED}Docker Compose chưa được cài đặt. Vui lòng cài đặt Docker Compose trước.${NC}"
    echo -e "Truy cập https://docs.docker.com/compose/install/ để xem hướng dẫn cài đặt."
    exit 1
  fi
fi

# Kiểm tra file .env
if [ ! -f .env ]; then
  echo -e "${YELLOW}Tạo file .env...${NC}"
  touch .env
else
  echo -e "${YELLOW}Cập nhật file .env hiện có...${NC}"
fi

# Nhập cổng HTTP
read -p "Nhập cổng HTTP [80]: " HTTP_PORT
HTTP_PORT=${HTTP_PORT:-80}

# Nhập cổng ứng dụng
read -p "Nhập cổng ứng dụng [3000]: " PORT
PORT=${PORT:-3000}

# Cập nhật file .env
cat > .env << EOF
# Cấu hình cổng
HTTP_PORT=$HTTP_PORT
PORT=$PORT
EOF

echo -e "${GREEN}Đã lưu cấu hình vào file .env.${NC}"

# Kiểm tra cổng đang sử dụng
if command -v lsof >/dev/null 2>&1; then
  HTTP_PORT_CHECK=$(lsof -i :$HTTP_PORT | grep LISTEN)

  if [ ! -z "$HTTP_PORT_CHECK" ]; then
    echo -e "${YELLOW}Cảnh báo: Cổng $HTTP_PORT có thể đang được sử dụng.${NC}"
    echo -e "${YELLOW}Nếu bạn đang chạy OpenLiteSpeed hoặc dịch vụ web khác, bạn cần dừng nó hoặc sử dụng cổng khác.${NC}"
    read -p "Bạn có muốn tiếp tục không? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ]; then
      exit 1
    fi
  fi
fi

echo -e "${GREEN}Cài đặt hoàn tất!${NC}"
echo -e "${YELLOW}Để khởi động ứng dụng, chạy:${NC}"
echo -e "${GREEN}docker-compose -f docker-compose.simple.yml up -d${NC}"
echo -e "${YELLOW}Để dừng ứng dụng, chạy:${NC}"
echo -e "${GREEN}docker-compose -f docker-compose.simple.yml down${NC}"