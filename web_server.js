const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');

const PORT = 8080;
const BUILD_WEB_DIR = path.join(__dirname, 'build', 'web');
const MOBILE_HTML_PATH = path.join(__dirname, 'mobile_app.html');
const APK_PATH = path.join(__dirname, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk');

// Helper to get local Wi-Fi / LAN IP
function getLocalIp() {
  const nets = os.networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === 'IPv4' && !net.internal) {
        return net.address;
      }
    }
  }
  return 'localhost';
}

const LOCAL_IP = getLocalIp();

const MIME_TYPES = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.json': 'application/json',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.wav': 'audio/wav',
  '.mp4': 'video/mp4',
  '.woff': 'application/font-woff',
  '.ttf': 'application/font-ttf',
  '.eot': 'application/vnd.ms-fontobject',
  '.otf': 'application/font-otf',
  '.wasm': 'application/wasm',
  '.apk': 'application/vnd.android.package-archive'
};

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
  res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');

  let reqUrl = req.url.split('?')[0];

  // 1. Direct APK Download endpoints
  if (reqUrl === '/download-apk' || reqUrl === '/app-release.apk' || reqUrl === '/apk') {
    if (fs.existsSync(APK_PATH)) {
      const stat = fs.statSync(APK_PATH);
      res.writeHead(200, {
        'Content-Type': 'application/vnd.android.package-archive',
        'Content-Length': stat.size,
        'Content-Disposition': 'attachment; filename="LLB_Real_Estate_Chennai.apk"'
      });
      fs.createReadStream(APK_PATH).pipe(res);
    } else {
      res.writeHead(404, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end(`
        <!DOCTYPE html>
        <html>
        <head><title>APK Compiling</title><meta name="viewport" content="width=device-width, initial-scale=1"></head>
        <body style="font-family:sans-serif;text-align:center;padding:40px;background:#f8f9fa;">
          <h2>⏳ Android APK is currently compiling...</h2>
          <p>Please refresh this page in a moment to download.</p>
        </body>
        </html>
      `);
    }
    return;
  }

  // 2. Mobile Install & Download Landing Page
  if (reqUrl === '/download' || reqUrl === '/install') {
    const apkExists = fs.existsSync(APK_PATH);
    const apkSizeMb = apkExists ? (fs.statSync(APK_PATH).size / (1024 * 1024)).toFixed(1) : null;

    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(`
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Download LLB Real Estate App (Android APK)</title>
        <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800;900&display=swap" rel="stylesheet">
        <style>
          * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Plus Jakarta Sans', sans-serif; }
          body { background: #0b0f19; color: #fff; min-height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 24px; }
          .card { background: #131926; border: 1px solid #232d42; border-radius: 24px; max-width: 460px; width: 100%; padding: 36px 28px; text-align: center; box-shadow: 0 20px 60px rgba(0,0,0,0.6); }
          .logo-badge { width: 72px; height: 72px; background: #000; border: 2px solid #334155; border-radius: 20px; display: inline-flex; align-items: center; justify-content: center; font-size: 28px; font-weight: 900; color: #fff; margin-bottom: 20px; box-shadow: 0 8px 24px rgba(0,0,0,0.5); }
          h1 { font-size: 22px; font-weight: 900; margin-bottom: 6px; letter-spacing: 0.5px; }
          .tagline { color: #94a3b8; font-size: 13px; margin-bottom: 24px; line-height: 1.5; }
          .features { background: #0a0e17; border: 1px solid #1e293b; border-radius: 16px; padding: 16px; text-align: left; margin-bottom: 24px; }
          .feature-item { font-size: 13px; color: #cbd5e1; display: flex; align-items: center; margin-bottom: 8px; }
          .feature-item:last-child { margin-bottom: 0; }
          .feature-item span { color: #10b981; margin-right: 8px; font-weight: bold; }
          .btn-download { display: block; width: 100%; background: #ffffff; color: #000000; text-decoration: none; padding: 16px; border-radius: 14px; font-weight: 800; font-size: 15px; letter-spacing: 0.5px; transition: transform 0.15s, background 0.15s; box-shadow: 0 10px 25px rgba(255,255,255,0.15); margin-bottom: 14px; }
          .btn-download:hover { background: #e2e8f0; transform: translateY(-2px); }
          .btn-secondary { display: block; width: 100%; background: #1e293b; color: #94a3b8; text-decoration: none; padding: 12px; border-radius: 12px; font-weight: 600; font-size: 13px; margin-bottom: 12px; }
          .btn-secondary:hover { background: #334155; color: #fff; }
          .qr-box { margin-top: 20px; padding: 16px; background: #0a0e17; border-radius: 16px; border: 1px solid #1e293b; }
          .qr-box img { width: 140px; height: 140px; border-radius: 8px; }
          .qr-caption { font-size: 11px; color: #64748b; margin-top: 8px; }
          .instructions { margin-top: 20px; font-size: 11.5px; color: #64748b; line-height: 1.6; text-align: left; background: rgba(0,0,0,0.2); padding: 12px; border-radius: 10px; }
        </style>
      </head>
      <body>
        <div class="card">
          <div class="logo-badge">LLB</div>
          <h1>LLB Real Estate Mobile</h1>
          <p class="tagline">Chennai Residential Plots & Villas with Google Maps Navigation</p>

          <div class="features">
            <div class="feature-item"><span>✓</span> 100% Genuine Google Maps Plot Discovery</div>
            <div class="feature-item"><span>✓</span> Multi-Modal Animated Navigation (Car, Bike, Bus, Walk)</div>
            <div class="feature-item"><span>✓</span> 90% White Luxury Architecture & Villa Showcases</div>
            <div class="feature-item"><span>✓</span> Instant n8n Plot Enquiry Automation</div>
          </div>

          <a href="/download-apk" class="btn-download">
            📥 DOWNLOAD ANDROID APK ${apkSizeMb ? '(' + apkSizeMb + ' MB)' : ''}
          </a>

          <a href="/mobile" class="btn-secondary">
            📱 Open in Browser Mobile Device Runner
          </a>
          <a href="/" class="btn-secondary">
            🌐 Open Full Web Experience
          </a>

          <div class="qr-box">
            <img src="https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=http://${LOCAL_IP}:${PORT}/download-apk" alt="Scan to Download APK">
            <p class="qr-caption">Scan with Smartphone Camera on same Wi-Fi to install<br><strong>http://${LOCAL_IP}:${PORT}/download</strong></p>
          </div>

          <div class="instructions">
            <strong>📲 How to Install on Smartphone:</strong><br>
            1. Scan QR code or visit <code>http://${LOCAL_IP}:${PORT}/download</code> on phone browser.<br>
            2. Tap <strong>Download Android APK</strong>.<br>
            3. Tap downloaded file and select <strong>Install</strong> (enable "Install unknown apps" if prompted).<br>
            4. Open LLB Real Estate and explore plots directly!
          </div>
        </div>
      </body>
      </html>
    `);
    return;
  }

  // 3. Mobile Runner
  if (reqUrl === '/mobile' || reqUrl === '/mobile_app.html') {
    fs.readFile(MOBILE_HTML_PATH, (err, content) => {
      if (err) {
        res.writeHead(500);
        res.end('Error loading mobile_app.html');
      } else {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(content, 'utf-8');
      }
    });
    return;
  }

  // 4. Flutter Web Build Files
  let filePath = path.join(BUILD_WEB_DIR, reqUrl === '/' ? 'index.html' : reqUrl);
  let extname = String(path.extname(filePath)).toLowerCase();
  let contentType = MIME_TYPES[extname] || 'application/octet-stream';

  fs.readFile(filePath, (error, content) => {
    if (error) {
      if (error.code === 'ENOENT') {
        fs.readFile(path.join(BUILD_WEB_DIR, 'index.html'), (err2, content2) => {
          if (err2) {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('File not found');
          } else {
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(content2, 'utf-8');
          }
        });
      } else {
        res.writeHead(500);
        res.end('Server Error: ' + error.code);
      }
    } else {
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content, 'utf-8');
    }
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`======================================================`);
  console.log(`🚀 LLB Real Estate Server running at:`);
  console.log(`   👉 Smartphone Download Page: http://${LOCAL_IP}:${PORT}/download`);
  console.log(`   👉 Direct APK Download:      http://${LOCAL_IP}:${PORT}/download-apk`);
  console.log(`   👉 Localhost Download Page:  http://localhost:${PORT}/download`);
  console.log(`   👉 Mobile Device Runner:     http://localhost:${PORT}/mobile`);
  console.log(`   👉 Web Application:          http://localhost:${PORT}/`);
  console.log(`======================================================`);
});
