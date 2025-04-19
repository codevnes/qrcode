# PowerShell script for Windows users

# Function to check if a command exists
function Test-CommandExists {
    param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
        if (Get-Command $command) { return $true }
    } catch {
        return $false
    } finally {
        $ErrorActionPreference = $oldPreference
    }
}

# Check for required dependencies
Write-Host "Checking dependencies..." -ForegroundColor Yellow
if (-not (Test-CommandExists docker)) {
    Write-Host "Docker is not installed. Please install Docker first." -ForegroundColor Red
    Write-Host "Visit https://docs.docker.com/get-docker/ for installation instructions."
    exit 1
}

if (-not (Test-CommandExists docker-compose)) {
    if ((Test-CommandExists docker) -and (docker compose version 2>&1 | Out-Null) -eq $null) {
        Write-Host "Docker Compose plugin detected." -ForegroundColor Green
    } else {
        Write-Host "Docker Compose is not installed. Please install Docker Compose first." -ForegroundColor Red
        Write-Host "Visit https://docs.docker.com/compose/install/ for installation instructions."
        exit 1
    }
}

# Check if .env file exists, if not create it
if (-not (Test-Path .env)) {
    Write-Host "Creating .env file..." -ForegroundColor Yellow
    New-Item -Path .env -ItemType File | Out-Null
} else {
    Write-Host "Updating existing .env file..." -ForegroundColor Yellow
}

# Get domain
$DOMAIN = Read-Host "Enter your domain name (e.g., example.com)"
if ([string]::IsNullOrEmpty($DOMAIN)) {
    Write-Host "Domain name is required." -ForegroundColor Red
    exit 1
}

# Get email for Let's Encrypt
$EMAIL = Read-Host "Enter your email for Let's Encrypt notifications"
if ([string]::IsNullOrEmpty($EMAIL)) {
    Write-Host "Email is required for Let's Encrypt." -ForegroundColor Red
    exit 1
}

# Get HTTP port (default: 80)
$HTTP_PORT = Read-Host "Enter HTTP port [80]"
if ([string]::IsNullOrEmpty($HTTP_PORT)) { $HTTP_PORT = "80" }

# Get HTTPS port (default: 443)
$HTTPS_PORT = Read-Host "Enter HTTPS port [443]"
if ([string]::IsNullOrEmpty($HTTPS_PORT)) { $HTTPS_PORT = "443" }

# Get application port (default: 3000)
$PORT = Read-Host "Enter application port [3000]"
if ([string]::IsNullOrEmpty($PORT)) { $PORT = "3000" }

# Generate Traefik auth credentials
$TRAEFIK_USER = Read-Host "Enter username for Traefik dashboard [admin]"
if ([string]::IsNullOrEmpty($TRAEFIK_USER)) { $TRAEFIK_USER = "admin" }

$TRAEFIK_PASSWORD = Read-Host "Enter password for Traefik dashboard [password]" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($TRAEFIK_PASSWORD)
$TRAEFIK_PASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
if ([string]::IsNullOrEmpty($TRAEFIK_PASSWORD)) { $TRAEFIK_PASSWORD = "password" }

# Use Docker to generate the hash
Write-Host "Using Docker to generate credentials..." -ForegroundColor Yellow
$TRAEFIK_AUTH = docker run --rm httpd:alpine htpasswd -nb $TRAEFIK_USER $TRAEFIK_PASSWORD

# Escape special characters for .env file
$TRAEFIK_AUTH = $TRAEFIK_AUTH -replace '\$', '$$'

# Update .env file
@"
# Domain configuration
DOMAIN=$DOMAIN

# Email for Let's Encrypt notifications
EMAIL=$EMAIL

# Port configuration
HTTP_PORT=$HTTP_PORT
HTTPS_PORT=$HTTPS_PORT
PORT=$PORT

# Traefik dashboard authentication
TRAEFIK_AUTH=$TRAEFIK_AUTH
"@ | Set-Content -Path .env

Write-Host "Configuration saved to .env file." -ForegroundColor Green

# Check if ports are in use
$HTTP_PORT_IN_USE = $false
$HTTPS_PORT_IN_USE = $false

try {
    $HTTP_PORT_CHECK = Get-NetTCPConnection -LocalPort $HTTP_PORT -ErrorAction SilentlyContinue
    if ($HTTP_PORT_CHECK) { $HTTP_PORT_IN_USE = $true }
} catch {}

try {
    $HTTPS_PORT_CHECK = Get-NetTCPConnection -LocalPort $HTTPS_PORT -ErrorAction SilentlyContinue
    if ($HTTPS_PORT_CHECK) { $HTTPS_PORT_IN_USE = $true }
} catch {}

if ($HTTP_PORT_IN_USE -or $HTTPS_PORT_IN_USE) {
    Write-Host "Warning: Ports $HTTP_PORT and/or $HTTPS_PORT may be in use." -ForegroundColor Yellow
    Write-Host "If you have other web servers running, you may need to stop them or use different ports." -ForegroundColor Yellow
    $CONTINUE = Read-Host "Do you want to continue? (y/n)"
    if ($CONTINUE -ne "y") {
        exit 1
    }
}

# Create necessary directories
if (-not (Test-Path traefik/config)) {
    New-Item -Path traefik/config -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path traefik/letsencrypt)) {
    New-Item -Path traefik/letsencrypt -ItemType Directory -Force | Out-Null
}

Write-Host "Setup completed successfully!" -ForegroundColor Green
Write-Host "To start the application, run:" -ForegroundColor Yellow
Write-Host "docker-compose up -d" -ForegroundColor Green
Write-Host "To stop the application, run:" -ForegroundColor Yellow
Write-Host "docker-compose down" -ForegroundColor Green
