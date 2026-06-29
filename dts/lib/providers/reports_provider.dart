import 'dart:convert';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_model.dart';
import '../repositories/report_repository.dart';
import '../services/api_service.dart';

class ReportsState {
  final List<ReportModel> reports; // From API
  final List<ReportModel> drafts;  // Saved locally (Pending status)
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
  final prefs = ref.watch(sharedPreferencesProvider);
  return ReportsNotifier(repo, prefs);
});

class ReportsNotifier extends StateNotifier<ReportsState> {
  final ReportRepository _repository;
  final SharedPreferences _prefs;
  static const String _draftsKey = 'report_drafts';

  ReportsNotifier(this._repository, this._prefs) : super(ReportsState.initial()) {
    loadDrafts();
    fetchReports();
  }

  // Load drafts from SharedPreferences
  void loadDrafts() {
    final list = _prefs.getStringList(_draftsKey) ?? [];
    final drafts = list.map((e) {
      try {
        return ReportModel.fromJson(jsonDecode(e) as Map<String, dynamic>);
      } catch (err) {
        return null;
      }
    }).whereType<ReportModel>().toList();

    state = state.copyWith(drafts: drafts);
  }

  // Save a draft locally
  Future<void> saveDraft(ReportModel draft) async {
    final drafts = List<ReportModel>.from(state.drafts);
    // If it exists, replace it, otherwise add it
    final index = drafts.indexWhere((element) => element.serviceAndCustomer.jobRef == draft.serviceAndCustomer.jobRef);
    if (index >= 0) {
      drafts[index] = draft;
    } else {
      drafts.insert(0, draft);
    }
    
    state = state.copyWith(drafts: drafts);
    await _saveDraftsToPrefs(drafts);
  }

  // Delete a draft
  Future<void> deleteDraft(String jobRef) async {
    final drafts = state.drafts.where((element) => element.serviceAndCustomer.jobRef != jobRef).toList();
    state = state.copyWith(drafts: drafts);
    await _saveDraftsToPrefs(drafts);
  }

  Future<void> _saveDraftsToPrefs(List<ReportModel> drafts) async {
    final list = drafts.map((e) => jsonEncode(e.toJson(flat: false))).toList();
    await _prefs.setStringList(_draftsKey, list);
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
      final date = d.serviceAndCustomer.dateTime;
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }).length;
    return todayReports + todayDrafts;
  }
}
