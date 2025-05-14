#!/bin/bash

echo "Importing workflow into n8n..."

# Wait for n8n to be fully up and running
echo "Waiting for n8n to be ready..."
sleep 10

# Get the workflow JSON
WORKFLOW_JSON=$(cat workflow.json)

# Import the workflow using the n8n API
curl -X POST http://localhost:5678/rest/workflows \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "X-N8N-Skip-Webhook-Register: true" \
  -d "$WORKFLOW_JSON"

echo -e "\nWorkflow imported successfully!"
echo "You can now access it at http://localhost:5678/workflow/edit"
