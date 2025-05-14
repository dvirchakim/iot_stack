Write-Host "Starting n8n and InfluxDB Docker stack..." -ForegroundColor Green

# Check if Docker is running
$dockerStatus = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Docker is not running. Please start Docker Desktop and try again." -ForegroundColor Red
    exit 1
}

# Start the Docker Compose stack
Write-Host "Starting containers..." -ForegroundColor Yellow
docker-compose up -d

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nDocker stack started successfully!" -ForegroundColor Green
    Write-Host "`nServices available at:"
    Write-Host "- n8n: http://localhost:5678"
    Write-Host "- InfluxDB: http://localhost:8086"
    Write-Host "`nTo import the workflow in n8n:"
    Write-Host "1. Go to http://localhost:5678"
    Write-Host "2. Navigate to Workflows > Import from file"
    Write-Host "3. Upload the workflow.json file"
} else {
    Write-Host "`nFailed to start Docker stack. Check the error messages above." -ForegroundColor Red
}
