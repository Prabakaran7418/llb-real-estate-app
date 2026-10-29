enum EnquiryStatus { pending, scheduled, completed, cancelled }

class EnquiryModel {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String? propertyLocation;
  final double? propertyPrice;
  final String? propertyImage;
  final String userId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String? preferredDate;
  final String? preferredTime;
  final bool needCabPickup;
  final String? pickupAddress;
  final bool loanRequired;
  final String message;
  final EnquiryStatus status;
  final bool n8nDispatched;
  final DateTime createdAt;

  const EnquiryModel({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    this.propertyLocation,
    this.propertyPrice,
    this.propertyImage,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.preferredDate,
    this.preferredTime,
    this.needCabPickup = false,
    this.pickupAddress,
    this.loanRequired = false,
    required this.message,
    this.status = EnquiryStatus.pending,
    this.n8nDispatched = false,
    required this.createdAt,
  });

  String get statusLabel {
    switch (status) {
      case EnquiryStatus.pending:
        return 'Enquiry Received';
      case EnquiryStatus.scheduled:
        return 'Site Visit Scheduled';
      case EnquiryStatus.completed:
        return 'Visit Completed';
      case EnquiryStatus.cancelled:
        return 'Cancelled';
    }
  }

  factory EnquiryModel.fromMap(Map<String, dynamic> map, String id) {
    return EnquiryModel(
      id: id,
      propertyId: map['propertyId'] ?? '',
      propertyTitle: map['propertyTitle'] ?? '',
      propertyLocation: map['propertyLocation'],
      propertyPrice: (map['propertyPrice'] as num?)?.toDouble(),
      propertyImage: map['propertyImage'],
      userId: map['userId'] ?? '',
      customerName: map['customerName'] ?? map['fullName'] ?? '',
      customerEmail: map['customerEmail'] ?? map['email'] ?? '',
      customerPhone: map['customerPhone'] ?? map['phone'] ?? '',
      preferredDate: map['preferredDate'],
      preferredTime: map['preferredTime'],
      needCabPickup: map['needCabPickup'] ?? false,
      pickupAddress: map['pickupAddress'],
      loanRequired: map['loanRequired'] ?? false,
      message: map['message'] ?? map['notes'] ?? '',
      status: EnquiryStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => EnquiryStatus.pending,
      ),
      n8nDispatched: map['n8nDispatched'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'propertyLocation': propertyLocation,
      'propertyPrice': propertyPrice,
      'propertyImage': propertyImage,
      'userId': userId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'preferredDate': preferredDate,
      'preferredTime': preferredTime,
      'needCabPickup': needCabPickup,
      'pickupAddress': pickupAddress,
      'loanRequired': loanRequired,
      'message': message,
      'status': status.name,
      'n8nDispatched': n8nDispatched,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
