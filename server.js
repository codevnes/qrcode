const express = require('express');
const { QRPay, BanksObject } = require('vietnam-qr-pay');
const QRCode = require('qrcode');
const path = require('path');

const app = express();
const port = process.env.PORT || 3000;

// Middleware to parse JSON bodies (for POST requests)
app.use(express.json());

// Trust proxy headers if the app is behind a reverse proxy
app.set('trust proxy', true);

// Serve static files from the public directory
app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
  res.send('Hello World!');
});

// Endpoint to generate and save QR code image
app.all('/generate-qr', async (req, res) => {
  try {
    const { bankKey, bankAccount, amount, message } = req.method === 'GET' ? req.query : req.body;

    if (!bankKey || !bankAccount) {
        return res.status(400).json({ error: 'Missing required parameters: bankKey and bankAccount' });
    }

    // Check if the bankKey is valid
    if (!BanksObject[bankKey]) {
        return res.status(400).json({ error: `Invalid bankKey: ${bankKey}. Please provide a valid bank identifier.` });
    }

    const qrPay = QRPay.initVietQR({
        bankBin: BanksObject[bankKey].bin,
        bankNumber: bankAccount,
        amount: amount,
        purpose: message || '',
    });

    const qrString = qrPay.build();

    // Common QR code generation options
    const qrOptions = {
      errorCorrectionLevel: 'H',
      margin: 1,
      width: 400, // Internal generation width
      color: {
        dark:"#000000", // Black dots
        light:"#FFFFFF" // White background
      }
    };

    // Check Accept header to decide response format
    const accepts = req.accepts(['html', 'image/png']);

    if (accepts === 'image/png') {
      // Generate QR code as buffer and send as PNG image
      const buffer = await QRCode.toBuffer(qrString, qrOptions);
      res.setHeader('Content-Type', 'image/png');
      res.send(buffer);
    } else { // Default to HTML or if specifically requested
      // Generate the QR code as a data URL for embedding in HTML
      const dataUrl = await QRCode.toDataURL(qrString, qrOptions);

      // Construct the HTML response
      const htmlContent = `
<!DOCTYPE html>
<html style="height: 100%;">
  <head>
    <meta name="viewport" content="width=device-width, minimum-scale=0.1">
    <title>QR Code Payment</title>
  </head>
  <body style="margin: 0px; height: 100%; background-color: rgb(14, 14, 14); display: flex; justify-content: center; align-items: center;">
    <img style="display: block; width: 256px; height: 256px; -webkit-user-select: none; background-color: hsl(0, 0%, 100%); transition: background-color 300ms;" src="${dataUrl}">
  </body>
</html>`;
      // Set content type and send HTML
      res.setHeader('Content-Type', 'text/html');
      res.send(htmlContent);
    }

  } catch (error) {
      console.error('Error generating QR code page:', error);
      res.status(500).json({
          success: false,
          error: 'Failed to generate QR code page',
          details: error.message
      });
  }
});

app.listen(port, () => {
  console.log(`Example app listening at http://localhost:${port}`);
});
