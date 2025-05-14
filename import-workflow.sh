#!/bin/bash

set -e

# Configuration
N8N_HOST="localhost"
N8N_PORT="5678"
N8N_URL="http://${N8N_HOST}:${N8N_PORT}"
N8N_EMAIL="admin@example.com"
N8N_PASSWORD="password123"
WORKFLOW_FILE="workflow.json"
MAX_RETRIES=10
RETRY_DELAY=5

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${GREEN}IoT Sensor Data Workflow Import Tool${NC}"
echo "----------------------------------------"

# Function to check if n8n is ready
check_n8n_ready() {
  echo -e "${YELLOW}Checking if n8n is ready...${NC}"
  local retry_count=0
  
  while [ $retry_count -lt $MAX_RETRIES ]; do
    if curl -s "${N8N_URL}/healthz" | grep -q "ok"; then
      echo -e "${GREEN}n8n is up and running!${NC}"
      return 0
    else
      retry_count=$((retry_count+1))
      echo -e "${YELLOW}n8n not ready yet. Waiting ${RETRY_DELAY} seconds... (Attempt ${retry_count}/${MAX_RETRIES})${NC}"
      sleep $RETRY_DELAY
    fi
  done
  
  echo -e "${RED}n8n did not become ready after ${MAX_RETRIES} attempts.${NC}"
  echo -e "${YELLOW}Check if the n8n container is running with 'docker-compose ps'${NC}"
  return 1
}

# Function to check if workflow file exists
check_workflow_file() {
  if [ ! -f "$WORKFLOW_FILE" ]; then
    echo -e "${RED}Error: Workflow file '$WORKFLOW_FILE' not found!${NC}"
    echo "Make sure you're running this script from the project root directory."
    exit 1
  fi
  
  echo -e "${GREEN}Found workflow file: $WORKFLOW_FILE${NC}"
}

# Function to handle user setup
setup_user() {
  echo -e "${YELLOW}Checking if n8n needs initial setup...${NC}"
  
  # Check if we need to create a user (n8n might be in setup mode)
  local setup_status=$(curl -s "${N8N_URL}/rest/setup")
  
  if [[ $setup_status == *"setupStatus":"not-completed"* ]]; then
    echo -e "${YELLOW}Creating initial user...${NC}"
    # Create the initial user
    local setup_response=$(curl -s -X POST "${N8N_URL}/rest/setup" \
      -H "Content-Type: application/json" \
      -d '{"email":"'"$N8N_EMAIL"'","password":"'"$N8N_PASSWORD"'","firstName":"Admin","lastName":"User"}')
    
    if [[ $setup_response == *""success":true"* ]]; then
      echo -e "${GREEN}Initial user created successfully.${NC}"
    else
      echo -e "${RED}Failed to create initial user.${NC}"
      echo "Response: $setup_response"
      return 1
    fi
  else
    echo -e "${GREEN}n8n is already set up.${NC}"
  fi
  
  return 0
}

# Function to login and get auth token
get_auth_token() {
  echo -e "${YELLOW}Logging in to n8n...${NC}"
  
  local auth_response=$(curl -s -X POST "${N8N_URL}/rest/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"'"$N8N_EMAIL"'","password":"'"$N8N_PASSWORD"'"}')
  
  # Extract the token
  local api_token=$(echo $auth_response | grep -o '"token":"[^"]*"' | cut -d '"' -f 4)
  
  if [ -z "$api_token" ]; then
    echo -e "${RED}Failed to get authentication token.${NC}"
    echo "Response: $auth_response"
    echo -e "${YELLOW}Trying alternative authentication method...${NC}"
    
    # Try the cookie-based authentication as fallback
    local cookie_jar="/tmp/n8n_cookies.txt"
    curl -s -c "$cookie_jar" -X POST "${N8N_URL}/rest/login" \
      -H "Content-Type: application/json" \
      -d '{"email":"'"$N8N_EMAIL"'","password":"'"$N8N_PASSWORD"'"}' > /dev/null
    
    # Check if we got a cookie
    if [ -s "$cookie_jar" ]; then
      echo -e "${GREEN}Successfully authenticated with cookies.${NC}"
      echo "$cookie_jar"
      return 0
    else
      echo -e "${RED}All authentication methods failed.${NC}"
      return 1
    fi
  fi
  
  echo -e "${GREEN}Successfully authenticated with token.${NC}"
  echo "$api_token"
  return 0
}

# Function to import workflow
import_workflow() {
  local auth_method=$1
  local auth_value=$2
  
  echo -e "${YELLOW}Preparing workflow for import...${NC}"
  local workflow_json=$(cat "$WORKFLOW_FILE")
  
  echo -e "${YELLOW}Importing workflow into n8n...${NC}"
  
  local import_cmd
  if [ "$auth_method" = "token" ]; then
    import_cmd="curl -s -X POST '${N8N_URL}/rest/workflows' \
      -H 'Content-Type: application/json' \
      -H 'Accept: application/json' \
      -H 'X-N8N-Skip-Webhook-Register: true' \
      -H 'Authorization: Bearer $auth_value' \
      -d @${WORKFLOW_FILE}"
  else
    import_cmd="curl -s -X POST '${N8N_URL}/rest/workflows' \
      -H 'Content-Type: application/json' \
      -H 'Accept: application/json' \
      -H 'X-N8N-Skip-Webhook-Register: true' \
      -b '$auth_value' \
      -d @${WORKFLOW_FILE}"
  fi
  
  local import_response=$(eval $import_cmd)
  
  # Check if import was successful
  if [[ $import_response == *"id"* ]]; then
    echo -e "${GREEN}Workflow imported successfully!${NC}"
    local workflow_id=$(echo $import_response | grep -o '"id":"[^"]*"' | cut -d '"' -f 4)
    echo -e "${GREEN}Workflow ID: $workflow_id${NC}"
    echo -e "${GREEN}You can now access it at ${N8N_URL}/workflow/edit/$workflow_id${NC}"
    return 0
  else
    echo -e "${RED}Error importing workflow:${NC}"
    echo "$import_response"
    return 1
  fi
}

# Main execution
main() {
  # Check if workflow file exists
  check_workflow_file
  
  # Wait for n8n to be ready
  check_n8n_ready || exit 1
  
  # Setup user if needed
  setup_user || exit 1
  
  # Get authentication token
  auth_result=$(get_auth_token)
  auth_status=$?
  
  if [ $auth_status -eq 0 ]; then
    # Determine auth method based on response
    if [[ $auth_result == /tmp/* ]]; then
      # Cookie-based auth
      import_workflow "cookie" "$auth_result"
    else
      # Token-based auth
      import_workflow "token" "$auth_result"
    fi
  else
    echo -e "${RED}Authentication failed. Cannot import workflow.${NC}"
    exit 1
  fi
}

# Run the main function
main
