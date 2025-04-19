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

### For Linux/macOS Users

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

### For Windows Users

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

## Usage

Once the application is running, you can generate QR codes by accessing:

```
https://your-domain.com/generate-qr?bankKey=BANK_KEY&bankAccount=ACCOUNT_NUMBER&amount=AMOUNT&message=MESSAGE
```

Replace the following parameters:
- `BANK_KEY`: The bank identifier (e.g., `VCB` for Vietcombank)
- `ACCOUNT_NUMBER`: Your bank account number
- `AMOUNT`: The payment amount (optional)
- `MESSAGE`: The payment message (optional)

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

## License

This project is licensed under the ISC License - see the package.json file for details.