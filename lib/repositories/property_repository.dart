import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property_model.dart';
import '../services/seed_data.dart';

class PropertyRepository {
  final FirebaseFirestore? _firestore;
  List<PropertyModel> _inMemoryProperties = [];

  PropertyRepository({FirebaseFirestore? firestore}) : _firestore = firestore {
    _inMemoryProperties = List.from(SeedData.chennaiProperties);
  }

  /// Get all properties
  Future<List<PropertyModel>> getProperties() async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final snapshot = await firestore.collection('properties').get();
        if (snapshot.docs.isNotEmpty) {
          final list = snapshot.docs
              .map((doc) => PropertyModel.fromMap(doc.data(), doc.id))
              .toList();
          _inMemoryProperties = list;
          return list;
        }
      } catch (_) {}
    }
    return _inMemoryProperties;
  }

  /// Get single property by ID
  Future<PropertyModel?> getPropertyById(String id) async {
    final properties = await getProperties();
    try {
      return properties.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add new property (Admin function)
  Future<void> addProperty(PropertyModel property) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('properties').doc(property.id).set(property.toMap());
      } catch (_) {}
    }
    _inMemoryProperties.insert(0, property);
  }

  /// Delete property (Admin function)
  Future<void> deleteProperty(String id) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection('properties').doc(id).delete();
      } catch (_) {}
    }
    _inMemoryProperties.removeWhere((p) => p.id == id);
  }
}
