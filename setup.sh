#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check for required dependencies
echo -e "${YELLOW}Checking dependencies...${NC}"
if ! command_exists docker; then
  echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
  echo -e "Visit https://docs.docker.com/get-docker/ for installation instructions."
  exit 1
fi

if ! command_exists docker-compose; then
  if command_exists docker && docker compose version >/dev/null 2>&1; then
    echo -e "${GREEN}Docker Compose plugin detected.${NC}"
  else
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose first.${NC}"
    echo -e "Visit https://docs.docker.com/compose/install/ for installation instructions."
    exit 1
  fi
fi

# Check if .env file exists, if not create it
if [ ! -f .env ]; then
  echo -e "${YELLOW}Creating .env file...${NC}"
  touch .env
else
  echo -e "${YELLOW}Updating existing .env file...${NC}"
fi

# Get domain
read -p "Enter your domain name (e.g., example.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
  echo -e "${RED}Domain name is required.${NC}"
  exit 1
fi

# Get email for Let's Encrypt
read -p "Enter your email for Let's Encrypt notifications: " EMAIL
if [ -z "$EMAIL" ]; then
  echo -e "${RED}Email is required for Let's Encrypt.${NC}"
  exit 1
fi

# Get HTTP port (default: 80)
read -p "Enter HTTP port [80]: " HTTP_PORT
HTTP_PORT=${HTTP_PORT:-80}

# Get HTTPS port (default: 443)
read -p "Enter HTTPS port [443]: " HTTPS_PORT
HTTPS_PORT=${HTTPS_PORT:-443}

# Get application port (default: 3000)
read -p "Enter application port [3000]: " PORT
PORT=${PORT:-3000}

# Get dashboard port (default: 8080)
read -p "Enter Traefik dashboard port [8080]: " DASHBOARD_PORT
DASHBOARD_PORT=${DASHBOARD_PORT:-8080}

# Generate Traefik auth credentials
read -p "Enter username for Traefik dashboard [admin]: " TRAEFIK_USER
TRAEFIK_USER=${TRAEFIK_USER:-admin}

read -s -p "Enter password for Traefik dashboard [password]: " TRAEFIK_PASSWORD
echo ""
TRAEFIK_PASSWORD=${TRAEFIK_PASSWORD:-password}

# Check if htpasswd is available
if command_exists htpasswd; then
  TRAEFIK_AUTH=$(htpasswd -nb "$TRAEFIK_USER" "$TRAEFIK_PASSWORD")
else
  # Use Docker to generate the hash if htpasswd is not available
  echo -e "${YELLOW}htpasswd not found, using Docker to generate credentials...${NC}"
  TRAEFIK_AUTH=$(docker run --rm httpd:alpine htpasswd -nb "$TRAEFIK_USER" "$TRAEFIK_PASSWORD")
fi

# Escape special characters for .env file
TRAEFIK_AUTH=$(echo "$TRAEFIK_AUTH" | sed 's/\$/\$\$/g')

# Update .env file
cat > .env << EOF
# Domain configuration
DOMAIN=$DOMAIN

# Email for Let's Encrypt notifications
EMAIL=$EMAIL

# Port configuration
HTTP_PORT=$HTTP_PORT
HTTPS_PORT=$HTTPS_PORT
PORT=$PORT
DASHBOARD_PORT=$DASHBOARD_PORT

# Traefik dashboard authentication
TRAEFIK_AUTH=$TRAEFIK_AUTH
EOF

echo -e "${GREEN}Configuration saved to .env file.${NC}"

# Check if OpenLiteSpeed is running on ports 80/443
if command_exists lsof; then
  HTTP_PORT_CHECK=$(lsof -i :$HTTP_PORT | grep LISTEN)
  HTTPS_PORT_CHECK=$(lsof -i :$HTTPS_PORT | grep LISTEN)

  if [ ! -z "$HTTP_PORT_CHECK" ] || [ ! -z "$HTTPS_PORT_CHECK" ]; then
    echo -e "${YELLOW}Warning: Ports $HTTP_PORT and/or $HTTPS_PORT may be in use.${NC}"
    echo -e "${YELLOW}If you have OpenLiteSpeed running, you may need to stop it or use different ports.${NC}"
    read -p "Do you want to continue? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ]; then
      exit 1
    fi
  fi
fi

# Create necessary directories
mkdir -p traefik/config traefik/letsencrypt
chmod 600 traefik/letsencrypt

echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${YELLOW}To start the application, run:${NC}"
echo -e "${GREEN}docker-compose up -d${NC}"
echo -e "${YELLOW}To stop the application, run:${NC}"
echo -e "${GREEN}docker-compose down${NC}"
