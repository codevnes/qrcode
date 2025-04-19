# PowerShell script for restarting services

Write-Host "Stopping Docker containers..." -ForegroundColor Yellow
docker-compose down

Write-Host "Starting Docker containers..." -ForegroundColor Yellow
docker-compose up -d

Write-Host "Services restarted successfully!" -ForegroundColor Green
Write-Host "To check logs, run:" -ForegroundColor Yellow
Write-Host "docker-compose logs" -ForegroundColor Green
