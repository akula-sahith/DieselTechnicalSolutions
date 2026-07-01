import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/agreement_model.dart';
import '../repositories/agreement_repository.dart';

class AgreementsState {
  final List<AgreementModel> agreements;
  final List<AgreementModel> drafts;
  final bool isLoading;
  final String? error;
  final int page;
  final int totalPages;
  final int totalCount;
  final String searchQuery;
  final String documentTypeFilter; // '', 'Agreement', 'Quotation'

  AgreementsState({
    required this.agreements,
    required this.drafts,
    required this.isLoading,
    this.error,
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.searchQuery,
    required this.documentTypeFilter,
  });

  AgreementsState copyWith({
    List<AgreementModel>? agreements,
    List<AgreementModel>? drafts,
    bool? isLoading,
    String? error,
    int? page,
    int? totalPages,
    int? totalCount,
    String? searchQuery,
    String? documentTypeFilter,
  }) {
    return AgreementsState(
      agreements: agreements ?? this.agreements,
      drafts: drafts ?? this.drafts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      searchQuery: searchQuery ?? this.searchQuery,
      documentTypeFilter: documentTypeFilter ?? this.documentTypeFilter,
    );
  }

  factory AgreementsState.initial() {
    return AgreementsState(
      agreements: [],
      drafts: [],
      isLoading: false,
      page: 1,
      totalPages: 1,
      totalCount: 0,
      searchQuery: '',
      documentTypeFilter: '',
    );
  }
}

class AgreementsNotifier extends StateNotifier<AgreementsState> {
  final AgreementRepository _repository;

  AgreementsNotifier(this._repository) : super(AgreementsState.initial()) {
    fetchDrafts();
    fetchAgreements();
  }

  // Fetch drafts from MongoDB
  Future<void> fetchDrafts() async {
    try {
      final response = await _repository.getAgreements(
        page: 1,
        limit: 100,
        status: 'draft',
      );
      state = state.copyWith(drafts: response.agreements);
    } catch (e) {
      print("Failed to fetch drafts: $e");
    }
  }

  // Delete a draft or agreement
  Future<void> deleteDraft(String id) async {
    try {
      await _repository.deleteAgreement(id);
      final drafts = state.drafts.where((element) => element.id != id).toList();
      state = state.copyWith(drafts: drafts);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchAgreements({bool refresh = false, String? search, String? docType}) async {
    if (state.isLoading) return;

    final targetSearch = search ?? state.searchQuery;
    final targetDocType = docType ?? state.documentTypeFilter;
    final nextPage = refresh ? 1 : state.page;

    state = state.copyWith(
      isLoading: true,
      error: null,
      searchQuery: targetSearch,
      documentTypeFilter: targetDocType,
      page: nextPage,
    );

    try {
      // Refresh drafts in parallel when refreshing the main feed
      if (refresh) {
        fetchDrafts();
      }

      final response = await _repository.getAgreements(
        page: nextPage,
        search: targetSearch,
        documentType: targetDocType,
      );

      final newList = refresh 
          ? response.agreements 
          : [...state.agreements, ...response.agreements];

      final seenIds = <String>{};
      final uniqueAgreements = newList.where((agreement) {
        if (agreement.id == null) return true;
        return seenIds.add(agreement.id!);
      }).toList();

      state = state.copyWith(
        agreements: uniqueAgreements,
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

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query, page: 1, agreements: []);
    await fetchAgreements(refresh: true);
  }

  Future<void> filterByDocumentType(String type) async {
    state = state.copyWith(documentTypeFilter: type, page: 1, agreements: []);
    await fetchAgreements(refresh: true);
  }

  Future<void> deleteAgreement(String id) async {
    try {
      await _repository.deleteAgreement(id);
      final agreements = state.agreements.where((element) => element.id != id).toList();
      final drafts = state.drafts.where((element) => element.id != id).toList();
      state = state.copyWith(
        agreements: agreements,
        drafts: drafts,
        totalCount: (state.totalCount - 1).clamp(0, 999999),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    await fetchAgreements(refresh: true);
  }
}

final agreementsProvider = StateNotifierProvider<AgreementsNotifier, AgreementsState>((ref) {
  final repo = ref.watch(agreementRepositoryProvider);
  return AgreementsNotifier(repo);
});
