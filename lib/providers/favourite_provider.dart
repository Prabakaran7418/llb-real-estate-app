import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/property_model.dart';
import 'property_provider.dart';

class FavouritesNotifier extends StateNotifier<Set<String>> {
  FavouritesNotifier() : super({}) {
    _loadFavourites();
  }

  Future<void> _loadFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(AppConstants.keyFavourites) ?? [];
    state = list.toSet();
  }

  Future<void> toggleFavourite(String propertyId) async {
    final updated = Set<String>.from(state);
    if (updated.contains(propertyId)) {
      updated.remove(propertyId);
    } else {
      updated.add(propertyId);
    }
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.keyFavourites, updated.toList());
  }

  bool isFavourite(String propertyId) => state.contains(propertyId);
}

final favouritesProvider = StateNotifierProvider<FavouritesNotifier, Set<String>>((ref) {
  return FavouritesNotifier();
});

final favouritePropertiesProvider = Provider<AsyncValue<List<PropertyModel>>>((ref) {
  final propertiesAsync = ref.watch(propertiesFutureProvider);
  final favIds = ref.watch(favouritesProvider);

  return propertiesAsync.whenData((properties) {
    return properties.where((p) => favIds.contains(p.id)).toList();
  });
});
