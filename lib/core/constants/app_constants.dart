class AppConstants {
  static const String appName = 'LLB Real Estate';
  static const String companyFullName = 'Lokesh Laven Barani Real Estate Company';
  static const String companyTagline = 'CMDA & RERA Approved Residential Properties';
  static const String companyPhone = '+91 98400 00000';
  static const String companyWhatsApp = '919840000000';
  static const String companyEmail = 'sales@llbrealty.com';
  static const String companyOffice = 'Anna Nagar Western Extension, Chennai - 600101';

  // Default Map Coordinates (Chennai Central / Anna Nagar)
  static const double defaultLatitude = 13.0827;
  static const double defaultLongitude = 80.2707;
  static const double defaultMapZoom = 12.0;

  // n8n Webhook Endpoint for Enquiry Dispatch (Configured for local n8n / automation server)
  static const String n8nWebhookUrl =
      'http://localhost:5678/webhook/llb-chennai-events';

  // Local storage keys
  static const String keyAuthToken = 'llb_auth_token';
  static const String keyUserEmail = 'llb_user_email';
  static const String keyFavourites = 'llb_user_favourites';
}
