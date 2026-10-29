import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enquiry_model.dart';
import '../models/property_model.dart';
import '../repositories/enquiry_repository.dart';
import 'auth_provider.dart';

final enquiryRepositoryProvider = Provider<EnquiryRepository>((ref) {
  return EnquiryRepository();
});

class EnquiriesNotifier extends StateNotifier<AsyncValue<List<EnquiryModel>>> {
  final EnquiryRepository _repository;
  final String _userId;

  EnquiriesNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    loadEnquiries();
  }

  Future<void> loadEnquiries() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getUserEnquiries(_userId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<EnquirySubmissionResponse> submitEnquiry({
    required EnquiryModel enquiry,
    PropertyModel? property,
  }) async {
    final result = await _repository.submitEnquiry(
      enquiry: enquiry,
      property: property,
    );
    await loadEnquiries();
    return result;
  }
}

final userEnquiriesProvider =
    StateNotifierProvider<EnquiriesNotifier, AsyncValue<List<EnquiryModel>>>((ref) {
  final repo = ref.watch(enquiryRepositoryProvider);
  final user = ref.watch(authProvider).user;
  return EnquiriesNotifier(repo, user?.id ?? '');
});

final allEnquiriesProvider = FutureProvider<List<EnquiryModel>>((ref) async {
  final repo = ref.watch(enquiryRepositoryProvider);
  return repo.getAllEnquiries();
});
