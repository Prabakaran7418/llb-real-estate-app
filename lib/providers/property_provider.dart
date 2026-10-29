import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/property_model.dart';
import '../repositories/property_repository.dart';

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepository();
});

final propertiesFutureProvider = FutureProvider<List<PropertyModel>>((ref) async {
  final repo = ref.watch(propertyRepositoryProvider);
  return repo.getProperties();
});

// Category filter: null for All, or PropertyType
final propertyCategoryFilterProvider = StateProvider<PropertyType?>((ref) => null);

// Search Query
final propertySearchQueryProvider = StateProvider<String>((ref) => '');

// Filtered Properties Provider
final filteredPropertiesProvider = Provider<AsyncValue<List<PropertyModel>>>((ref) {
  final propertiesAsync = ref.watch(propertiesFutureProvider);
  final filterType = ref.watch(propertyCategoryFilterProvider);
  final searchQuery = ref.watch(propertySearchQueryProvider).toLowerCase().trim();

  return propertiesAsync.whenData((properties) {
    return properties.where((property) {
      final matchesCategory = filterType == null || property.type == filterType;
      final matchesSearch = searchQuery.isEmpty ||
          property.title.toLowerCase().contains(searchQuery) ||
          property.locality.toLowerCase().contains(searchQuery) ||
          property.address.toLowerCase().contains(searchQuery) ||
          property.facing.toLowerCase().contains(searchQuery);

      return matchesCategory && matchesSearch;
    }).toList();
  });
});

// Featured Properties Provider
final featuredPropertiesProvider = Provider<AsyncValue<List<PropertyModel>>>((ref) {
  final propertiesAsync = ref.watch(propertiesFutureProvider);
  return propertiesAsync.whenData((properties) {
    return properties.where((p) => p.isFeatured).toList();
  });
});

// Single Property Provider
final propertyDetailsProvider = FutureProvider.family<PropertyModel?, String>((ref, id) async {
  final repo = ref.watch(propertyRepositoryProvider);
  return repo.getPropertyById(id);
});
