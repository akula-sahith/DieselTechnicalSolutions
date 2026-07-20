import 'package:flutter_riverpod/legacy.dart';
import '../models/tax_invoice_model.dart';
import '../repositories/tax_invoice_repository.dart';

class TaxInvoicesState {
  final List<TaxInvoiceModel> taxInvoices;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  TaxInvoicesState({
    this.taxInvoices = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = true,
  });

  TaxInvoicesState copyWith({
    List<TaxInvoiceModel>? taxInvoices,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
  }) {
    return TaxInvoicesState(
      taxInvoices: taxInvoices ?? this.taxInvoices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class TaxInvoicesNotifier extends StateNotifier<TaxInvoicesState> {
  final TaxInvoiceRepository _repository;
  String _currentSearch = '';

  TaxInvoicesNotifier(this._repository) : super(TaxInvoicesState()) {
    loadTaxInvoices();
  }

  Future<void> loadTaxInvoices({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(currentPage: 1, hasMore: true, taxInvoices: [], isLoading: true, error: null);
    } else {
      if (!state.hasMore) return;
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await _repository.getTaxInvoices(
        page: state.currentPage,
        search: _currentSearch,
      );

      final newInvoices = refresh 
          ? response.taxInvoices 
          : [...state.taxInvoices, ...response.taxInvoices];

      state = state.copyWith(
        taxInvoices: newInvoices,
        isLoading: false,
        currentPage: response.page + 1,
        totalPages: response.totalPages,
        hasMore: response.page < response.totalPages,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void search(String query) {
    _currentSearch = query;
    loadTaxInvoices(refresh: true);
  }

  Future<void> refresh() async {
    await loadTaxInvoices(refresh: true);
  }
}

final taxInvoicesProvider = StateNotifierProvider<TaxInvoicesNotifier, TaxInvoicesState>((ref) {
  final repo = ref.watch(taxInvoiceRepositoryProvider);
  return TaxInvoicesNotifier(repo);
});
