Write-Host "Importing workflow into n8n..." -ForegroundColor Green

# Wait for n8n to be fully up and running
Write-Host "Waiting for n8n to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Get the workflow JSON
$workflowJson = Get-Content -Path "workflow.json" -Raw

# Import the workflow using the n8n API
try {
    $response = Invoke-RestMethod -Uri "http://localhost:5678/rest/workflows" `
        -Method Post `
        -ContentType "application/json" `
        -Headers @{
            "Accept" = "application/json"
            "X-N8N-Skip-Webhook-Register" = "true"
        } `
        -Body $workflowJson

    Write-Host "`nWorkflow imported successfully!" -ForegroundColor Green
    Write-Host "You can now access it at http://localhost:5678/workflow/edit"
} catch {
    Write-Host "`nError importing workflow: $_" -ForegroundColor Red
    Write-Host "Make sure n8n is running and accessible at http://localhost:5678"
}
