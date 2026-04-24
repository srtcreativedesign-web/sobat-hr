const express = require('express');
const { Client, LocalAuth } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');

const app = express();
app.use(express.json());

// Inisialisasi WhatsApp Client dengan LocalAuth agar sesi tersimpan
const client = new Client({
    authStrategy: new LocalAuth(),
    puppeteer: {
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-accelerated-2d-canvas',
            '--no-first-run',
            '--no-zygote',
            '--single-process',
            '--disable-gpu'
        ]
    }
});

client.on('qr', (qr) => {
    console.log('\n--- SCAN QR CODE DI BAWAH INI DENGAN WHATSAPP ANDA ---');
    qrcode.generate(qr, { small: true });
});

client.on('ready', () => {
    console.log('\n✅ WhatsApp Client is READY!');
    console.log('🤖 Bot pengirim OTP telah siap.');
});

client.on('disconnected', (reason) => {
    console.log('WhatsApp terputus!', reason);
    // client.initialize(); // Coba inisialisasi ulang jika ingin auto-reconnect tanpa disadari
});

client.initialize();

// Endpoint Internal untuk menerima request dari Laravel
app.post('/send-otp', async (req, res) => {
    const { number, message } = req.body;

    if (!number || !message) {
        return res.status(400).json({ error: 'Number dan message wajib diisi' });
    }

    // Format nomor WA untuk Indonesia: 6281234567890@c.us
    // Pastikan Laravel mengirim format nomor yang sudah diawali 62
    const chatId = `${number}@c.us`;

    try {
        await client.sendMessage(chatId, message);
        console.log(`[SUKSES] OTP terkirim ke: ${number}`);
        res.status(200).json({ status: 'success', message: 'OTP Terkirim' });
    } catch (error) {
        console.error(`[GAGAL] Gagal mengirim WA ke ${number}:`, error);
        res.status(500).json({ status: 'error', error: error.toString() });
    }
});

const PORT = 3000;
app.listen(PORT, '127.0.0.1', () => {
    console.log(`\n🚀 SOBAT WA Microservice berjalan di internal port ${PORT}`);
});
