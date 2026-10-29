import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/property_provider.dart';
import '../../../shared/widgets/amenity_chip.dart';
import '../../../shared/widgets/property_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedLocality = 'All';

  final List<String> _popularLocalities = [
    'All',
    'KK Nagar',
    'Porur',
    'Velachery',
    'Tambaram',
    'OMR',
    'ECR',
    'Anna Nagar',
    'Medavakkam',
  ];

  void _showQuickLoginModal(BuildContext context) {
    final emailController = TextEditingController(text: 'prabakaransethu7@gmail.com');
    final passwordController = TextEditingController(text: 'Password123!');
    bool obscurePassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Client Portal Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'EMAIL ADDRESS OR PHONE NUMBER',
                      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'PASSWORD',
                      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setModalState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/forgot-password');
                      },
                      child: const Text('Forgot Password?', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await ref.read(authProvider.notifier).signIn(
                            emailController.text,
                            passwordController.text,
                          );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlack,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/register');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Continue Browsing as Guest →',
                      style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final allPropertiesAsync = ref.watch(propertiesFutureProvider);
    final featuredPropertiesAsync = ref.watch(featuredPropertiesProvider);

    final displayName = user?.fullName.split(' ').first ?? 'Client';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. Top Custom Brand Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vanakkam, $displayName',
                          style: AppTypography.heading1.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppConstants.companyFullName.toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                            fontSize: 9.0,
                          ),
                        ),
                      ],
                    ),
                    // Monogram LLB Badge
                    GestureDetector(
                      onTap: () {
                        if (user != null) {
                          context.push('/profile');
                        } else {
                          _showQuickLoginModal(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlack,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'LLB',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            if (user != null) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.check_circle, color: AppColors.verifiedGreen, size: 13),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. REQUIRED WIDE HERO SECTION: PHOTOREALISTIC MODERN VILLA
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryBlack, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // High-Quality Photorealistic Independent Villa Image
                        Stack(
                          children: [
                            SizedBox(
                              height: 210,
                              width: double.infinity,
                              child: Image.network(
                                'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.subtleGrey,
                                  child: const Icon(Icons.home_work, size: 48, color: Colors.grey),
                                ),
                              ),
                            ),
                            Container(
                              height: 210,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.85),
                                  ],
                                ),
                              ),
                            ),
                            // CMDA & RERA Approval Badge
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlack,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.white38),
                                    ),
                                    child: const Text(
                                      'CMDA & RERA APPROVED',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.verifiedGreen,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '100% CLEAR TITLES',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Exact Required Headline & Supporting Text
                            const Positioned(
                              bottom: 12,
                              left: 14,
                              right: 14,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Find Your Perfect Plot. Build Your Dream Home.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      height: 1.25,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Discover available plots across Chennai and find the perfect location for your future home.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // The Three Prominent Buttons
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Prominent Black Button: Explore Available Plots
                              ElevatedButton.icon(
                                onPressed: () => context.push('/map'),
                                icon: const Icon(Icons.explore, size: 16),
                                label: const Text(
                                  'EXPLORE AVAILABLE PLOTS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlack,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  elevation: 0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 2. Login & Create Account Row
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _showQuickLoginModal(context),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primaryBlack,
                                        side: const BorderSide(color: AppColors.primaryBlack, width: 1.3),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      child: const Text(
                                        'LOGIN',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => context.push('/register'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primaryBlack,
                                        side: const BorderSide(color: AppColors.primaryBlack, width: 1.3),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      child: const Text(
                                        'CREATE ACCOUNT',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Interactive Map Preview Banner with Avatars
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlack,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ZERO API KEY • 100% FREE GIS MAP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const Text(
                            '🚗 🏍️ 🚌 🚶',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Interactive Map with Transport Avatars',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Select any Chennai plot to preview turn-by-turn road routes with Car, Bike, Bus, and Walking avatars.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => context.push('/map'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryBlack,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          elevation: 0,
                        ),
                        child: const Text(
                          'OPEN INTERACTIVE MAP',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Popular Chennai Locations
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Popular Chennai Locations', style: AppTypography.heading2),
                    const SizedBox(height: 2),
                    const Text(
                      'Prime residential layouts across Chennai fastest growing corridors',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _popularLocalities.map((loc) {
                          final isSelected = _selectedLocality == loc;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: AmenityChip(
                              label: loc,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedLocality = loc;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Featured Residential Plots Carousel
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Featured Residential Plots', style: AppTypography.heading2),
                    Text(
                      'VIP SELECTION',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 310,
                child: featuredPropertiesAsync.when(
                  data: (featuredList) => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: featuredList.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 290,
                        child: PropertyCard(
                          property: featuredList[index],
                          isHorizontal: true,
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryBlack),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // 6. Simple Explanation: "How to Choose a Plot and Visit It"
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.subtleGrey,
                    border: Border.all(color: AppColors.primaryBlack, width: 1.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How to Choose a Plot & Visit It',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'A simple 3-step transparent property journey by LLB Real Estate',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      _buildGuideStep(
                        step: '1',
                        title: 'Discover Verified Chennai Plots',
                        description:
                            'Browse CMDA & RERA approved plots with transparent pricing, exact boundary dimensions (e.g. 40 × 60), and 100% legal title deeds.',
                      ),
                      const SizedBox(height: 10),
                      _buildGuideStep(
                        step: '2',
                        title: 'Choose Travel Avatar & Preview Route',
                        description:
                            'Select Car 🚗, Bike 🏍️, Bus 🚌 or Walking 🚶 avatar. Watch the simulated route preview along actual roads with live distance & ETA calculation.',
                      ),
                      const SizedBox(height: 10),
                      _buildGuideStep(
                        step: '3',
                        title: 'Direct Site Visit & Instant Enquiry',
                        description:
                            'Launch real-world Google Maps turn-by-turn navigation directly to the demarcated corner stones, or send an enquiry email dispatched instantly to our director via n8n.',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 7. Recently Added Properties / Filtered List Heading
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedLocality == 'All'
                          ? 'Available Plots Across Chennai'
                          : 'Available Plots in $_selectedLocality',
                      style: AppTypography.heading2,
                    ),
                    allPropertiesAsync.maybeWhen(
                      data: (list) {
                        final count = _selectedLocality == 'All'
                            ? list.length
                            : list.where((p) => p.locality.toLowerCase().contains(_selectedLocality.toLowerCase())).length;
                        return Text(
                          '$count Available',
                          style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            // 8. Properties Vertical List
            allPropertiesAsync.when(
              data: (properties) {
                final filtered = _selectedLocality == 'All'
                    ? properties
                    : properties
                        .where((p) => p.locality.toLowerCase().contains(_selectedLocality.toLowerCase()))
                        .toList();

                if (filtered.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        children: [
                          const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 10),
                          Text(
                            'No plots available in $_selectedLocality.',
                            style: AppTypography.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedLocality = 'All';
                              });
                            },
                            child: const Text('Show All Localities'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: PropertyCard(property: filtered[index]),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlack)),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(child: Text('Error loading properties: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep({
    required String step,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.primaryBlack,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.black),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
