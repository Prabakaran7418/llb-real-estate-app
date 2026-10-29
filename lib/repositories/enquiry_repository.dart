import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enquiry_model.dart';
import '../models/property_model.dart';
import '../services/n8n_service.dart';

class EnquirySubmissionResponse {
  final EnquiryModel enquiry;
  final EnquiryDispatchResult dispatchResult;

  const EnquirySubmissionResponse({
    required this.enquiry,
    required this.dispatchResult,
  });
}

class EnquiryRepository {
  final FirebaseFirestore? _firestore;
  final N8nService _n8nService;
  final List<EnquiryModel> _localEnquiries = [];

  EnquiryRepository({
    FirebaseFirestore? firestore,
    N8nService? n8nService,
  })  : _firestore = firestore,
        _n8nService = n8nService ?? N8nService();

  /// Create and submit enquiry, then trigger n8n automated email dispatch
  Future<EnquirySubmissionResponse> submitEnquiry({
    required EnquiryModel enquiry,
    PropertyModel? property,
  }) async {
    // 1. Dispatch to n8n webhook
    final dispatchResult = await _n8nService.dispatchEnquiryWebhook(
      enquiry: enquiry,
      property: property,
    );

    final updatedEnquiry = EnquiryModel(
      id: enquiry.id,
      propertyId: enquiry.propertyId,
      propertyTitle: enquiry.propertyTitle,
      propertyLocation: enquiry.propertyLocation,
      propertyPrice: enquiry.propertyPrice,
      propertyImage: enquiry.propertyImage,
      userId: enquiry.userId,
      customerName: enquiry.customerName,
      customerEmail: enquiry.customerEmail,
      customerPhone: enquiry.customerPhone,
      preferredDate: enquiry.preferredDate,
      preferredTime: enquiry.preferredTime,
      needCabPickup: enquiry.needCabPickup,
      pickupAddress: enquiry.pickupAddress,
      loanRequired: enquiry.loanRequired,
      message: enquiry.message,
      status: enquiry.preferredDate != null && enquiry.preferredDate!.isNotEmpty
          ? EnquiryStatus.scheduled
          : EnquiryStatus.pending,
      n8nDispatched: dispatchResult.success,
      createdAt: DateTime.now(),
    );

    // 2. Persist in Firestore
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore
            .collection('enquiries')
            .doc(updatedEnquiry.id)
            .set(updatedEnquiry.toMap());
      } catch (_) {}
    }

    // 3. Keep in-memory
    _localEnquiries.insert(0, updatedEnquiry);

    return EnquirySubmissionResponse(
      enquiry: updatedEnquiry,
      dispatchResult: dispatchResult,
    );
  }

  /// Get user's enquiries
  Future<List<EnquiryModel>> getUserEnquiries(String userId) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final snap = await firestore
            .collection('enquiries')
            .where('userId', isEqualTo: userId)
            .get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((doc) => EnquiryModel.fromMap(doc.data(), doc.id))
              .toList();
        }
      } catch (_) {}
    }
    return _localEnquiries.where((e) => e.userId == userId || userId.isEmpty).toList();
  }

  /// Get all enquiries (Admin function)
  Future<List<EnquiryModel>> getAllEnquiries() async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final snap = await firestore.collection('enquiries').get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((doc) => EnquiryModel.fromMap(doc.data(), doc.id))
              .toList();
        }
      } catch (_) {}
    }
    return _localEnquiries;
  }
}
