import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/llb_logo.dart';
import '../../../shared/widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'prabakaransethu7@gmail.com');
  final _passwordController = TextEditingController(text: 'Password123!');
  bool _showLoginForm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email/phone and password.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    await ref.read(authProvider.notifier).signIn(
          email,
          password,
        );

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. BRAND LOGO & APP NAME
              const Center(
                child: LlbLogo(size: 48, showSubtitle: true),
              ),
              const SizedBox(height: 16),

              // 2. HERO RESIDENTIAL PLOT PHOTOGRAPH (CHENNAI CMDA LAYOUT)
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGrey, width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=800&q=80',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.subtleGrey,
                          child: const Icon(Icons.landscape, size: 48, color: Colors.grey),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlack,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CMDA & RERA APPROVED PLOTS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        bottom: 12,
                        left: 14,
                        right: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prime Residential Layouts in Chennai',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'KK Nagar • Porur • Velachery • Tambaram • OMR • ECR',
                              style: TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. HEADLINE & SUBTITLE
              const Text(
                'Find Your Perfect Plot in Chennai',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryBlack,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Explore verified residential plots across Chennai on an interactive map with Car, Bike, Bus, and Walking avatar navigation.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // 4. THREE PROMINENT ACTION BUTTONS
              Row(
                children: [
                  // Button 1: Explore Available Plots (Primary Black)
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.explore, size: 16),
                      label: const Text(
                        'EXPLORE PLOTS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonBlack,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Button 2: Toggle Login Form
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showLoginForm = true;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlack,
                        side: const BorderSide(color: AppColors.primaryBlack, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'LOGIN',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Button 3: Create Account
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () => context.push('/register'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlack,
                        side: const BorderSide(color: AppColors.borderGrey, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'REGISTER',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 5. INTERACTIVE LOGIN FORM CONTAINER
              if (_showLoginForm)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryBlack, width: 1.4),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryBlack,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.subtleGrey,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'CLIENT PORTAL',
                                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sign in with your email or phone to sync saved plots & enquiries.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),

                        // 1-Click Fast Sign In Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.borderGrey),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Fast 1-Click Access', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                                  Text('prabakaransethu7@gmail.com', style: TextStyle(color: AppColors.textMuted, fontSize: 9.5)),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.buttonBlack,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text('1-CLICK SIGN IN', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Email Address or Phone
                        CustomTextField(
                          label: 'EMAIL OR PHONE NUMBER',
                          hint: 'prabakaransethu7@gmail.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.account_circle_outlined,
                          validator: (v) => Validators.validateRequired(v, 'Email or Phone'),
                        ),
                        const SizedBox(height: 12),

                        // Password Field
                        CustomTextField(
                          label: 'PASSWORD',
                          hint: 'Enter your password',
                          controller: _passwordController,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline,
                          validator: Validators.validatePassword,
                        ),
                        const SizedBox(height: 8),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primaryBlack,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Primary Sign In Button
                        PrimaryButton(
                          text: 'SIGN IN',
                          isLoading: authState.isLoading,
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: 10),

                        // Guest Browsing Alternative
                        OutlinedButton.icon(
                          onPressed: () => context.go('/home'),
                          icon: const Icon(Icons.arrow_forward, size: 14),
                          label: const Text(
                            'CONTINUE BROWSING AS GUEST',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryBlack,
                            side: const BorderSide(color: AppColors.borderGrey, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // 6. PROPERTY PREVIEWS SNAPSHOT (Visual proofs for first-time user)
              const Text(
                'FEATURED RESIDENTIAL PLOTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildPlotPreviewTile(
                      title: 'Plot #14 KK Nagar',
                      price: '₹ 78.0 Lakhs',
                      dimensions: '30 × 40 ft (1,200 sq.ft)',
                      status: 'AVAILABLE',
                      statusColor: AppColors.verifiedGreen,
                      onTap: () => context.go('/home'),
                    ),
                    const SizedBox(width: 10),
                    _buildPlotPreviewTile(
                      title: 'Plot #11 Porur',
                      price: '₹ 57.6 Lakhs',
                      dimensions: '30 × 40 ft (1,200 sq.ft)',
                      status: 'AVAILABLE',
                      statusColor: AppColors.verifiedGreen,
                      onTap: () => context.go('/home'),
                    ),
                    const SizedBox(width: 10),
                    _buildPlotPreviewTile(
                      title: 'Plot #05 Velachery',
                      price: '₹ 1.22 Crores',
                      dimensions: '35 × 50 ft (1,750 sq.ft)',
                      status: 'AVAILABLE',
                      statusColor: AppColors.verifiedGreen,
                      onTap: () => context.go('/home'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlotPreviewTile({
    required String title,
    required String price,
    required String dimensions,
    required String status,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              price,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
            Text(
              dimensions,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5),
            ),
          ],
        ),
      ),
    );
  }
}
