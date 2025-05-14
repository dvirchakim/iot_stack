#!/bin/bash

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${GREEN}IoT Sensor Data Workflow Import Tool (CLI Method)${NC}"
echo "----------------------------------------"

# Check if workflow file exists
if [ ! -f "workflow.json" ]; then
  echo -e "${RED}Error: workflow.json file not found!${NC}"
  echo "Make sure you're running this script from the project root directory."
  exit 1
fi

echo -e "${GREEN}Found workflow file: workflow.json${NC}"

# Wait for n8n container to be ready
echo -e "${YELLOW}Waiting for n8n container to be ready...${NC}"
while ! docker ps | grep -q "iot_stack-n8n-1"; do
  echo -e "${YELLOW}Waiting for n8n container to start...${NC}"
  sleep 5
done

echo -e "${GREEN}n8n container is running!${NC}"
sleep 5  # Give it a bit more time to initialize

# Copy the workflow file into the container
echo -e "${YELLOW}Copying workflow file into the container...${NC}"
docker cp workflow.json iot_stack-n8n-1:/tmp/workflow.json

if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to copy workflow file to container.${NC}"
  exit 1
fi

echo -e "${GREEN}Workflow file copied successfully.${NC}"

# Import the workflow using n8n CLI inside the container
echo -e "${YELLOW}Importing workflow using n8n CLI...${NC}"
docker exec iot_stack-n8n-1 n8n import:workflow --input=/tmp/workflow.json --separate

if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to import workflow using CLI.${NC}"
  echo -e "${YELLOW}Trying alternative method...${NC}"
  
  # Try with different CLI syntax (for older n8n versions)
  docker exec iot_stack-n8n-1 n8n import --input=/tmp/workflow.json
  
  if [ $? -ne 0 ]; then
    echo -e "${RED}All import methods failed.${NC}"
    echo -e "${YELLOW}Please try manually importing the workflow through the n8n web interface:${NC}"
    echo -e "${YELLOW}1. Open http://localhost:5678 in your browser${NC}"
    echo -e "${YELLOW}2. Go to Workflows > Import from file${NC}"
    echo -e "${YELLOW}3. Upload the workflow.json file${NC}"
    exit 1
  fi
fi

echo -e "${GREEN}Workflow imported successfully!${NC}"
echo -e "${GREEN}You can access n8n at: http://localhost:5678${NC}"
exit 0
