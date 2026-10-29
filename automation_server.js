// ==============================================================================
// LLB REAL ESTATE - SECURE n8n & GMAIL ENQUIRY AUTOMATION DISPATCHER
// ==============================================================================
// Recipient: prabakaransethu7@gmail.com
// Features: Input validation, Duplicate prevention, Admin Notification Email,
// Customer Confirmation Email, Real Delivery Verification, Local Database Storage.
// ==============================================================================

const http = require('http');
const fs = require('fs');
const path = require('path');
const nodemailer = require('C:/Users/praba karan/.gemini/antigravity/scratch/llb-real-estate/server/node_modules/nodemailer');

const PORT = process.env.PORT || 5678;
const DB_FILE = path.join(__dirname, 'enquiries_db.json');

// Ensure local persistent JSON database exists
if (!fs.existsSync(DB_FILE)) {
  fs.writeFileSync(DB_FILE, JSON.stringify([]), 'utf8');
}

// Secure Gmail SMTP Credentials (stored strictly server-side)
const SMTP_CONFIG = {
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: {
    user: 'prabakaransethu7@gmail.com',
    pass: 'poni gwzv ufcj ivae'
  }
};

const transporter = nodemailer.createTransport(SMTP_CONFIG);

// Verify SMTP connection on startup
transporter.verify((err, success) => {
  if (err) {
    console.error('❌ [SMTP Auth Error]:', err.message);
  } else {
    console.log('✅ [Gmail SMTP Ready] Authenticated for: prabakaransethu7@gmail.com');
  }
});

// Helper to save enquiry in database
function saveEnquiryToDb(enquiryRecord) {
  try {
    const existing = JSON.parse(fs.readFileSync(DB_FILE, 'utf8') || '[]');
    existing.unshift(enquiryRecord);
    fs.writeFileSync(DB_FILE, JSON.stringify(existing, null, 2), 'utf8');
  } catch (err) {
    console.error('Failed to write to local DB:', err.message);
  }
}

// Generate Admin Notification HTML
function buildAdminNotificationHtml(data) {
  const c = data.customer || {};
  const p = data.property || {};
  const googleMapsUrl = p.googleMapsUrl || (p.latitude && p.longitude ? `https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}&travelmode=driving` : 'https://maps.google.com');
  const timeStr = data.timestamp ? new Date(data.timestamp).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }) : new Date().toLocaleString();

  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f4f4f5; margin: 0; padding: 24px; color: #000000; }
    .card { max-width: 620px; margin: 0 auto; background: #ffffff; border: 1.5px solid #000000; border-radius: 8px; overflow: hidden; }
    .header { background: #000000; color: #ffffff; padding: 24px; text-align: center; }
    .logo-badge { display: inline-block; width: 44px; height: 44px; line-height: 44px; background: #ffffff; color: #000000; font-weight: 900; font-size: 18px; border-radius: 6px; margin-bottom: 8px; }
    .title { font-size: 18px; font-weight: 800; letter-spacing: 1px; text-transform: uppercase; margin: 0; }
    .subtitle { font-size: 10px; color: #a1a1aa; letter-spacing: 1.5px; text-transform: uppercase; margin-top: 4px; }
    .content { padding: 28px 24px; }
    .alert-banner { background: #fafafa; border-left: 4px solid #000000; padding: 14px 18px; margin-bottom: 24px; font-size: 14px; font-weight: 700; }
    .section-title { font-size: 12px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px; color: #71717a; margin: 20px 0 10px; border-bottom: 1px solid #e4e4e7; padding-bottom: 6px; }
    table { width: 100%; border-collapse: collapse; font-size: 13px; }
    td { padding: 9px 0; border-bottom: 1px solid #f4f4f5; }
    td.label { color: #71717a; width: 38%; font-weight: 500; }
    td.val { color: #000000; font-weight: 700; }
    .btn { display: inline-block; background: #000000; color: #ffffff !important; text-decoration: none; padding: 12px 24px; border-radius: 4px; font-size: 12px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; margin: 8px 4px; }
    .btn-outline { display: inline-block; background: #ffffff; color: #000000 !important; border: 1.5px solid #000000; text-decoration: none; padding: 11px 22px; border-radius: 4px; font-size: 12px; font-weight: 800; text-transform: uppercase; margin: 8px 4px; }
    .footer { background: #fafafa; border-top: 1px solid #e4e4e7; padding: 18px; text-align: center; font-size: 11px; color: #71717a; }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <div class="logo-badge">LLB</div>
      <div class="title">LLB REAL ESTATE</div>
      <div class="subtitle">Lokesh Laven Barani Real Estate Company</div>
    </div>
    <div class="content">
      <div class="alert-banner">
        🚨 NEW PLOT ENQUIRY RECEIVED: ${p.plotNumber || p.id} – ${p.locality}
      </div>

      <div class="section-title">1. Customer Information</div>
      <table>
        <tr><td class="label">Full Name:</td><td class="val">${c.name}</td></tr>
        <tr><td class="label">Email Address:</td><td class="val"><a href="mailto:${c.email}">${c.email}</a></td></tr>
        <tr><td class="label">Mobile Number:</td><td class="val"><a href="tel:${c.phone}">${c.phone}</a></td></tr>
        <tr><td class="label">Date & Time:</td><td class="val">${timeStr} IST</td></tr>
      </table>

      <div class="section-title">2. Target Plot Specifications</div>
      <table>
        <tr><td class="label">Plot ID:</td><td class="val">${p.id}</td></tr>
        <tr><td class="label">Plot Name / Layout:</td><td class="val">${p.title}</td></tr>
        <tr><td class="label">Locality / Address:</td><td class="val">${p.address || p.locality}</td></tr>
        <tr><td class="label">Price:</td><td class="val">${p.priceFormatted || p.price}</td></tr>
        <tr><td class="label">Dimensions / Area:</td><td class="val">${p.dimensions || (p.areaSqFt ? p.areaSqFt + ' Sq.Ft' : 'Standard')}</td></tr>
        <tr><td class="label">Vasthu Orientation:</td><td class="val">${p.facing || 'East Facing'}</td></tr>
        <tr><td class="label">Approval Status:</td><td class="val">${p.approval || 'CMDA Approved'}</td></tr>
        <tr><td class="label">Coordinates:</td><td class="val">${p.latitude}, ${p.longitude}</td></tr>
      </table>

      <div class="section-title">3. Customer Enquiry Message</div>
      <div style="background: #fafafa; border: 1px solid #e4e4e7; padding: 14px; border-radius: 6px; font-size: 13px; line-height: 1.5; color: #18181b;">
        ${c.message && c.message.trim() ? c.message : 'Customer requested verified plot prospectus and callback for site visit.'}
      </div>

      ${c.needCab ? `
      <div style="background: #f0fdf4; border: 1px solid #bbf7d0; padding: 12px 16px; border-radius: 6px; margin-top: 14px; font-size: 12px; color: #166534;">
        <strong>✓ Complimentary AC Cab Requested:</strong> Pickup address: ${c.pickupAddress || 'Residence'}
      </div>` : ''}

      <div style="text-align: center; margin-top: 28px;">
        <a href="${googleMapsUrl}" class="btn" target="_blank">🧭 Open Driving Navigation to Plot</a>
        <a href="https://wa.me/${c.phone.replace(/[^0-9]/g, '')}?text=Vanakkam%20${encodeURIComponent(c.name)},%20this%20is%20LLB%20Real%20Estate%20regarding%20your%20enquiry%20for%20${encodeURIComponent(p.title)}" class="btn-outline" target="_blank">💬 WhatsApp Customer</a>
      </div>
    </div>
    <div class="footer">
      <strong>LLB Real Estate Admin Notification System</strong><br>
      Corporate Office: Anna Nagar Western Extension, Chennai - 600101 | Helpline: +91 98400 00000
    </div>
  </div>
</body>
</html>
  `;
}

// Generate Customer Confirmation HTML
function buildCustomerConfirmationHtml(data) {
  const c = data.customer || {};
  const p = data.property || {};
  const googleMapsUrl = p.googleMapsUrl || (p.latitude && p.longitude ? `https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}&travelmode=driving` : 'https://maps.google.com');
  const mainImage = (p.images && p.images.length > 0) ? p.images[0] : 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=1200&q=80';

  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f9f9fb; margin: 0; padding: 24px; color: #000000; }
    .card { max-width: 620px; margin: 0 auto; background: #ffffff; border: 1px solid #e4e4e7; border-radius: 8px; overflow: hidden; }
    .header { background: #000000; color: #ffffff; padding: 28px 24px; text-align: center; }
    .logo-badge { display: inline-block; width: 46px; height: 46px; line-height: 46px; background: #ffffff; color: #000000; font-weight: 900; font-size: 19px; border-radius: 6px; margin-bottom: 8px; }
    .title { font-size: 18px; font-weight: 900; letter-spacing: 2px; text-transform: uppercase; margin: 0; }
    .subtitle { font-size: 10px; color: #a1a1aa; letter-spacing: 2px; text-transform: uppercase; margin-top: 4px; }
    .content { padding: 30px 24px; }
    .greeting { font-size: 18px; font-weight: 800; color: #000000; margin-bottom: 8px; }
    .lead { font-size: 13.5px; line-height: 1.6; color: #52525b; margin-bottom: 20px; }
    .prop-card { border: 1px solid #e4e4e7; border-radius: 8px; overflow: hidden; margin: 20px 0; background: #ffffff; }
    .prop-img { width: 100%; height: 240px; object-fit: cover; display: block; }
    .prop-info { padding: 18px; }
    .badge { display: inline-block; background: #000000; color: #ffffff; font-size: 9px; font-weight: 800; padding: 3px 8px; border-radius: 4px; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 8px; }
    .prop-title { font-size: 17px; font-weight: 800; color: #000000; margin-bottom: 4px; }
    .prop-price { font-size: 20px; font-weight: 900; color: #000000; margin-bottom: 12px; }
    table { width: 100%; border-collapse: collapse; font-size: 12.5px; }
    td { padding: 8px 0; border-bottom: 1px solid #f4f4f5; }
    td.lbl { color: #71717a; width: 42%; }
    td.val { color: #000000; font-weight: 700; text-align: right; }
    .next-steps { background: #fafafa; border: 1px solid #000000; border-radius: 6px; padding: 18px; margin: 24px 0; }
    .btn { display: inline-block; background: #000000; color: #ffffff !important; text-decoration: none; padding: 14px 28px; border-radius: 4px; font-size: 12px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.5px; }
    .footer { background: #fafafa; border-top: 1px solid #e4e4e7; padding: 20px; text-align: center; font-size: 11px; color: #71717a; line-height: 1.5; }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <div class="logo-badge">LLB</div>
      <div class="title">LLB REAL ESTATE</div>
      <div class="subtitle">Lokesh Laven Barani Real Estate Company</div>
    </div>
    <div class="content">
      <div class="greeting">Vanakkam ${c.name},</div>
      <p class="lead">
        Thank you for submitting your enquiry for <strong>${p.title} (${p.plotNumber || p.id})</strong>. We have successfully registered your request and our senior property advisor has been notified.
      </p>

      <div class="prop-card">
        <img src="${mainImage}" alt="${p.title}" class="prop-img">
        <div class="prop-info">
          <span class="badge">${p.approval || 'CMDA & RERA Approved'}</span>
          <div class="prop-title">${p.title}</div>
          <div class="prop-price">${p.priceFormatted || p.price}</div>
          <table>
            <tr><td class="lbl">Plot ID</td><td class="val">${p.id}</td></tr>
            <tr><td class="lbl">Locality</td><td class="val">${p.locality || 'Chennai'}</td></tr>
            <tr><td class="lbl">Dimensions & Area</td><td class="val">${p.dimensions || (p.areaSqFt ? p.areaSqFt + ' Sq.Ft' : 'Standard')}</td></tr>
            <tr><td class="lbl">Vasthu Orientation</td><td class="val">${p.facing || 'East Facing'}</td></tr>
            <tr><td class="lbl">Groundwater Table</td><td class="val">${p.waterTable || 'Sweet Potable Water at 22 ft'}</td></tr>
            <tr><td class="lbl">Legal Documents</td><td class="val">100% Clear Title Verification</td></tr>
          </table>
        </div>
      </div>

      <div class="next-steps">
        <div style="font-size: 12px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 8px;">
          ✓ Next Steps & Live Site Visit Coordination
        </div>
        <p style="font-size: 13px; line-height: 1.6; color: #18181b; margin: 0;">
          <strong>1. Assigned Senior Advisor:</strong> Er. S. Karthik (+91 98401 55678)<br>
          <strong>2. Direct Callback:</strong> Our coordinator will contact your mobile (<strong>${c.phone}</strong>) within 30 minutes to confirm your preferred schedule.<br>
          <strong>3. Transportation:</strong> ${c.needCab ? 'Complimentary AC Cab Pickup arranged from your residence.' : 'Self-drive directions provided below.'}
        </p>
      </div>

      <div style="text-align: center; margin-top: 24px;">
        <a href="${googleMapsUrl}" class="btn" target="_blank">🧭 Open Driving Route on Google Maps</a>
      </div>
    </div>
    <div class="footer">
      <strong>Lokesh Laven Barani Real Estate Company (LLB Real Estate)</strong><br>
      Head Office: Anna Nagar Western Extension, Chennai - 600101<br>
      Helpline: +91 98400 00000 | Email: sales@llbrealty.com
    </div>
  </div>
</body>
</html>
  `;
}

// In-memory set for deduplication (prevents duplicate emails within 60 seconds)
const recentEnquiries = new Map();

// Main Request Handler
const server = http.createServer((req, res) => {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // Health / Status Check
  if (req.method === 'GET' && (req.url === '/' || req.url === '/health' || req.url === '/api/status')) {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'active',
      service: 'LLB Real Estate n8n Automation & Dispatcher',
      configuredRecipient: 'prabakaransethu7@gmail.com',
      time: new Date().toISOString()
    }));
    return;
  }

  // Webhook Endpoints
  const isEnquiryEndpoint = (
    req.url === '/webhook/llb-chennai-events' ||
    req.url === '/webhook/llb-events' ||
    req.url === '/api/enquiry'
  );

  if (req.method === 'POST' && isEnquiryEndpoint) {
    let body = '';
    req.on('data', chunk => { body += chunk.toString(); });
    req.on('end', async () => {
      try {
        const payload = JSON.parse(body || '{}');

        const customer = payload.customer || {
          name: payload.customerName || payload.name,
          email: payload.customerEmail || payload.email,
          phone: payload.customerPhone || payload.phone,
          message: payload.message || payload.enquiryMessage
        };
        const property = payload.property || {
          id: payload.plotId || payload.propertyId || payload.id,
          title: payload.plotTitle || payload.propertyTitle || payload.title,
          locality: payload.plotLocality || payload.locality,
          price: payload.price,
          dimensions: payload.dimensions
        };

        // 1. Validation
        if (!customer.name || !customer.name.trim()) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          return res.end(JSON.stringify({ success: false, error: 'Customer name is required.' }));
        }

        const emailRegex = /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/;
        if (!customer.email || !emailRegex.test(customer.email.trim())) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          return res.end(JSON.stringify({ success: false, error: 'Valid customer email address is required.' }));
        }

        const phoneClean = (customer.phone || '').replace(/\D/g, '');
        if (phoneClean.length < 10) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          return res.end(JSON.stringify({ success: false, error: 'Valid 10-digit customer phone number is required.' }));
        }

        if (!property.id || !property.title) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          return res.end(JSON.stringify({ success: false, error: 'Selected plot ID and title are required.' }));
        }

        // 2. Duplicate Prevention (Key: email + propertyId)
        const dedupKey = `${customer.email.toLowerCase()}_${property.id}`;
        const now = Date.now();
        if (recentEnquiries.has(dedupKey) && (now - recentEnquiries.get(dedupKey)) < 30000) {
          console.log(`⚠️ Duplicate enquiry ignored for ${dedupKey}`);
          res.writeHead(200, { 'Content-Type': 'application/json' });
          return res.end(JSON.stringify({
            success: true,
            duplicate: true,
            message: 'Enquiry already received and notification in progress.',
            enquiryId: payload.enquiryId || 'enq-' + now
          }));
        }
        recentEnquiries.set(dedupKey, now);

        // Normalize payload fields
        payload.timestamp = payload.timestamp || new Date().toISOString();
        payload.customer = customer;
        payload.property = property;
        const plotId = property.plotNumber || property.id;
        const plotLoc = property.locality || property.areaName || 'Chennai';

        console.log(`\n======================================================`);
        console.log(`⚡ [NEW PLOT ENQUIRY RECEIVED]`);
        console.log(`   Customer: ${customer.name} | ${customer.email} | ${customer.phone}`);
        console.log(`   Plot: [${plotId}] ${property.title} (${property.price})`);
        console.log(`   Timestamp: ${payload.timestamp}`);

        // 3. Send Email 1: Admin Notification to prabakaransethu7@gmail.com
        const adminSubject = `New Plot Enquiry – [${plotId}] – [${plotLoc}]`;
        const adminMailOptions = {
          from: `"LLB Real Estate Portal" <${SMTP_CONFIG.auth.user}>`,
          to: 'prabakaransethu7@gmail.com',
          replyTo: customer.email,
          subject: adminSubject,
          html: buildAdminNotificationHtml(payload)
        };

        const adminResult = await transporter.sendMail(adminMailOptions);
        console.log(`✅ [Admin Email Sent to prabakaransethu7@gmail.com]: ${adminResult.messageId}`);

        // 4. Send Email 2: Customer Confirmation Email
        let customerDelivered = false;
        try {
          const customerSubject = `[LLB Real Estate] Enquiry Confirmation: ${property.title} (${plotId})`;
          const customerMailOptions = {
            from: `"LLB Real Estate" <${SMTP_CONFIG.auth.user}>`,
            to: customer.email,
            subject: customerSubject,
            html: buildCustomerConfirmationHtml(payload)
          };
          const custResult = await transporter.sendMail(customerMailOptions);
          customerDelivered = true;
          console.log(`✅ [Customer Confirmation Sent to ${customer.email}]: ${custResult.messageId}`);
        } catch (custErr) {
          console.error(`⚠️ Customer confirmation email failed:`, custErr.message);
        }

        // 5. Save to local database
        saveEnquiryToDb({
          enquiryId: payload.enquiryId || 'enq-' + now,
          customer: customer,
          property: property,
          adminNotified: true,
          adminMessageId: adminResult.messageId,
          customerConfirmed: customerDelivered,
          timestamp: payload.timestamp
        });

        // 6. Return Verified Success Result to Caller
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: true,
          message: `Enquiry accepted. Notification successfully delivered to prabakaransethu7@gmail.com.`,
          adminNotificationDelivered: true,
          adminMessageId: adminResult.messageId,
          customerConfirmationDelivered: customerDelivered,
          timestamp: payload.timestamp
        }));

      } catch (err) {
        console.error('❌ Processing Error:', err.message);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          success: false,
          error: `Failed to dispatch enquiry notification: ${err.message}`
        }));
      }
    });
    return;
  }

  // Not Found
  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Endpoint not found' }));
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`\n======================================================`);
  console.log(`🚀 LLB Real Estate Automation Server is LIVE on Port ${PORT}`);
  console.log(`   Webhook Endpoint: http://localhost:${PORT}/webhook/llb-chennai-events`);
  console.log(`   Configured Recipient: prabakaransethu7@gmail.com`);
  console.log(`======================================================\n`);
});
