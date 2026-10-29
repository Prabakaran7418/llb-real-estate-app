import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/property_model.dart';
import '../../../providers/enquiry_provider.dart';
import '../../../providers/property_provider.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/primary_button.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddPropertyDialog() {
    final titleController = TextEditingController();
    final priceController = TextEditingController();
    final localityController = TextEditingController();
    final sqftController = TextEditingController();
    final latController = TextEditingController(text: '13.0827');
    final lngController = TextEditingController(text: '80.2707');
    PropertyType selectedType = PropertyType.villa;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Add New Property Listing', style: AppTypography.heading2),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'PROPERTY TITLE',
                      hint: 'Imperial Court - Anna Nagar',
                      controller: titleController,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'PRICE (IN RUPEES)',
                      hint: '18500000',
                      controller: priceController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'LOCALITY / AREA',
                      hint: 'Anna Nagar, Chennai',
                      controller: localityController,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'AREA (SQ.FT)',
                      hint: '2400',
                      controller: sqftController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'LATITUDE',
                            controller: latController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'LONGITUDE',
                            controller: lngController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<PropertyType>(
                      value: selectedType,
                      isExpanded: true,
                      items: PropertyType.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(t.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      text: 'PUBLISH LISTING',
                      onPressed: () async {
                        final price = double.tryParse(priceController.text) ?? 10000000;
                        final sqft = double.tryParse(sqftController.text) ?? 1500;
                        final lat = double.tryParse(latController.text) ?? 13.0827;
                        final lng = double.tryParse(lngController.text) ?? 80.2707;

                        final newProp = PropertyModel(
                          id: 'llb-custom-${const Uuid().v4().substring(0, 8)}',
                          title: titleController.text.trim().isNotEmpty
                              ? titleController.text.trim()
                              : 'Exclusive LLB Property',
                          description:
                              'Prime CMDA sanctioned property with 100% clear legal titles, sweet potable groundwater, and immediate construction readiness.',
                          price: price,
                          pricePerSqFt: price / sqft,
                          type: selectedType,
                          bedrooms: 3,
                          bathrooms: 3,
                          areaSqFt: sqft,
                          facing: 'North-East (Vasthu Compliant)',
                          approval: 'CMDA & RERA Approved',
                          waterTable: 'Sweet Potable Water at 24 ft',
                          address: localityController.text,
                          locality: localityController.text,
                          latitude: lat,
                          longitude: lng,
                          images: [
                            'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
                          ],
                          amenities: [
                            'CMDA Approved',
                            '100% Vasthu Compliant',
                            'Blacktop Roads',
                            'EB Connection',
                          ],
                          nearbyLandmarks: ['Metro Station (1.5 km)', 'Reputed Schools (1.0 km)'],
                          isFeatured: true,
                          createdAt: DateTime.now(),
                        );

                        await ref.read(propertyRepositoryProvider).addProperty(newProp);
                        ref.invalidate(propertiesFutureProvider);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Listing published successfully!')),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertiesFutureProvider);
    final allEnquiriesAsync = ref.watch(allEnquiriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Console'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryBlack,
          labelColor: AppColors.primaryBlack,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Enquiries & Visits'),
            Tab(text: 'Manage Listings'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPropertyDialog,
        backgroundColor: AppColors.primaryBlack,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ADD LISTING', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Enquiries List
          allEnquiriesAsync.when(
            data: (enquiries) {
              if (enquiries.isEmpty) {
                return const Center(child: Text('No enquiries received yet.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: enquiries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final e = enquiries[index];
                  return Container(
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
                            Text(e.customerName, style: AppTypography.heading3),
                            Text(
                              e.statusLabel,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${e.customerEmail} • ${e.customerPhone}', style: AppTypography.caption),
                        const SizedBox(height: 6),
                        Text('Property: ${e.propertyTitle}', style: AppTypography.bodySmall),
                        if (e.preferredDate != null)
                          Text('Site Visit: ${e.preferredDate} (${e.preferredTime})',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlack)),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),

          // Properties Management List
          propertiesAsync.when(
            data: (properties) {
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: properties.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final p = properties[index];
                  return ListTile(
                    tileColor: AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(color: AppColors.borderGrey),
                    ),
                    title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${Formatters.formatCurrency(p.price)} • ${p.locality}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () async {
                        await ref.read(propertyRepositoryProvider).deleteProperty(p.id);
                        ref.invalidate(propertiesFutureProvider);
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlack)),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ],
      ),
    );
  }
}
