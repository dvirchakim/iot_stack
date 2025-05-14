# IoT Sensor Data Workflow Import Tool for n8n

# Configuration
$N8N_HOST = "localhost"
$N8N_PORT = "5678"
$N8N_URL = "http://${N8N_HOST}:${N8N_PORT}"
$N8N_EMAIL = "admin@example.com"
$N8N_PASSWORD = "password123"
$WORKFLOW_FILE = "workflow.json"
$MAX_RETRIES = 10
$RETRY_DELAY = 5

Write-Host "IoT Sensor Data Workflow Import Tool" -ForegroundColor Cyan
Write-Host "----------------------------------------"

# Function to check if workflow file exists
function Test-WorkflowFile {
    if (-not (Test-Path -Path $WORKFLOW_FILE)) {
        Write-Host "Error: Workflow file '$WORKFLOW_FILE' not found!" -ForegroundColor Red
        Write-Host "Make sure you're running this script from the project root directory."
        return $false
    }
    
    Write-Host "Found workflow file: $WORKFLOW_FILE" -ForegroundColor Green
    return $true
}

# Function to check if n8n is ready
function Test-N8nReady {
    Write-Host "Checking if n8n is ready..." -ForegroundColor Yellow
    $retryCount = 0
    
    while ($retryCount -lt $MAX_RETRIES) {
        try {
            $response = Invoke-RestMethod -Uri "${N8N_URL}/healthz" -Method Get -TimeoutSec 5
            if ($response -eq "ok") {
                Write-Host "n8n is up and running!" -ForegroundColor Green
                return $true
            }
        } catch {
            # Ignore error and retry
        }
        
        $retryCount++
        Write-Host "n8n not ready yet. Waiting ${RETRY_DELAY} seconds... (Attempt ${retryCount}/${MAX_RETRIES})" -ForegroundColor Yellow
        Start-Sleep -Seconds $RETRY_DELAY
    }
    
    Write-Host "n8n did not become ready after ${MAX_RETRIES} attempts." -ForegroundColor Red
    Write-Host "Check if the n8n container is running with 'docker-compose ps'" -ForegroundColor Yellow
    return $false
}

# Function to handle user setup
function Initialize-N8nUser {
    Write-Host "Checking if n8n needs initial setup..." -ForegroundColor Yellow
    
    try {
        $setupStatus = Invoke-RestMethod -Uri "${N8N_URL}/rest/setup" -Method Get -TimeoutSec 5
        
        if ($setupStatus.setupStatus -eq "not-completed") {
            Write-Host "Creating initial user..." -ForegroundColor Yellow
            
            # Create the initial user
            $setupBody = @{
                email = $N8N_EMAIL
                password = $N8N_PASSWORD
                firstName = "Admin"
                lastName = "User"
            } | ConvertTo-Json
            
            $setupResponse = Invoke-RestMethod -Uri "${N8N_URL}/rest/setup" `
                -Method Post `
                -ContentType "application/json" `
                -Body $setupBody
                
            if ($setupResponse.success -eq $true) {
                Write-Host "Initial user created successfully." -ForegroundColor Green
                return $true
            } else {
                Write-Host "Failed to create initial user." -ForegroundColor Red
                Write-Host "Response: $($setupResponse | ConvertTo-Json)" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "n8n is already set up." -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "Setup check failed: $_" -ForegroundColor Yellow
        Write-Host "Continuing with login attempt..." -ForegroundColor Yellow
        return $true  # Continue anyway, might be already set up
    }
}

# Function to login and get auth token
function Get-N8nAuthToken {
    Write-Host "Logging in to n8n..." -ForegroundColor Yellow
    
    try {
        $loginBody = @{
            email = $N8N_EMAIL
            password = $N8N_PASSWORD
        } | ConvertTo-Json
        
        $authResponse = Invoke-RestMethod -Uri "${N8N_URL}/rest/login" `
            -Method Post `
            -ContentType "application/json" `
            -Body $loginBody
        
        $apiToken = $authResponse.token
        
        if ([string]::IsNullOrEmpty($apiToken)) {
            throw "Empty token received"
        }
        
        Write-Host "Successfully authenticated with token." -ForegroundColor Green
        return @{
            Type = "token"
            Value = $apiToken
        }
    } catch {
        Write-Host "Token-based authentication failed: $_" -ForegroundColor Yellow
        Write-Host "Trying cookie-based authentication..." -ForegroundColor Yellow
        
        # Try cookie-based authentication as fallback
        try {
            $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
            $loginResponse = Invoke-WebRequest -Uri "${N8N_URL}/rest/login" `
                -Method Post `
                -ContentType "application/json" `
                -Body $loginBody `
                -SessionVariable session
            
            if ($session.Cookies.Count -gt 0) {
                Write-Host "Successfully authenticated with cookies." -ForegroundColor Green
                return @{
                    Type = "cookie"
                    Value = $session
                }
            } else {
                Write-Host "No cookies received from authentication." -ForegroundColor Red
                return $null
            }
        } catch {
            Write-Host "All authentication methods failed." -ForegroundColor Red
            return $null
        }
    }
}

# Function to import workflow
function Import-N8nWorkflow {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Auth
    )
    
    Write-Host "Preparing workflow for import..." -ForegroundColor Yellow
    $workflowJson = Get-Content -Path $WORKFLOW_FILE -Raw
    
    Write-Host "Importing workflow into n8n..." -ForegroundColor Yellow
    
    try {
        if ($Auth.Type -eq "token") {
            $headers = @{
                "Content-Type" = "application/json"
                "Accept" = "application/json"
                "X-N8N-Skip-Webhook-Register" = "true"
                "Authorization" = "Bearer $($Auth.Value)"
            }
            
            $importResponse = Invoke-RestMethod -Uri "${N8N_URL}/rest/workflows" `
                -Method Post `
                -Headers $headers `
                -Body $workflowJson
        } else {
            $headers = @{
                "Content-Type" = "application/json"
                "Accept" = "application/json"
                "X-N8N-Skip-Webhook-Register" = "true"
            }
            
            $importResponse = Invoke-RestMethod -Uri "${N8N_URL}/rest/workflows" `
                -Method Post `
                -Headers $headers `
                -WebSession $Auth.Value `
                -Body $workflowJson
        }
        
        Write-Host "`nWorkflow imported successfully!" -ForegroundColor Green
        Write-Host "Workflow ID: $($importResponse.id)" -ForegroundColor Green
        Write-Host "You can now access it at ${N8N_URL}/workflow/edit/$($importResponse.id)"
        return $true
    } catch {
        Write-Host "`nError importing workflow: $_" -ForegroundColor Red
        Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Red
        return $false
    }
}

# Main execution
function Start-WorkflowImport {
    # Check if workflow file exists
    if (-not (Test-WorkflowFile)) {
        exit 1
    }
    
    # Wait for n8n to be ready
    if (-not (Test-N8nReady)) {
        exit 1
    }
    
    # Setup user if needed
    if (-not (Initialize-N8nUser)) {
        Write-Host "User setup failed, but continuing..." -ForegroundColor Yellow
    }
    
    # Get authentication token or session
    $auth = Get-N8nAuthToken
    if ($null -eq $auth) {
        Write-Host "Authentication failed. Cannot import workflow." -ForegroundColor Red
        exit 1
    }
    
    # Import the workflow
    if (-not (Import-N8nWorkflow -Auth $auth)) {
        Write-Host "Workflow import failed." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "`nWorkflow import process completed successfully!" -ForegroundColor Green
}

# Run the main function
Start-WorkflowImport
