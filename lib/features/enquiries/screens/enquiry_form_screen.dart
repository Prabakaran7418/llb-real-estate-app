import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../models/enquiry_model.dart';
import '../../../models/property_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/enquiry_provider.dart';
import '../../../providers/property_provider.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';

class EnquiryFormScreen extends ConsumerStatefulWidget {
  final String propertyId;

  const EnquiryFormScreen({super.key, required this.propertyId});

  @override
  ConsumerState<EnquiryFormScreen> createState() => _EnquiryFormScreenState();
}

class _EnquiryFormScreenState extends ConsumerState<EnquiryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pickupController = TextEditingController();
  final _messageController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedTimeSlot = '10:00 AM - 01:00 PM (Morning Slot)';
  bool _needCabPickup = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _timeSlots = [
    '10:00 AM - 01:00 PM (Morning Slot)',
    '02:00 PM - 05:00 PM (Afternoon Slot)',
    '05:00 PM - 07:00 PM (Evening Sunset Slot)',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        _nameController.text = user.fullName;
        _emailController.text = user.email;
        _phoneController.text = user.phoneNumber;
      }
      _messageController.text =
          'I am interested in this residential plot. Please share verified CMDA documents and coordinate site visit.';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _pickupController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 45)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlack,
              onPrimary: Colors.white,
              surface: AppColors.background,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSubmit(PropertyModel? property) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final user = ref.read(authProvider).user;
    final dateStr = _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : '';

    final plotId = property?.plotNumber.isNotEmpty == true
        ? property!.plotNumber
        : (property?.id ?? widget.propertyId);

    final enquiry = EnquiryModel(
      id: const Uuid().v4(),
      propertyId: property?.id ?? widget.propertyId,
      propertyTitle: property?.title ?? 'Demarcated Residential Plot',
      propertyLocation: property?.locality ?? 'Chennai',
      propertyPrice: property?.price,
      propertyImage: property?.images.isNotEmpty == true ? property!.images.first : null,
      userId: user?.id ?? 'client-user',
      customerName: _nameController.text.trim(),
      customerEmail: _emailController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      preferredDate: dateStr.isNotEmpty ? dateStr : null,
      preferredTime: _selectedTimeSlot,
      needCabPickup: _needCabPickup,
      pickupAddress: _needCabPickup && _pickupController.text.trim().isNotEmpty
          ? _pickupController.text.trim()
          : 'Residence',
      loanRequired: false,
      message: _messageController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      final response = await ref.read(userEnquiriesProvider.notifier).submitEnquiry(
            enquiry: enquiry,
            property: property,
          );

      setState(() {
        _isSubmitting = false;
      });

      if (!mounted) return;

      if (response.dispatchResult.success) {
        // Show success ONLY after notification step succeeds!
        _showConfirmationDialog(enquiry, property, plotId);
      } else {
        // Report failure accurately
        setState(() {
          _errorMessage = response.dispatchResult.error ??
              'Enquiry email notification could not be delivered to administrator. Please check network connection and try again.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (err) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'System error: $err';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showConfirmationDialog(EnquiryModel enquiry, PropertyModel? property, String plotId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.borderBlack, width: 1.5),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlack,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                'Plot Enquiry Submitted',
                style: AppTypography.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'An automated email notification for [$plotId] has been delivered to prabakaransethu7@gmail.com, and confirmation was sent to ${enquiry.customerEmail}.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.subtleGrey,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned Senior Advisor:',
                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Er. S. Karthik (+91 98401 55678)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Coordinator will call your mobile (${enquiry.customerPhone}) prior to the visit.',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'VIEW MY ENQUIRIES',
                onPressed: () {
                  context.pop();
                  context.go('/enquiries');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertyAsync = ref.watch(propertyDetailsProvider(widget.propertyId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Enquire About This Plot'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: propertyAsync.when(
        data: (property) {
          final plotId = property?.plotNumber.isNotEmpty == true
              ? property!.plotNumber
              : (property?.id ?? widget.propertyId);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // PREFILLED SELECTED PLOT DETAILS HEADER
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderBlack, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                              Text(
                                property != null ? Formatters.formatCurrency(property.price) : '',
                                style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            property?.title ?? 'Residential Plot',
                            style: AppTypography.heading3.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${property?.locality ?? 'Chennai'} • ${property?.dimensions ?? ''} (${property != null ? Formatters.formatSqFt(property.areaSqFt) : ''})',
                            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          border: Border.all(color: AppColors.error),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.error, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Text('Your Contact Details', style: AppTypography.heading3),
                    const SizedBox(height: 14),

                    // Full Name
                    CustomTextField(
                      label: 'YOUR FULL NAME *',
                      hint: 'Lokesh Kumar',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline,
                      validator: (v) => Validators.validateRequired(v, 'Customer Name'),
                    ),
                    const SizedBox(height: 14),

                    // Email Address
                    CustomTextField(
                      label: 'EMAIL ADDRESS *',
                      hint: 'name@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 14),

                    // Phone Number
                    CustomTextField(
                      label: 'MOBILE NUMBER *',
                      hint: '+91 98400 00000',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      validator: Validators.validatePhone,
                    ),
                    const SizedBox(height: 14),

                    // Enquiry Message
                    CustomTextField(
                      label: 'ENQUIRY MESSAGE *',
                      hint: 'Specific questions regarding title deeds, approvals, etc.',
                      controller: _messageController,
                      maxLines: 3,
                      validator: (v) => Validators.validateRequired(v, 'Enquiry message'),
                    ),
                    const SizedBox(height: 20),

                    const Text('Optional Site Visit Coordination', style: AppTypography.heading3),
                    const SizedBox(height: 12),

                    // Preferred Date Picker
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderGrey),
                          borderRadius: BorderRadius.circular(6),
                          color: AppColors.background,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PREFERRED VISIT DATE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedDate != null
                                      ? DateFormat('EEEE, dd MMM yyyy').format(_selectedDate!)
                                      : 'Tap to pick preferred visit date (Optional)',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: _selectedDate != null
                                        ? AppColors.textPrimary
                                        : AppColors.placeholder,
                                    fontWeight: _selectedDate != null ? FontWeight.w700 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.calendar_today, size: 18, color: AppColors.primaryBlack),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Preferred Time Slot Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderGrey),
                        borderRadius: BorderRadius.circular(6),
                        color: AppColors.background,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedTimeSlot,
                          isExpanded: true,
                          icon: const Icon(Icons.access_time, size: 18, color: AppColors.primaryBlack),
                          items: _timeSlots.map((slot) {
                            return DropdownMenuItem<String>(
                              value: slot,
                              child: Text(slot, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedTimeSlot = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Complimentary AC Cab Toggle
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderGrey),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Complimentary AC Cab Pickup',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Chauffeur-driven pickup from residence.',
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _needCabPickup,
                                activeThumbColor: AppColors.primaryBlack,
                                onChanged: (val) {
                                  setState(() {
                                    _needCabPickup = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_needCabPickup) ...[
                            const SizedBox(height: 10),
                            CustomTextField(
                              label: 'RESIDENTIAL PICKUP ADDRESS',
                              hint: 'Apartment name, Street, Chennai locality',
                              controller: _pickupController,
                              maxLines: 2,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SUBMIT BUTTON
                    PrimaryButton(
                      text: _isSubmitting
                          ? 'DISPATCHING NOTIFICATION...'
                          : 'SUBMIT PLOT ENQUIRY & NOTIFY',
                      isLoading: _isSubmitting,
                      onPressed: () => _handleSubmit(property),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Notification will be immediately dispatched to prabakaransethu7@gmail.com via n8n.',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
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
