import 'package:flutter_riverpod/legacy.dart';
import '../models/customer_model.dart';
import '../repositories/customer_repository.dart';

class CustomersState {
  final List<CustomerModel> customers;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  CustomersState({
    this.customers = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = true,
  });

  CustomersState copyWith({
    List<CustomerModel>? customers,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class CustomersNotifier extends StateNotifier<CustomersState> {
  final CustomerRepository _repository;
  String _currentSearch = '';

  CustomersNotifier(this._repository) : super(CustomersState()) {
    loadCustomers();
  }

  Future<void> loadCustomers({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(currentPage: 1, hasMore: true, customers: [], isLoading: true, error: null);
    } else {
      if (!state.hasMore) return;
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await _repository.getCustomers(
        page: state.currentPage,
        search: _currentSearch,
      );

      final newCustomers = refresh 
          ? response.customers 
          : [...state.customers, ...response.customers];

      state = state.copyWith(
        customers: newCustomers,
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
    loadCustomers(refresh: true);
  }

  Future<void> refresh() async {
    await loadCustomers(refresh: true);
  }
}

final customersProvider = StateNotifierProvider<CustomersNotifier, CustomersState>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return CustomersNotifier(repo);
});
