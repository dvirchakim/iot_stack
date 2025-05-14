#!/bin/bash

# Configuration
N8N_HOST="localhost"
N8N_PORT="5678"
N8N_URL="http://${N8N_HOST}:${N8N_PORT}"
WORKFLOW_FILE="workflow.json"
MAX_RETRIES=20
RETRY_DELAY=5

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${GREEN}IoT Sensor Data Workflow Import Tool${NC}"
echo "----------------------------------------"

# Check if workflow file exists
if [ ! -f "$WORKFLOW_FILE" ]; then
  echo -e "${RED}Error: Workflow file '$WORKFLOW_FILE' not found!${NC}"
  echo "Make sure you're running this script from the project root directory."
  exit 1
fi

echo -e "${GREEN}Found workflow file: $WORKFLOW_FILE${NC}"

# Wait for n8n to be fully ready
echo -e "${YELLOW}Waiting for n8n to be ready...${NC}"
retry_count=0

while [ $retry_count -lt $MAX_RETRIES ]; do
  if curl -s "${N8N_URL}/healthz" | grep -q "ok"; then
    echo -e "${GREEN}n8n is up and running!${NC}"
    # Wait a bit more to ensure the API is fully initialized
    echo -e "${YELLOW}Waiting 5 more seconds for n8n API to initialize...${NC}"
    sleep 5
    break
  else
    retry_count=$((retry_count+1))
    echo -e "${YELLOW}n8n not ready yet. Waiting ${RETRY_DELAY} seconds... (Attempt ${retry_count}/${MAX_RETRIES})${NC}"
    sleep $RETRY_DELAY
  fi
  
  if [ $retry_count -eq $MAX_RETRIES ]; then
    echo -e "${RED}n8n did not become ready after ${MAX_RETRIES} attempts.${NC}"
    echo -e "${YELLOW}Check container logs with: docker-compose logs n8n${NC}"
    exit 1
  fi
done

# Import the workflow
echo -e "${YELLOW}Importing workflow...${NC}"

# Try multiple times with increasing delays
for attempt in {1..5}; do
  echo -e "${YELLOW}Import attempt $attempt of 5...${NC}"
  
  # Use curl with verbose output to see what's happening
  response=$(curl -s -X POST "${N8N_URL}/rest/workflows" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H "X-N8N-Skip-Webhook-Register: true" \
    -d @${WORKFLOW_FILE})
  
  # Check if import was successful
  if echo "$response" | grep -q '"id":"'; then
    workflow_id=$(echo "$response" | grep -o '"id":"[^"]*"' | head -1 | cut -d '"' -f 4)
    echo -e "${GREEN}Success! Workflow imported with ID: $workflow_id${NC}"
    echo -e "${GREEN}You can access it at: ${N8N_URL}/workflow/edit/$workflow_id${NC}"
    exit 0
  else
    echo -e "${RED}Import failed on attempt $attempt.${NC}"
    echo -e "${YELLOW}Response: $response${NC}"
    echo -e "${YELLOW}Waiting before retry...${NC}"
    sleep $((attempt * 5))
  fi
done

echo -e "${RED}Failed to import workflow after multiple attempts.${NC}"
echo -e "${YELLOW}Try manually importing the workflow through the n8n web interface:${NC}"
echo -e "${YELLOW}1. Open ${N8N_URL} in your browser${NC}"
echo -e "${YELLOW}2. Go to Workflows > Import from file${NC}"
echo -e "${YELLOW}3. Upload the workflow.json file${NC}"
exit 1
