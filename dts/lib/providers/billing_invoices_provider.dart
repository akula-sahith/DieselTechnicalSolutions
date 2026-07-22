import 'package:flutter_riverpod/legacy.dart';
import '../models/billing_invoice_model.dart';
import '../repositories/billing_invoice_repository.dart';

class BillingInvoicesState {
  final List<BillingInvoiceModel> billingInvoices;
  final bool isLoading;
  final String? error;
  final int page;
  final int totalPages;
  final String searchQuery;

  BillingInvoicesState({
    required this.billingInvoices,
    required this.isLoading,
    this.error,
    required this.page,
    required this.totalPages,
    required this.searchQuery,
  });

  factory BillingInvoicesState.initial() {
    return BillingInvoicesState(
      billingInvoices: [],
      isLoading: false,
      error: null,
      page: 1,
      totalPages: 1,
      searchQuery: '',
    );
  }

  BillingInvoicesState copyWith({
    List<BillingInvoiceModel>? billingInvoices,
    bool? isLoading,
    String? error,
    int? page,
    int? totalPages,
    String? searchQuery,
  }) {
    return BillingInvoicesState(
      billingInvoices: billingInvoices ?? this.billingInvoices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class BillingInvoicesNotifier extends StateNotifier<BillingInvoicesState> {
  final BillingInvoiceRepository _repository;

  BillingInvoicesNotifier(this._repository) : super(BillingInvoicesState.initial()) {
    loadBillingInvoices();
  }

  Future<void> loadBillingInvoices({int page = 1, String search = ''}) async {
    state = state.copyWith(isLoading: true, error: null, searchQuery: search);
    try {
      final res = await _repository.getBillingInvoices(page: page, search: search);
      state = state.copyWith(
        billingInvoices: res.billingInvoices,
        isLoading: false,
        page: res.page,
        totalPages: res.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadBillingInvoices(page: state.page, search: state.searchQuery);
  }
}

final billingInvoicesProvider = StateNotifierProvider<BillingInvoicesNotifier, BillingInvoicesState>((ref) {
  final repository = ref.watch(billingInvoiceRepositoryProvider);
  return BillingInvoicesNotifier(repository);
});
