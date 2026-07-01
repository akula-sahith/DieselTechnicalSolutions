import 'package:flutter_riverpod/legacy.dart';
import '../models/report_model.dart';
import '../repositories/report_repository.dart';

class ReportsState {
  final List<ReportModel> reports; // Combined list or submitted list
  final List<ReportModel> drafts;  // Draft documents from MongoDB
  final bool isLoading;
  final String? error;
  final int page;
  final int totalPages;
  final int totalCount;
  final String searchQuery;

  ReportsState({
    required this.reports,
    required this.drafts,
    required this.isLoading,
    this.error,
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.searchQuery,
  });

  ReportsState copyWith({
    List<ReportModel>? reports,
    List<ReportModel>? drafts,
    bool? isLoading,
    String? error,
    int? page,
    int? totalPages,
    int? totalCount,
    String? searchQuery,
  }) {
    return ReportsState(
      reports: reports ?? this.reports,
      drafts: drafts ?? this.drafts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  factory ReportsState.initial() {
    return ReportsState(
      reports: [],
      drafts: [],
      isLoading: false,
      page: 1,
      totalPages: 1,
      totalCount: 0,
      searchQuery: '',
    );
  }
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  final repo = ref.watch(reportRepositoryProvider);
  return ReportsNotifier(repo);
});

class ReportsNotifier extends StateNotifier<ReportsState> {
  final ReportRepository _repository;

  ReportsNotifier(this._repository) : super(ReportsState.initial()) {
    fetchDrafts();
    fetchReports();
  }

  // Fetch drafts from MongoDB
  Future<void> fetchDrafts() async {
    try {
      final response = await _repository.getReports(
        page: 1,
        limit: 100,
        status: 'draft',
      );
      state = state.copyWith(drafts: response.reports);
    } catch (e) {
      print("Failed to fetch drafts: $e");
    }
  }

  // Delete a report or draft
  Future<void> deleteReport(String id) async {
    try {
      await _repository.deleteReport(id);
      final reports = state.reports.where((element) => element.id != id).toList();
      final drafts = state.drafts.where((element) => element.id != id).toList();
      state = state.copyWith(
        reports: reports,
        drafts: drafts,
        totalCount: (state.totalCount - 1).clamp(0, 999999),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Fetch reports from API with optional search query and pagination
  Future<void> fetchReports({bool refresh = false, String? search}) async {
    if (state.isLoading) return;

    final targetSearch = search ?? state.searchQuery;
    final nextPage = refresh ? 1 : state.page;

    state = state.copyWith(
      isLoading: true,
      error: null,
      searchQuery: targetSearch,
      page: nextPage,
    );

    try {
      // Refresh drafts in parallel when refreshing the main feed
      if (refresh) {
        fetchDrafts();
      }

      final response = await _repository.getReports(
        page: nextPage,
        search: targetSearch,
      );

      final newList = refresh 
          ? response.reports 
          : [...state.reports, ...response.reports];
      
      // Deduplicate by ID
      final seenIds = <String>{};
      final uniqueReports = newList.where((report) {
        if (report.id == null) return true;
        return seenIds.add(report.id!);
      }).toList();

      state = state.copyWith(
        reports: uniqueReports,
        isLoading: false,
        page: response.page + 1,
        totalPages: response.totalPages,
        totalCount: response.total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Search reports
  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query, page: 1, reports: []);
    await fetchReports(refresh: true);
  }

  // Refresh reports
  Future<void> refresh() async {
    await fetchReports(refresh: true);
  }

  // Statistics calculation helpers
  int get totalReportsCount => state.totalCount + state.drafts.length;
  int get completedReportsCount => state.totalCount;
  int get pendingReportsCount => state.drafts.length;
  
  int get todayReportsCount {
    final now = DateTime.now();
    final todayReports = state.reports.where((r) {
      final date = r.createdAt ?? r.serviceAndCustomer.dateTime;
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }).length;
    final todayDrafts = state.drafts.where((d) {
      final date = d.createdAt ?? d.serviceAndCustomer.dateTime;
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }).length;
    return todayReports + todayDrafts;
  }
}
