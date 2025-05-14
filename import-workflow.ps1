Write-Host "Importing workflow into n8n..." -ForegroundColor Green

# Wait for n8n to be fully up and running
Write-Host "Waiting for n8n to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Step 1: Check if we need to create a user (n8n might be in setup mode)
Write-Host "Checking setup status..." -ForegroundColor Yellow
try {
    $setupStatus = Invoke-RestMethod -Uri "http://localhost:5678/rest/setup" -Method Get
    
    if ($setupStatus.setupStatus -eq "not-completed") {
        Write-Host "Creating initial user..." -ForegroundColor Yellow
        # Create the initial user
        $setupBody = @{
            email = "admin@example.com"
            password = "password123"
            firstName = "Admin"
            lastName = "User"
        } | ConvertTo-Json
        
        Invoke-RestMethod -Uri "http://localhost:5678/rest/setup" `
            -Method Post `
            -ContentType "application/json" `
            -Body $setupBody
            
        Write-Host "Initial user created." -ForegroundColor Green
    }
} catch {
    Write-Host "Setup check failed: $_" -ForegroundColor Yellow
    Write-Host "Continuing with login..." -ForegroundColor Yellow
}

# Step 2: Login to get an auth token
Write-Host "Logging in..." -ForegroundColor Yellow
try {
    $loginBody = @{
        email = "admin@example.com"
        password = "password123"
    } | ConvertTo-Json
    
    $authResponse = Invoke-RestMethod -Uri "http://localhost:5678/rest/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $loginBody
    
    $apiToken = $authResponse.token
    
    if ([string]::IsNullOrEmpty($apiToken)) {
        throw "Failed to get authentication token"
    }
    
    Write-Host "Successfully authenticated." -ForegroundColor Green
} catch {
    Write-Host "Login failed: $_" -ForegroundColor Red
    Write-Host "Make sure n8n is running and accessible at http://localhost:5678" -ForegroundColor Red
    exit 1
}

# Step 3: Get the workflow JSON
Write-Host "Preparing workflow..." -ForegroundColor Yellow
$workflowJson = Get-Content -Path "workflow.json" -Raw

# Step 4: Import the workflow using the n8n API with authentication
Write-Host "Importing workflow..." -ForegroundColor Yellow
try {
    $importResponse = Invoke-RestMethod -Uri "http://localhost:5678/rest/workflows" `
        -Method Post `
        -ContentType "application/json" `
        -Headers @{
            "Accept" = "application/json"
            "X-N8N-Skip-Webhook-Register" = "true"
            "Authorization" = "Bearer $apiToken"
        } `
        -Body $workflowJson

    Write-Host "`nWorkflow imported successfully!" -ForegroundColor Green
    Write-Host "Workflow ID: $($importResponse.id)" -ForegroundColor Green
    Write-Host "You can now access it at http://localhost:5678/workflow/edit/$($importResponse.id)"
} catch {
    Write-Host "`nError importing workflow: $_" -ForegroundColor Red
    Write-Host "Make sure n8n is running and accessible at http://localhost:5678" -ForegroundColor Red
}
