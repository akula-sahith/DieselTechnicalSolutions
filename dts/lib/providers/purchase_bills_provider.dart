import 'package:flutter_riverpod/legacy.dart';
import '../models/purchase_bill_model.dart';
import '../repositories/purchase_bill_repository.dart';

class PurchaseBillsState {
  final List<PurchaseBillModel> purchaseBills;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  PurchaseBillsState({
    this.purchaseBills = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = true,
  });

  PurchaseBillsState copyWith({
    List<PurchaseBillModel>? purchaseBills,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
  }) {
    return PurchaseBillsState(
      purchaseBills: purchaseBills ?? this.purchaseBills,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class PurchaseBillsNotifier extends StateNotifier<PurchaseBillsState> {
  final PurchaseBillRepository _repository;
  String _currentSearch = '';
  String _currentStatus = '';

  PurchaseBillsNotifier(this._repository) : super(PurchaseBillsState()) {
    loadPurchaseBills();
  }

  Future<void> loadPurchaseBills({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(currentPage: 1, hasMore: true, purchaseBills: [], isLoading: true, error: null);
    } else {
      if (!state.hasMore) return;
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await _repository.getPurchaseBills(
        page: state.currentPage,
        search: _currentSearch,
        status: _currentStatus,
      );

      final newBills = refresh 
          ? response.purchaseBills 
          : [...state.purchaseBills, ...response.purchaseBills];

      state = state.copyWith(
        purchaseBills: newBills,
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
    loadPurchaseBills(refresh: true);
  }

  void filterStatus(String status) {
    _currentStatus = status;
    loadPurchaseBills(refresh: true);
  }

  Future<void> refresh() async {
    await loadPurchaseBills(refresh: true);
  }
}

final purchaseBillsProvider = StateNotifierProvider<PurchaseBillsNotifier, PurchaseBillsState>((ref) {
  final repo = ref.watch(purchaseBillRepositoryProvider);
  return PurchaseBillsNotifier(repo);
});
