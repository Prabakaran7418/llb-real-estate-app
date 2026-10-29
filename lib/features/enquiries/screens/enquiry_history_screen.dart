import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/enquiry_model.dart';
import '../../../providers/enquiry_provider.dart';
import '../../../services/map_service.dart';

class EnquiryHistoryScreen extends ConsumerWidget {
  const EnquiryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enquiriesAsync = ref.watch(userEnquiriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Enquiries & Visits'),
      ),
      body: enquiriesAsync.when(
        data: (enquiries) {
          if (enquiries.isEmpty) {
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
                      child: const Icon(Icons.event_note, size: 32, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Active Enquiries',
                      style: AppTypography.heading2,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Schedule a site visit for any verified property to view your live appointment status and automated prospectuses here.',
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
                      child: const Text('BROWSE PROPERTIES'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: enquiries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = enquiries[index];
              return _buildEnquiryCard(context, item);
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

  Widget _buildEnquiryCard(BuildContext context, EnquiryModel item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGrey, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlack,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.statusLabel.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                Formatters.formatDate(item.createdAt),
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            item.propertyTitle,
            style: AppTypography.heading3.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),

          if (item.preferredDate != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Visit: ${item.preferredDate} (${item.preferredTime ?? 'Slot Confirmed'})',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],

          if (item.needCabPickup) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.directions_car, size: 14, color: AppColors.primaryBlack),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'AC Cab Pickup: ${item.pickupAddress ?? 'Residence'}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderGrey),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.mark_email_read_outlined, size: 14, color: AppColors.verifiedGreen),
                  const SizedBox(width: 4),
                  Text(
                    'n8n Prospectus Dispatched',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.verifiedGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => MapService.openWhatsApp(propertyTitle: item.propertyTitle),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Contact Advisor →'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
