#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Stop any running containers
echo -e "${YELLOW}Stopping any running containers...${NC}"
docker-compose down

# Start the application in local mode
echo -e "${YELLOW}Starting the application in local mode (without SSL)...${NC}"
docker-compose -f docker-compose.local.yml up -d

# Get the port from .env file or use default
PORT=$(grep "PORT=" .env | cut -d= -f2 || echo "3000")

echo -e "${GREEN}Application started in local mode!${NC}"
echo -e "${GREEN}You can access it at: http://localhost:${PORT}${NC}"
echo -e "${YELLOW}To check logs, run:${NC}"
echo -e "${GREEN}docker-compose -f docker-compose.local.yml logs${NC}"
echo -e "${YELLOW}To stop the application, run:${NC}"
echo -e "${GREEN}docker-compose -f docker-compose.local.yml down${NC}"
