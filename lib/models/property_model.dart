enum PropertyType { plot, villa, apartment, commercial }

class PropertyModel {
  final String id;
  final String plotNumber;
  final String projectName;
  final String title;
  final String description;
  final double price;
  final double pricePerSqFt;
  final PropertyType type;
  final int bedrooms;
  final int bathrooms;
  final double areaSqFt;
  final String dimensions;
  final String facing;
  final String approval;
  final String waterTable;
  final String address;
  final String locality;
  final double latitude;
  final double longitude;
  final List<String> images;
  final List<String> amenities;
  final List<String> nearbyLandmarks;
  final String availability; // 'available', 'reserved', 'sold'
  final bool isFeatured;
  final bool isAvailable;
  final DateTime createdAt;

  const PropertyModel({
    required this.id,
    this.plotNumber = '',
    this.projectName = '',
    required this.title,
    required this.description,
    required this.price,
    required this.pricePerSqFt,
    required this.type,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqFt,
    this.dimensions = '',
    required this.facing,
    required this.approval,
    required this.waterTable,
    required this.address,
    required this.locality,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.amenities,
    required this.nearbyLandmarks,
    this.availability = 'available',
    this.isFeatured = false,
    this.isAvailable = true,
    required this.createdAt,
  });

  bool get isPlotAvailable => availability.toLowerCase() == 'available' && isAvailable;
  bool get isPlotReserved => availability.toLowerCase() == 'reserved';
  bool get isPlotSold => availability.toLowerCase() == 'sold';

  String get availabilityLabel {
    switch (availability.toLowerCase()) {
      case 'reserved':
        return 'Reserved Plot';
      case 'sold':
        return 'Sold Out';
      case 'available':
      default:
        return 'Available Plot';
    }
  }

  String get typeLabel {
    switch (type) {
      case PropertyType.plot:
        return 'Demarcated Plot';
      case PropertyType.villa:
        return 'Independent Villa';
      case PropertyType.apartment:
        return 'Luxury Apartment';
      case PropertyType.commercial:
        return 'Commercial Space';
    }
  }

  String get googleMapsDirectionsUrl {
    return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';
  }

  factory PropertyModel.fromMap(Map<String, dynamic> map, String id) {
    return PropertyModel(
      id: id,
      plotNumber: map['plotNumber'] ?? '',
      projectName: map['projectName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      pricePerSqFt: (map['pricePerSqFt'] as num?)?.toDouble() ?? 0.0,
      type: PropertyType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'plot'),
        orElse: () => PropertyType.plot,
      ),
      bedrooms: (map['bedrooms'] as num?)?.toInt() ?? 0,
      bathrooms: (map['bathrooms'] as num?)?.toInt() ?? 0,
      areaSqFt: (map['areaSqFt'] as num?)?.toDouble() ?? 0.0,
      dimensions: map['dimensions'] ?? '',
      facing: map['facing'] ?? 'East Facing',
      approval: map['approval'] ?? 'CMDA & RERA Approved',
      waterTable: map['waterTable'] ?? 'Sweet Potable Water at 22 ft',
      address: map['address'] ?? '',
      locality: map['locality'] ?? 'Chennai',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 13.041042,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 80.199415,
      images: List<String>.from(map['images'] ?? []),
      amenities: List<String>.from(map['amenities'] ?? []),
      nearbyLandmarks: List<String>.from(map['nearbyLandmarks'] ?? []),
      availability: map['availability'] ?? 'available',
      isFeatured: map['isFeatured'] ?? false,
      isAvailable: map['isAvailable'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plotNumber': plotNumber,
      'projectName': projectName,
      'title': title,
      'description': description,
      'price': price,
      'pricePerSqFt': pricePerSqFt,
      'type': type.name,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'areaSqFt': areaSqFt,
      'dimensions': dimensions,
      'facing': facing,
      'approval': approval,
      'waterTable': waterTable,
      'address': address,
      'locality': locality,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'amenities': amenities,
      'nearbyLandmarks': nearbyLandmarks,
      'availability': availability,
      'isFeatured': isFeatured,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
