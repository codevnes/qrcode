const express = require('express');
const { QRPay, BanksObject } = require('vietnam-qr-pay');
const QRCode = require('qrcode');

const app = express();
const port = 3000;

// Middleware to parse JSON bodies (for POST requests)
app.use(express.json());

app.get('/', (req, res) => {
  res.send('Hello World!');
});

// Existing generate-qr endpoint
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
        bankBin: BanksObject[bankKey].bin, //mbbank
        bankNumber: bankAccount,
        amount: amount,
        purpose: message || '',
    });

    const qrString = qrPay.build();
    
    // Send HTML response with just the QR code image
    res.send(`
      <img src="${await QRCode.toDataURL(qrString, {
        errorCorrectionLevel: 'H',
        margin: 1,
        width: 400
      })}" alt="QR Code" style="display: block; max-width: 100%; height: auto;" />
    `);

  } catch (error) {
      console.error('Error generating QR code:', error);
      res.status(500).json({
          success: false,
          error: 'Failed to generate QR code',
          details: error.message
      });
  }
});

app.listen(port, () => {
  console.log(`Example app listening at http://localhost:${port}`);
}); 
