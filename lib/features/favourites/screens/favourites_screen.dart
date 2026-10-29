import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../providers/favourite_provider.dart';
import '../../../shared/widgets/property_card.dart';

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favouritePropertiesAsync = ref.watch(favouritePropertiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Properties'),
      ),
      body: favouritePropertiesAsync.when(
        data: (properties) {
          if (properties.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.subtleGrey,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_border, size: 32, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    const Text('No Saved Properties', style: AppTypography.heading2),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the heart icon on any property card to save it for quick reference and comparison.',
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlack,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('EXPLORE PROPERTIES'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: properties.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return PropertyCard(property: properties[index]);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlack),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
