import 'package:flutter_riverpod/legacy.dart';
import '../models/delivery_challan_model.dart';
import '../repositories/delivery_challan_repository.dart';

class DeliveryChallansState {
  final List<DeliveryChallanModel> deliveryChallans;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  DeliveryChallansState({
    this.deliveryChallans = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = true,
  });

  DeliveryChallansState copyWith({
    List<DeliveryChallanModel>? deliveryChallans,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
  }) {
    return DeliveryChallansState(
      deliveryChallans: deliveryChallans ?? this.deliveryChallans,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class DeliveryChallansNotifier extends StateNotifier<DeliveryChallansState> {
  final DeliveryChallanRepository _repository;
  String _currentSearch = '';

  DeliveryChallansNotifier(this._repository) : super(DeliveryChallansState()) {
    loadDeliveryChallans();
  }

  Future<void> loadDeliveryChallans({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(
        currentPage: 1,
        hasMore: true,
        deliveryChallans: [],
        isLoading: true,
        error: null,
      );
    } else {
      if (!state.hasMore) return;
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await _repository.getDeliveryChallans(
        page: state.currentPage,
        search: _currentSearch,
      );

      final newChallans = refresh
          ? response.deliveryChallans
          : [...state.deliveryChallans, ...response.deliveryChallans];

      state = state.copyWith(
        deliveryChallans: newChallans,
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
    loadDeliveryChallans(refresh: true);
  }

  Future<void> refresh() async {
    await loadDeliveryChallans(refresh: true);
  }
}

final deliveryChallansProvider =
    StateNotifierProvider<DeliveryChallansNotifier, DeliveryChallansState>((ref) {
  final repo = ref.watch(deliveryChallanRepositoryProvider);
  return DeliveryChallansNotifier(repo);
});
