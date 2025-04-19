#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Công cụ khắc phục vấn đề SSL cho QR Code Generator ===${NC}"
echo -e "${YELLOW}Đang kiểm tra cấu hình hiện tại...${NC}"

# Kiểm tra file .env
if [ ! -f .env ]; then
  echo -e "${RED}Không tìm thấy file .env. Vui lòng chạy script setup.sh trước.${NC}"
  exit 1
fi

# Đọc cấu hình hiện tại
CURRENT_DOMAIN=$(grep "DOMAIN=" .env | cut -d= -f2)
CURRENT_EMAIL=$(grep "EMAIL=" .env | cut -d= -f2)
CURRENT_HTTP_PORT=$(grep "HTTP_PORT=" .env | cut -d= -f2 || echo "80")
CURRENT_HTTPS_PORT=$(grep "HTTPS_PORT=" .env | cut -d= -f2 || echo "443")

echo -e "${YELLOW}Cấu hình hiện tại:${NC}"
echo -e "Domain: ${GREEN}$CURRENT_DOMAIN${NC}"
echo -e "Email: ${GREEN}$CURRENT_EMAIL${NC}"
echo -e "HTTP Port: ${GREEN}$CURRENT_HTTP_PORT${NC}"
echo -e "HTTPS Port: ${GREEN}$CURRENT_HTTPS_PORT${NC}"

# Kiểm tra domain
if [ "$CURRENT_DOMAIN" = "yourdomain.com" ]; then
  echo -e "${RED}Domain chưa được cấu hình đúng. Vẫn đang sử dụng giá trị mặc định 'yourdomain.com'.${NC}"
  read -p "Nhập domain thực tế của bạn (ví dụ: qrcode.danhtrong.com): " NEW_DOMAIN
  if [ -z "$NEW_DOMAIN" ]; then
    echo -e "${RED}Domain không được để trống.${NC}"
    exit 1
  fi
  # Cập nhật domain trong .env
  sed -i.bak "s/DOMAIN=.*/DOMAIN=$NEW_DOMAIN/" .env
  echo -e "${GREEN}Đã cập nhật domain thành $NEW_DOMAIN${NC}"
  CURRENT_DOMAIN=$NEW_DOMAIN
else
  echo -e "${GREEN}Domain đã được cấu hình.${NC}"
fi

# Kiểm tra email
if [ "$CURRENT_EMAIL" = "your-email@example.com" ]; then
  echo -e "${RED}Email chưa được cấu hình đúng. Vẫn đang sử dụng giá trị mặc định 'your-email@example.com'.${NC}"
  read -p "Nhập email của bạn cho Let's Encrypt: " NEW_EMAIL
  if [ -z "$NEW_EMAIL" ]; then
    echo -e "${RED}Email không được để trống.${NC}"
    exit 1
  fi
  # Cập nhật email trong .env
  sed -i.bak "s/EMAIL=.*/EMAIL=$NEW_EMAIL/" .env
  echo -e "${GREEN}Đã cập nhật email thành $NEW_EMAIL${NC}"
else
  echo -e "${GREEN}Email đã được cấu hình.${NC}"
fi

# Kiểm tra kết nối đến domain
echo -e "${YELLOW}Đang kiểm tra kết nối đến domain $CURRENT_DOMAIN...${NC}"
if command -v curl >/dev/null 2>&1; then
  # Kiểm tra DNS
  echo -e "${YELLOW}Kiểm tra DNS...${NC}"
  DOMAIN_IP=$(dig +short $CURRENT_DOMAIN)
  if [ -z "$DOMAIN_IP" ]; then
    echo -e "${RED}Không thể phân giải DNS cho domain $CURRENT_DOMAIN.${NC}"
    echo -e "${YELLOW}Vui lòng kiểm tra cấu hình DNS của bạn và đảm bảo domain trỏ đến IP của máy chủ.${NC}"
  else
    echo -e "${GREEN}DNS phân giải thành công: $CURRENT_DOMAIN -> $DOMAIN_IP${NC}"
    
    # Kiểm tra IP của máy chủ
    SERVER_IP=$(curl -s ifconfig.me)
    echo -e "${YELLOW}IP của máy chủ này: $SERVER_IP${NC}"
    
    if [ "$DOMAIN_IP" != "$SERVER_IP" ]; then
      echo -e "${RED}Cảnh báo: IP của domain ($DOMAIN_IP) không khớp với IP của máy chủ ($SERVER_IP).${NC}"
      echo -e "${YELLOW}Let's Encrypt sẽ không thể xác thực domain nếu nó không trỏ đến máy chủ này.${NC}"
    else
      echo -e "${GREEN}IP của domain khớp với IP của máy chủ.${NC}"
    fi
  fi
  
  # Kiểm tra kết nối HTTP
  echo -e "${YELLOW}Kiểm tra kết nối HTTP...${NC}"
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$CURRENT_DOMAIN:$CURRENT_HTTP_PORT || echo "failed")
  if [ "$HTTP_STATUS" = "failed" ]; then
    echo -e "${RED}Không thể kết nối đến http://$CURRENT_DOMAIN:$CURRENT_HTTP_PORT${NC}"
    echo -e "${YELLOW}Vui lòng kiểm tra:${NC}"
    echo -e "1. Tường lửa có mở port $CURRENT_HTTP_PORT không?"
    echo -e "2. Nếu bạn đang sử dụng NAT, port forwarding đã được cấu hình chưa?"
    echo -e "3. Có dịch vụ nào khác đang sử dụng port $CURRENT_HTTP_PORT không?"
  else
    echo -e "${GREEN}Kết nối HTTP thành công (Status: $HTTP_STATUS)${NC}"
  fi
else
  echo -e "${YELLOW}Không tìm thấy lệnh curl. Bỏ qua kiểm tra kết nối.${NC}"
fi

# Kiểm tra cấu hình Docker
echo -e "${YELLOW}Kiểm tra cấu hình Docker...${NC}"
if [ ! -f docker-compose.yml ]; then
  echo -e "${RED}Không tìm thấy file docker-compose.yml${NC}"
  exit 1
fi

# Kiểm tra thư mục traefik
if [ ! -d traefik/config ] || [ ! -d traefik/letsencrypt ]; then
  echo -e "${YELLOW}Tạo thư mục traefik...${NC}"
  mkdir -p traefik/config traefik/letsencrypt
  chmod 600 traefik/letsencrypt
  echo -e "${GREEN}Đã tạo thư mục traefik${NC}"
fi

# Kiểm tra quyền truy cập
echo -e "${YELLOW}Kiểm tra quyền truy cập...${NC}"
if [ ! -w traefik/letsencrypt ]; then
  echo -e "${RED}Không có quyền ghi vào thư mục traefik/letsencrypt${NC}"
  echo -e "${YELLOW}Đang cấp quyền...${NC}"
  chmod -R 600 traefik/letsencrypt
  echo -e "${GREEN}Đã cấp quyền${NC}"
fi

# Khởi động lại dịch vụ
echo -e "${YELLOW}Bạn có muốn khởi động lại dịch vụ không? (y/n)${NC}"
read -p "" RESTART
if [ "$RESTART" = "y" ]; then
  echo -e "${YELLOW}Đang dừng các container đang chạy...${NC}"
  docker-compose down
  
  echo -e "${YELLOW}Đang khởi động lại dịch vụ...${NC}"
  docker-compose up -d
  
  echo -e "${GREEN}Dịch vụ đã được khởi động lại.${NC}"
  echo -e "${YELLOW}Để kiểm tra logs, chạy:${NC}"
  echo -e "${GREEN}docker-compose logs${NC}"
fi

echo -e "${BLUE}=== Hoàn tất kiểm tra ===${NC}"
echo -e "${YELLOW}Nếu vẫn gặp vấn đề với SSL, vui lòng kiểm tra:${NC}"
echo -e "1. Domain $CURRENT_DOMAIN có trỏ đúng đến IP của máy chủ không?"
echo -e "2. Port $CURRENT_HTTP_PORT và $CURRENT_HTTPS_PORT có mở không?"
echo -e "3. Nếu bạn đang sử dụng NAT hoặc proxy, đã cấu hình đúng chưa?"
echo -e "4. Kiểm tra logs của Traefik: ${GREEN}docker-compose logs traefik${NC}"
echo -e "5. Nếu bạn chỉ muốn chạy ở môi trường local, hãy sử dụng: ${GREEN}./local.sh${NC}"