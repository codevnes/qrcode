#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Stopping Docker containers...${NC}"
docker-compose down

echo -e "${YELLOW}Starting Docker containers...${NC}"
docker-compose up -d

echo -e "${GREEN}Services restarted successfully!${NC}"
echo -e "${YELLOW}To check logs, run:${NC}"
echo -e "${GREEN}docker-compose logs${NC}"
