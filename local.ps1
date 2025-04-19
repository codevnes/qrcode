# PowerShell script for running in local mode

# Stop any running containers
Write-Host "Stopping any running containers..." -ForegroundColor Yellow
docker-compose down

# Start the application in local mode
Write-Host "Starting the application in local mode (without SSL)..." -ForegroundColor Yellow
docker-compose -f docker-compose.local.yml up -d

# Get the port from .env file or use default
$PORT = "3000"
if (Test-Path .env) {
    $ENV_CONTENT = Get-Content .env
    foreach ($line in $ENV_CONTENT) {
        if ($line -match "^PORT=(.*)$") {
            $PORT = $matches[1]
            break
        }
    }
}

Write-Host "Application started in local mode!" -ForegroundColor Green
Write-Host "You can access it at: http://localhost:$PORT" -ForegroundColor Green
Write-Host "To check logs, run:" -ForegroundColor Yellow
Write-Host "docker-compose -f docker-compose.local.yml logs" -ForegroundColor Green
Write-Host "To stop the application, run:" -ForegroundColor Yellow
Write-Host "docker-compose -f docker-compose.local.yml down" -ForegroundColor Green
