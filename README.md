# QR Code Generator for Vietnamese Bank Payments

This application generates QR codes for Vietnamese bank payments using the VietQR standard.

## Features

- Generate QR codes for Vietnamese bank payments
- Docker support for easy deployment
- Automatic SSL certificate generation with Let's Encrypt
- Custom domain configuration
- Configurable ports
- Cross-platform support (Linux, macOS, Windows)

## Prerequisites

- Docker and Docker Compose installed
- A domain name pointing to your server's IP address
- Open ports for HTTP (80) and HTTPS (443) traffic

## Quick Start

### For Production (With SSL)

#### Linux/macOS Users

1. Clone this repository
2. Run the setup script:
   ```bash
   ./setup.sh
   ```
3. Follow the prompts to configure your domain, email, and ports
4. Start the application:
   ```bash
   docker-compose up -d
   ```

#### Windows Users

1. Clone this repository
2. Run the PowerShell setup script:
   ```powershell
   .\setup.ps1
   ```
3. Follow the prompts to configure your domain, email, and ports
4. Start the application:
   ```powershell
   docker-compose up -d
   ```

### For Local Development (Without SSL)

#### Linux/macOS Users

1. Clone this repository
2. Run the setup script to configure your environment:
   ```bash
   ./setup.sh
   ```
3. Start the application in local mode:
   ```bash
   ./local.sh
   ```

#### Windows Users

1. Clone this repository
2. Run the PowerShell setup script to configure your environment:
   ```powershell
   .\setup.ps1
   ```
3. Start the application in local mode:
   ```powershell
   .\local.ps1
   ```

## Usage

### Web Interface

Once the application is running, you can access the web interface at:

```
https://your-domain.com/
```

This provides a user-friendly form to generate QR codes.

### Direct API Access

You can also generate QR codes programmatically by accessing:

```
https://your-domain.com/generate-qr?bankKey=BANK_KEY&bankAccount=ACCOUNT_NUMBER&amount=AMOUNT&message=MESSAGE
```

This will return a direct URL to the QR code image, which can be used in your applications.

### Parameters

Replace the following parameters:
- `BANK_KEY`: The bank identifier (e.g., `VCB` for Vietcombank)
- `ACCOUNT_NUMBER`: Your bank account number
- `AMOUNT`: The payment amount (optional)
- `MESSAGE`: The payment message (optional)

### Image URLs

The QR code images are accessible directly at:

```
https://your-domain.com/qr-images/[hash].png
```

Where `[hash]` is a unique identifier generated from the QR code parameters. This allows you to:

1. Use the image URL directly in your applications
2. Share the URL with others
3. Embed the image in websites, emails, or documents

## Configuration

The application can be configured through the `.env` file, which is created during setup. You can manually edit this file to change settings:

```
# Domain configuration
DOMAIN=yourdomain.com

# Email for Let's Encrypt notifications
EMAIL=your-email@example.com

# Port configuration
HTTP_PORT=80
HTTPS_PORT=443
PORT=3000
DASHBOARD_PORT=8080

# Traefik dashboard authentication
TRAEFIK_AUTH=admin:$$apr1$$q8eZFHjF$$Fvmkk//V6Btlaf2i/ju5n/
```

## Accessing the Traefik Dashboard

The Traefik dashboard is available at:

```
https://your-domain.com/dashboard/
```

Use the username and password you provided during setup to access the dashboard.

## Troubleshooting

### Port Conflicts

If you have OpenLiteSpeed or another web server running on ports 80 and 443, you can:

1. Stop the other web server before running this application
2. Configure this application to use different ports during setup
3. Set up a proxy in your existing web server to forward traffic to this application

### SSL Certificate Issues

If you're having trouble with SSL certificate generation:

1. Make sure your domain is correctly pointing to your server's IP address
2. Ensure ports 80 and 443 are open and accessible from the internet
3. Check the Traefik logs for more information:
   ```bash
   docker-compose logs traefik
   ```

4. If you're testing locally or don't need SSL, use the local mode instead:
   ```bash
   ./local.sh  # For Linux/macOS
   # or
   .\local.ps1  # For Windows
   ```

5. If you're behind a firewall or NAT, Let's Encrypt may not be able to reach your server for validation. In this case, you might need to:
   - Configure port forwarding on your router
   - Use a different ACME challenge method
   - Use a reverse proxy service like Cloudflare

## Checking Logs

You can check the logs of your Docker containers using the following commands:

### View All Logs

```bash
docker-compose logs
```

### View Logs for a Specific Service

```bash
docker-compose logs app
# or
docker-compose logs traefik
```

### Follow Logs in Real-Time

```bash
docker-compose logs -f
# or for a specific service
docker-compose logs -f app
```

### View Limited Number of Lines

```bash
docker-compose logs --tail=100
```

### View Logs with Timestamps

```bash
docker-compose logs --timestamps
```

## License

This project is licensed under the ISC License - see the package.json file for details.