import 'package:flutter_riverpod/legacy.dart';
import '../models/estimate_model.dart';
import '../repositories/estimate_repository.dart';

class EstimatesState {
  final List<EstimateModel> estimates;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  EstimatesState({
    this.estimates = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = true,
  });

  EstimatesState copyWith({
    List<EstimateModel>? estimates,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
  }) {
    return EstimatesState(
      estimates: estimates ?? this.estimates,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class EstimatesNotifier extends StateNotifier<EstimatesState> {
  final EstimateRepository _repository;
  String _currentSearch = '';

  EstimatesNotifier(this._repository) : super(EstimatesState()) {
    loadEstimates();
  }

  Future<void> loadEstimates({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(currentPage: 1, hasMore: true, estimates: [], isLoading: true, error: null);
    } else {
      if (!state.hasMore) return;
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await _repository.getEstimates(
        page: state.currentPage,
        search: _currentSearch,
      );

      final newEstimates = refresh 
          ? response.estimates 
          : [...state.estimates, ...response.estimates];

      state = state.copyWith(
        estimates: newEstimates,
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
    loadEstimates(refresh: true);
  }

  Future<void> refresh() async {
    await loadEstimates(refresh: true);
  }
}

final estimatesProvider = StateNotifierProvider<EstimatesNotifier, EstimatesState>((ref) {
  final repo = ref.watch(estimateRepositoryProvider);
  return EstimatesNotifier(repo);
});
