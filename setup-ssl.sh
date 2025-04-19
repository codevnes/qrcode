#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Cài đặt SSL cho QR Code Generator ===${NC}"

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

# Kiểm tra email
read -p "Nhập email của bạn cho Let's Encrypt (để nhận thông báo): " EMAIL
if [ -z "$EMAIL" ]; then
  echo -e "${RED}Email không được để trống.${NC}"
  exit 1
fi

# Tạo thư mục cần thiết
echo -e "${YELLOW}Tạo thư mục cần thiết...${NC}"
mkdir -p nginx/conf.d nginx/ssl nginx/certbot/conf nginx/certbot/www

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

# Tạo file cấu hình Nginx tạm thời cho việc xác thực SSL
echo -e "${YELLOW}Tạo cấu hình Nginx tạm thời...${NC}"
cat > nginx/conf.d/qrcode.danhtrong.com.conf << EOF
server {
    listen 80;
    server_name $DOMAIN;
    server_tokens off;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name $DOMAIN;
    server_tokens off;

    # Các chứng chỉ SSL sẽ được tạo sau
    ssl_certificate /etc/nginx/ssl/dummy.crt;
    ssl_certificate_key /etc/nginx/ssl/dummy.key;

    location / {
        proxy_pass http://app:2021;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Tạo chứng chỉ SSL giả để Nginx có thể khởi động
echo -e "${YELLOW}Tạo chứng chỉ SSL giả...${NC}"
mkdir -p nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout nginx/ssl/dummy.key -out nginx/ssl/dummy.crt -subj "/CN=$DOMAIN"

# Khởi động Nginx
echo -e "${YELLOW}Khởi động Nginx...${NC}"
docker-compose -f docker-compose.ssl.yml up -d nginx

# Chờ Nginx khởi động
echo -e "${YELLOW}Chờ Nginx khởi động...${NC}"
sleep 5

# Lấy chứng chỉ SSL từ Let's Encrypt
echo -e "${YELLOW}Lấy chứng chỉ SSL từ Let's Encrypt...${NC}"
docker-compose -f docker-compose.ssl.yml run --rm certbot certonly --webroot -w /var/www/certbot -d $DOMAIN --email $EMAIL --agree-tos --no-eff-email

# Cập nhật cấu hình Nginx
echo -e "${YELLOW}Cập nhật cấu hình Nginx...${NC}"
cat > nginx/conf.d/qrcode.danhtrong.com.conf << EOF
server {
    listen 80;
    server_name $DOMAIN;
    server_tokens off;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name $DOMAIN;
    server_tokens off;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        proxy_pass http://app:2021;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Khởi động lại Nginx
echo -e "${YELLOW}Khởi động lại Nginx...${NC}"
docker-compose -f docker-compose.ssl.yml exec nginx nginx -s reload

# Khởi động toàn bộ dịch vụ
echo -e "${YELLOW}Khởi động toàn bộ dịch vụ...${NC}"
docker-compose -f docker-compose.ssl.yml up -d

echo -e "${GREEN}Cài đặt SSL hoàn tất!${NC}"
echo -e "${YELLOW}Bạn có thể truy cập ứng dụng tại:${NC}"
echo -e "${GREEN}https://$DOMAIN${NC}"
echo -e "${YELLOW}Chứng chỉ SSL sẽ tự động gia hạn mỗi 3 tháng.${NC}"#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Cài đặt SSL cho QR Code Generator ===${NC}"

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

# Kiểm tra email
read -p "Nhập email của bạn cho Let's Encrypt (để nhận thông báo): " EMAIL
if [ -z "$EMAIL" ]; then
  echo -e "${RED}Email không được để trống.${NC}"
  exit 1
fi

# Tạo thư mục cần thiết
echo -e "${YELLOW}Tạo thư mục cần thiết...${NC}"
mkdir -p nginx/conf.d nginx/ssl nginx/certbot/conf nginx/certbot/www

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

# Tạo file cấu hình Nginx tạm thời cho việc xác thực SSL
echo -e "${YELLOW}Tạo cấu hình Nginx tạm thời...${NC}"
cat > nginx/conf.d/qrcode.danhtrong.com.conf << EOF
server {
    listen 80;
    server_name $DOMAIN;
    server_tokens off;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name $DOMAIN;
    server_tokens off;

    # Các chứng chỉ SSL sẽ được tạo sau
    ssl_certificate /etc/nginx/ssl/dummy.crt;
    ssl_certificate_key /etc/nginx/ssl/dummy.key;

    location / {
        proxy_pass http://app:2021;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Tạo chứng chỉ SSL giả để Nginx có thể khởi động
echo -e "${YELLOW}Tạo chứng chỉ SSL giả...${NC}"
mkdir -p nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout nginx/ssl/dummy.key -out nginx/ssl/dummy.crt -subj "/CN=$DOMAIN"

# Khởi động Nginx
echo -e "${YELLOW}Khởi động Nginx...${NC}"
docker-compose -f docker-compose.ssl.yml up -d nginx

# Chờ Nginx khởi động
echo -e "${YELLOW}Chờ Nginx khởi động...${NC}"
sleep 5

# Lấy chứng chỉ SSL từ Let's Encrypt
echo -e "${YELLOW}Lấy chứng chỉ SSL từ Let's Encrypt...${NC}"
docker-compose -f docker-compose.ssl.yml run --rm certbot certonly --webroot -w /var/www/certbot -d $DOMAIN --email $EMAIL --agree-tos --no-eff-email

# Cập nhật cấu hình Nginx
echo -e "${YELLOW}Cập nhật cấu hình Nginx...${NC}"
cat > nginx/conf.d/qrcode.danhtrong.com.conf << EOF
server {
    listen 80;
    server_name $DOMAIN;
    server_tokens off;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name $DOMAIN;
    server_tokens off;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        proxy_pass http://app:2021;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Khởi động lại Nginx
echo -e "${YELLOW}Khởi động lại Nginx...${NC}"
docker-compose -f docker-compose.ssl.yml exec nginx nginx -s reload

# Khởi động toàn bộ dịch vụ
echo -e "${YELLOW}Khởi động toàn bộ dịch vụ...${NC}"
docker-compose -f docker-compose.ssl.yml up -d

echo -e "${GREEN}Cài đặt SSL hoàn tất!${NC}"
echo -e "${YELLOW}Bạn có thể truy cập ứng dụng tại:${NC}"
echo -e "${GREEN}https://$DOMAIN${NC}"
echo -e "${YELLOW}Chứng chỉ SSL sẽ tự động gia hạn mỗi 3 tháng.${NC}"