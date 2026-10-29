import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/favourite_provider.dart';
import '../../../providers/property_provider.dart';
import '../../../services/map_service.dart';
import '../../../shared/widgets/primary_button.dart';

class PropertyDetailsScreen extends ConsumerStatefulWidget {
  final String propertyId;

  const PropertyDetailsScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends ConsumerState<PropertyDetailsScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final propertyAsync = ref.watch(propertyDetailsProvider(widget.propertyId));
    final isFav = ref.watch(favouritesProvider).contains(widget.propertyId);

    return propertyAsync.when(
      data: (property) {
        if (property == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Plot Not Found')),
            body: const Center(child: Text('Plot details could not be found.')),
          );
        }

        final plotId = property.plotNumber.isNotEmpty
            ? property.plotNumber
            : property.id;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Scrollable Content
              CustomScrollView(
                slivers: [
                  // App Bar with Image Carousel
                  SliverAppBar(
                    expandedHeight: 320,
                    pinned: true,
                    backgroundColor: AppColors.background,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlack, size: 20),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? AppColors.primaryBlack : AppColors.textMuted,
                            size: 20,
                          ),
                          onPressed: () {
                            ref
                                .read(favouritesProvider.notifier)
                                .toggleFavourite(property.id);
                          },
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          PageView.builder(
                            itemCount: property.images.isNotEmpty ? property.images.length : 1,
                            onPageChanged: (idx) {
                              setState(() {
                                _currentImageIndex = idx;
                              });
                            },
                            itemBuilder: (context, index) {
                              if (property.images.isEmpty) {
                                return Container(
                                  color: AppColors.subtleGrey,
                                  child: const Icon(Icons.landscape, size: 60),
                                );
                              }
                              return Image.network(
                                property.images[index],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.subtleGrey,
                                  child: const Icon(Icons.landscape, size: 60),
                                ),
                              );
                            },
                          ),
                          // Availability Status Tag
                          Positioned(
                            top: 60,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: property.isPlotAvailable
                                    ? AppColors.primaryBlack
                                    : (property.isPlotReserved ? Colors.amber[800] : AppColors.textMuted),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                property.availabilityLabel.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                          // Image Index Indicator
                          if (property.images.length > 1)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_currentImageIndex + 1} / ${property.images.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Property Details Body
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Plot ID and Approval Tag
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlack,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  plotId.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  property.approval.split('(').first.trim().toUpperCase(),
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Title
                          Text(
                            property.title,
                            style: AppTypography.displayMedium.copyWith(fontSize: 22),
                          ),
                          const SizedBox(height: 6),

                          // Locality & Address
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  property.address.isNotEmpty ? property.address : property.locality,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Pricing Breakdown Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderGrey, width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TOTAL PLOT PRICE',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Formatters.formatCurrency(property.price),
                                      style: AppTypography.displayMedium.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                if (property.pricePerSqFt > 0)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'RATE PER SQ.FT',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${property.pricePerSqFt.toInt()}',
                                        style: AppTypography.heading3.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Technical Land Demarcation Table
                          const Text('Plot Specifications', style: AppTypography.heading3),
                          const SizedBox(height: 12),
                          if (property.dimensions.isNotEmpty)
                            _buildSpecRow('Plot Dimensions', property.dimensions),
                          _buildSpecRow('Total Plot Area', Formatters.formatSqFt(property.areaSqFt)),
                          _buildSpecRow('Vasthu Compliance', property.facing),
                          _buildSpecRow('Groundwater Level', property.waterTable),
                          _buildSpecRow('Government Sanction', property.approval),
                          _buildSpecRow('Bank Loan Tie-ups', 'Pre-Approved 90% (SBI, HDFC, ICICI)'),
                          _buildSpecRow('GPS Coordinates', '${property.latitude.toStringAsFixed(6)}, ${property.longitude.toStringAsFixed(6)}'),
                          const SizedBox(height: 24),

                          // Overview Description
                          const Text('Overview & Legal Clearance', style: AppTypography.heading3),
                          const SizedBox(height: 8),
                          Text(
                            property.description,
                            style: AppTypography.bodyMedium.copyWith(height: 1.6),
                          ),
                          const SizedBox(height: 24),

                          // Amenities
                          const Text('Infrastructure & Features', style: AppTypography.heading3),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: property.amenities.map((amenity) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  border: Border.all(color: AppColors.borderGrey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_outline, size: 14, color: AppColors.primaryBlack),
                                    const SizedBox(width: 6),
                                    Text(
                                      amenity,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // REAL GOOGLE MAPS NAVIGATION CARD
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              border: Border.all(color: AppColors.borderBlack, width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.navigation, color: AppColors.primaryBlack, size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Real Google Maps Navigation',
                                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                          ),
                                          Text(
                                            'GPS: ${property.latitude.toStringAsFixed(6)}, ${property.longitude.toStringAsFixed(6)}',
                                            style: AppTypography.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Calculate real-time driving route from your current location directly to this plot marker.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      MapService.openDirections(
                                        latitude: property.latitude,
                                        longitude: property.longitude,
                                        title: property.title,
                                        plotId: plotId,
                                      );
                                    },
                                    icon: const Icon(Icons.directions, size: 16),
                                    label: const Text('NAVIGATE TO THIS PLOT'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primaryBlack,
                                      side: const BorderSide(color: AppColors.borderBlack, width: 1.2),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // STICKY BOTTOM ACTION BAR (Strict 90% White / 10% Black)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: const Border(top: BorderSide(color: AppColors.borderGrey, width: 1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // WhatsApp Button
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderBlack, width: 1.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryBlack, size: 20),
                          tooltip: 'WhatsApp Advisor',
                          onPressed: () => MapService.openWhatsApp(
                            plotTitle: property.title,
                            plotId: plotId,
                            plotPrice: Formatters.formatCurrency(property.price),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Direct Call Button
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderBlack, width: 1.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.phone_outlined, color: AppColors.primaryBlack, size: 20),
                          tooltip: 'Call LLB Helpline',
                          onPressed: () => MapService.makePhoneCall(),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Primary Action: "Enquire About This Plot"
                      Expanded(
                        child: PrimaryButton(
                          text: property.isPlotAvailable
                              ? 'ENQUIRE ABOUT THIS PLOT'
                              : 'ENQUIRE AVAILABILITY',
                          height: 48,
                          onPressed: () {
                            context.push('/enquire/${property.id}');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlack)),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
