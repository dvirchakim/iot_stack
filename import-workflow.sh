#!/bin/bash

echo "Importing workflow into n8n..."

# Wait for n8n to be fully up and running
echo "Waiting for n8n to be ready..."
sleep 15

# Step 1: Create a user if it doesn't exist
echo "Setting up user..."

# First, check if we need to create a user (n8n might be in setup mode)
SETUP_STATUS=$(curl -s http://localhost:5678/rest/setup)
if [[ $SETUP_STATUS == *""setupStatus":"not-completed""* ]]; then
  echo "Creating initial user..."
  # Create the initial user
  curl -X POST http://localhost:5678/rest/setup \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"password123","firstName":"Admin","lastName":"User"}'
  
  echo "Initial user created."
fi

# Step 2: Login to get an auth token
echo "Logging in..."
AUTH_RESPONSE=$(curl -s -X POST http://localhost:5678/rest/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password123"}')

# Extract the token
API_TOKEN=$(echo $AUTH_RESPONSE | grep -o '"token":"[^"]*"' | cut -d '"' -f 4)

if [ -z "$API_TOKEN" ]; then
  echo "Failed to get authentication token. Check if n8n is running and credentials are correct."
  exit 1
fi

echo "Successfully authenticated."

# Step 3: Get the workflow JSON and modify it
echo "Preparing workflow..."
WORKFLOW_JSON=$(cat workflow.json)

# Step 4: Import the workflow using the n8n API with authentication
echo "Importing workflow..."
IMPORT_RESPONSE=$(curl -s -X POST http://localhost:5678/rest/workflows \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "X-N8N-Skip-Webhook-Register: true" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d "$WORKFLOW_JSON")

# Check if import was successful
if [[ $IMPORT_RESPONSE == *""id""* ]]; then
  echo -e "\nWorkflow imported successfully!"
  WORKFLOW_ID=$(echo $IMPORT_RESPONSE | grep -o '"id":"[^"]*"' | cut -d '"' -f 4)
  echo "Workflow ID: $WORKFLOW_ID"
  echo "You can now access it at http://localhost:5678/workflow/edit/$WORKFLOW_ID"
else
  echo -e "\nError importing workflow:"
  echo $IMPORT_RESPONSE
fi
