import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/enquiry_model.dart';
import '../models/property_model.dart';

class EnquiryDispatchResult {
  final bool success;
  final String message;
  final String? error;
  final bool adminNotified;
  final bool customerConfirmed;

  const EnquiryDispatchResult({
    required this.success,
    required this.message,
    this.error,
    this.adminNotified = false,
    this.customerConfirmed = false,
  });
}

class N8nService {
  final http.Client _client;

  N8nService({http.Client? client}) : _client = client ?? http.Client();

  /// Dispatches enquiry to the secure automation webhook.
  /// Never claims delivery unless the server confirms receipt and processing.
  Future<EnquiryDispatchResult> dispatchEnquiryWebhook({
    required EnquiryModel enquiry,
    PropertyModel? property,
  }) async {
    // Endpoints to attempt (primary configured URL, with local backend fallbacks)
    final candidateUrls = [
      AppConstants.n8nWebhookUrl,
      'http://localhost:5678/webhook/llb-chennai-events',
      'http://10.0.2.2:5678/webhook/llb-chennai-events', // Android emulator localhost
      'http://localhost:3000/webhook/llb-events',
    ];

    final plotId = property?.plotNumber.isNotEmpty == true
        ? property!.plotNumber
        : (property?.id ?? enquiry.propertyId);
    final plotLoc = property?.locality ?? (enquiry.propertyLocation ?? 'Chennai');
    final mapsUrl = property != null
        ? property.googleMapsDirectionsUrl
        : 'https://www.google.com/maps/dir/?api=1&destination=13.041042,80.199415&travelmode=driving';

    final payload = {
      'event': 'plot.enquiry',
      'enquiryId': enquiry.id,
      'timestamp': DateTime.now().toIso8601String(),
      'customer': {
        'name': enquiry.customerName,
        'email': enquiry.customerEmail,
        'phone': enquiry.customerPhone,
        'message': enquiry.message,
        'preferredDate': enquiry.preferredDate,
        'preferredTime': enquiry.preferredTime,
        'needCab': enquiry.needCabPickup,
        'pickupAddress': enquiry.pickupAddress,
        'loanRequired': enquiry.loanRequired,
      },
      'property': {
        'id': property?.id ?? enquiry.propertyId,
        'plotNumber': plotId,
        'projectName': property?.projectName ?? 'LLB Real Estate',
        'title': enquiry.propertyTitle,
        'price': property != null ? '₹${property.price / 100000} Lakhs' : (enquiry.propertyPrice != null ? '₹${enquiry.propertyPrice! / 100000} Lakhs' : 'Price on Request'),
        'priceFormatted': property != null ? '₹${(property.price / 100000).toStringAsFixed(1)} Lakhs' : 'Verified',
        'dimensions': property?.dimensions ?? '',
        'areaSqFt': property?.areaSqFt ?? 1200,
        'locality': plotLoc,
        'address': property?.address ?? plotLoc,
        'latitude': property?.latitude ?? 13.041042,
        'longitude': property?.longitude ?? 80.199415,
        'facing': property?.facing ?? 'East Facing',
        'approval': property?.approval ?? 'CMDA & RERA Approved',
        'waterTable': property?.waterTable ?? 'Sweet Potable Water at 22 ft',
        'googleMapsUrl': mapsUrl,
        'images': property?.images ?? (enquiry.propertyImage != null ? [enquiry.propertyImage!] : []),
      },
      'targetAdminEmail': 'prabakaransethu7@gmail.com',
      'company': {
        'name': AppConstants.companyFullName,
        'city': 'Chennai',
        'phone': AppConstants.companyPhone,
        'supportEmail': AppConstants.companyEmail,
      },
    };

    String lastError = 'Unable to connect to automation webhook.';

    for (final urlStr in candidateUrls) {
      try {
        final url = Uri.parse(urlStr);
        debugPrint('[n8n Service] Attempting dispatch to: $url');

        final response = await _client
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 8));

        debugPrint('[n8n Service] Response from $url: ${response.statusCode}');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final resJson = jsonDecode(response.body);
          if (resJson is Map && resJson['success'] == true) {
            return EnquiryDispatchResult(
              success: true,
              message: resJson['message'] ?? 'Enquiry notification delivered to prabakaransethu7@gmail.com',
              adminNotified: resJson['adminNotificationDelivered'] ?? true,
              customerConfirmed: resJson['customerConfirmationDelivered'] ?? false,
            );
          }
        } else {
          lastError = 'Server returned HTTP ${response.statusCode}: ${response.body}';
        }
      } catch (e) {
        lastError = e.toString();
        debugPrint('[n8n Service] Connection failed for $urlStr: $e');
      }
    }

    // Never pretend email was delivered if all endpoints failed!
    return EnquiryDispatchResult(
      success: false,
      message: 'Failed to deliver enquiry email notification.',
      error: lastError,
    );
  }
}
