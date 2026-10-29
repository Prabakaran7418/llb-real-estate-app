import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/map_service.dart';
import '../../../shared/widgets/llb_logo.dart';
import '../../../shared/widgets/primary_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Account & Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderGrey),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlack,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (user?.fullName.isNotEmpty == true)
                            ? user!.fullName[0].toUpperCase()
                            : 'L',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Valued Client',
                            style: AppTypography.heading2,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'client@example.com',
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.subtleGrey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              user?.isAdmin == true ? 'ADMINISTRATOR' : 'VERIFIED BUYER',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Admin Panel Option
              if (user?.isAdmin == true || user?.email.contains('admin') == true) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.admin_panel_settings, color: AppColors.primaryBlack),
                  title: const Text('Admin Management Console', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Manage listings, view customer bookings'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => context.push('/admin'),
                ),
                const Divider(),
              ],

              // Support & Enquiries
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available, color: AppColors.primaryBlack),
                title: const Text('My Site Visits & Enquiries', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => context.push('/enquiries'),
              ),
              const Divider(),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone_outlined, color: AppColors.primaryBlack),
                title: const Text('LLB Helpline (+91 98400 00000)', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => MapService.makePhoneCall(),
              ),
              const Divider(),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.chat_outlined, color: AppColors.primaryBlack),
                title: const Text('WhatsApp Official Support', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => MapService.openWhatsApp(propertyTitle: 'General Enquiry'),
              ),
              const Divider(),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.verified_user_outlined, color: AppColors.primaryBlack),
                title: const Text('CMDA & RERA Verification Guide', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('100% Clear titles and government sanctioned layouts'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {},
              ),
              const Divider(),

              const SizedBox(height: 32),

              // Company Branding & Office Information
              const Center(
                child: LlbLogo(size: 40, showSubtitle: true),
              ),
              const SizedBox(height: 8),
              Text(
                'Head Office: ${AppConstants.companyOffice}',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Sign Out Button
              PrimaryButton(
                text: 'SIGN OUT',
                onPressed: () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
