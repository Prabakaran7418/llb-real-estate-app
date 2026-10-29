import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_constants.dart';

class MapService {
  /// Opens Google Maps Navigation directly to the selected plot's actual coordinates.
  /// Format required:
  /// https://www.google.com/maps/dir/?api=1&destination=LATITUDE,LONGITUDE&travelmode=driving
  /// Incorporates user's starting location if permission is granted.
  static Future<bool> openDirections({
    required double latitude,
    required double longitude,
    required String title,
    String? plotId,
    String travelMode = 'driving',
  }) async {
    // Validate coordinates
    if (latitude == 0.0 || longitude == 0.0) {
      debugPrint('[MapService] Coordinates missing or invalid for $title (ID: $plotId)');
      return false;
    }

    String? originParam;

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 4),
        );
        originParam = '&origin=${position.latitude},${position.longitude}';
      }
    } catch (e) {
      debugPrint('[MapService] Location permission/GPS note: $e - Navigating directly to destination.');
    }

    // Google Maps official navigation URL with dynamic travelmode (driving, bicycling, transit, walking)
    final dest = '$latitude,$longitude';
    final originStr = originParam ?? '';
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1$originStr&destination=$dest&travelmode=$travelMode',
    );
    final fallbackUrl = Uri.parse('https://maps.google.com/?q=$dest');

    try {
      debugPrint('[MapService] Launching Google Maps Navigation: $googleMapsUrl');
      if (await canLaunchUrl(googleMapsUrl)) {
        return await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(fallbackUrl)) {
        return await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[MapService] Could not launch maps application: $e');
    }
    return false;
  }

  /// Opens WhatsApp direct chat with prefilled plot enquiry message
  static Future<bool> openWhatsApp({
    String? plotTitle,
    String? propertyTitle,
    String? plotId,
    String? plotPrice,
  }) async {
    final title = plotTitle ?? propertyTitle ?? 'LLB Residential Plot';
    final idText = plotId != null && plotId.isNotEmpty ? ' [$plotId]' : '';
    final priceText = plotPrice != null && plotPrice.isNotEmpty ? ' ($plotPrice)' : '';
    final text = Uri.encodeComponent(
      'Vanakkam LLB Real Estate, I am interested in viewing $title$idText$priceText. Please share verified CMDA documents and site visit details.',
    );
    final url = Uri.parse('https://wa.me/${AppConstants.companyWhatsApp}?text=$text');

    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[MapService] Could not launch WhatsApp: $e');
      return false;
    }
  }

  /// Initiates phone call to LLB helpline
  static Future<bool> makePhoneCall() async {
    final url = Uri.parse('tel:${AppConstants.companyPhone}');
    try {
      return await launchUrl(url);
    } catch (e) {
      debugPrint('[MapService] Could not launch phone: $e');
      return false;
    }
  }
}
