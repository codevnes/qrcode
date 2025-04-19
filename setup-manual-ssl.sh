#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Cài đặt SSL thủ công cho QR Code Generator ===${NC}"

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

# Kiểm tra domain
DOMAIN="qrcode.danhtrong.com"
echo -e "${YELLOW}Domain: ${GREEN}$DOMAIN${NC}"

# Tạo thư mục cần thiết
echo -e "${YELLOW}Tạo thư mục cần thiết...${NC}"
mkdir -p nginx/conf.d nginx/ssl

# Kiểm tra cổng đang sử dụng
if command -v lsof >/dev/null 2>&1; then
  HTTP_PORT_CHECK=$(lsof -i :80 | grep LISTEN)
  HTTPS_PORT_CHECK=$(lsof -i :443 | grep LISTEN)

  if [ ! -z "$HTTP_PORT_CHECK" ] || [ ! -z "$HTTPS_PORT_CHECK" ]; then
    echo -e "${YELLOW}Cảnh báo: Cổng 80 và/hoặc 443 có thể đang được sử dụng.${NC}"
    echo -e "${YELLOW}Nếu bạn đang chạy dịch vụ web khác, bạn cần dừng nó trước.${NC}"
    read -p "Bạn có muốn tiếp tục không? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ]; then
      exit 1
    fi
  fi
fi

# Hướng dẫn người dùng chuẩn bị chứng chỉ SSL
echo -e "${YELLOW}Để cài đặt SSL thủ công, bạn cần chuẩn bị các file chứng chỉ sau:${NC}"
echo -e "1. ${GREEN}fullchain.pem${NC} - Chứng chỉ SSL đầy đủ bao gồm cả chứng chỉ trung gian"
echo -e "2. ${GREEN}privkey.pem${NC} - Khóa riêng tư của chứng chỉ SSL"
echo -e "${YELLOW}Bạn đã chuẩn bị sẵn các file này chưa? (y/n)${NC}"
read -p "" HAS_CERTS

if [ "$HAS_CERTS" != "y" ]; then
  echo -e "${RED}Vui lòng chuẩn bị các file chứng chỉ SSL trước khi tiếp tục.${NC}"
  exit 1
fi

# Yêu cầu người dùng cung cấp đường dẫn đến các file chứng chỉ
echo -e "${YELLOW}Nhập đường dẫn đầy đủ đến file fullchain.pem:${NC}"
read -p "" FULLCHAIN_PATH

if [ ! -f "$FULLCHAIN_PATH" ]; then
  echo -e "${RED}Không tìm thấy file $FULLCHAIN_PATH${NC}"
  exit 1
fi

echo -e "${YELLOW}Nhập đường dẫn đầy đủ đến file privkey.pem:${NC}"
read -p "" PRIVKEY_PATH

if [ ! -f "$PRIVKEY_PATH" ]; then
  echo -e "${RED}Không tìm thấy file $PRIVKEY_PATH${NC}"
  exit 1
fi

# Tạo thư mục SSL
echo -e "${YELLOW}Tạo thư mục SSL...${NC}"
mkdir -p nginx/ssl/$DOMAIN

# Sao chép các file chứng chỉ
echo -e "${YELLOW}Sao chép các file chứng chỉ...${NC}"
cp "$FULLCHAIN_PATH" nginx/ssl/$DOMAIN/fullchain.pem
cp "$PRIVKEY_PATH" nginx/ssl/$DOMAIN/privkey.pem

# Tạo file cấu hình Nginx
echo -e "${YELLOW}Tạo cấu hình Nginx...${NC}"
cat > nginx/conf.d/qrcode.danhtrong.com.conf << EOF
server {
    listen 80;
    server_name $DOMAIN;
    server_tokens off;

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name $DOMAIN;
    server_tokens off;

    ssl_certificate /etc/nginx/ssl/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/$DOMAIN/privkey.pem;
    
    # Cấu hình SSL tối ưu
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;

    # HSTS (ngx_http_headers_module is required) (63072000 seconds = 2 years)
    add_header Strict-Transport-Security "max-age=63072000" always;

    location / {
        proxy_pass http://app:2021;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Tạo docker-compose.manual-ssl.yml
echo -e "${YELLOW}Tạo file docker-compose.manual-ssl.yml...${NC}"
cat > docker-compose.manual-ssl.yml << EOF
version: '3.8'

services:
  app:
    build: .
    container_name: qr-app
    restart: unless-stopped
    environment:
      - PORT=2021
    expose:
      - "2021"
    networks:
      - qr-network

  nginx:
    image: nginx:alpine
    container_name: qr-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./nginx/ssl:/etc/nginx/ssl
    depends_on:
      - app
    networks:
      - qr-network

networks:
  qr-network:
    name: qr-network
    external: false
EOF

# Khởi động dịch vụ
echo -e "${YELLOW}Khởi động dịch vụ...${NC}"
docker-compose -f docker-compose.manual-ssl.yml up -d

echo -e "${GREEN}Cài đặt SSL thủ công hoàn tất!${NC}"
echo -e "${YELLOW}Bạn có thể truy cập ứng dụng tại:${NC}"
echo -e "${GREEN}https://$DOMAIN${NC}"
echo -e "${YELLOW}Lưu ý: Bạn cần tự gia hạn chứng chỉ SSL khi nó hết hạn.${NC}"
echo -e "${YELLOW}Để kiểm tra ngày hết hạn của chứng chỉ SSL, chạy:${NC}"
echo -e "${GREEN}openssl x509 -in nginx/ssl/$DOMAIN/fullchain.pem -text -noout | grep 'Not After'${NC}"