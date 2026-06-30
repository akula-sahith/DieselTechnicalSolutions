import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../providers/reports_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/common/document_card.dart';
import '../widgets/common/search_bar_widget.dart';
import '../widgets/common/empty_state_widget.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Set initial text if any
    final query = ref.read(reportsProvider).searchQuery;
    _searchController.text = query;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final reportsState = ref.read(reportsProvider);
      if (!reportsState.isLoading && reportsState.page <= reportsState.totalPages) {
        ref.read(reportsProvider.notifier).fetchReports();
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(reportsProvider.notifier).search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsProvider);
    final reportsNotifier = ref.read(reportsProvider.notifier);

    // Combine drafts and reports matching search
    final query = reportsState.searchQuery.toLowerCase();
    final filteredDrafts = reportsState.drafts.where((draft) {
      return draft.serviceAndCustomer.jobRef.toLowerCase().contains(query) ||
          draft.serviceAndCustomer.customerName.toLowerCase().contains(query) ||
          draft.serviceAndCustomer.contactNumber.toLowerCase().contains(query);
    }).toList();

    final allItems = [...filteredDrafts, ...reportsState.reports];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Service Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter feature coming soon.')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          SearchBarWidget(
            controller: _searchController,
            hintText: 'Search by Job Ref, Customer, Site...',
            onChanged: _onSearchChanged,
            onClear: () => ref.read(reportsProvider.notifier).search(''),
          ),

          // Main list area
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await reportsNotifier.refresh();
              },
              child: _buildListContent(reportsState, allItems),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'create_report_fab',
        onPressed: () => context.push('/create-report'),
        backgroundColor: AppColors.reportOrange,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildListContent(ReportsState state, List<dynamic> items) {
    if (items.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && items.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          EmptyStateWidget(
            icon: Icons.error_outline_rounded,
            title: 'Something went wrong',
            subtitle: state.error!,
            actionLabel: 'Retry',
            onAction: () => ref.read(reportsProvider.notifier).refresh(),
          ),
        ],
      );
    }

    if (items.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          EmptyStateWidget(
            icon: Icons.description_outlined,
            title: 'No Service Reports Found',
            subtitle: 'Try a different search or create\nyour first service report.',
            actionLabel: 'Create Report',
            onAction: () => context.push('/create-report'),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      itemCount: items.length + (state.page <= state.totalPages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final report = items[index];
        final isDraft = report.id == null || report.id!.isEmpty;
        final formattedDate = DateFormat('dd MMM yyyy, hh:mm a')
            .format(report.serviceAndCustomer.dateTime);

        return DocumentCard(
          documentNumber: report.serviceAndCustomer.jobRef,
          customerName: report.serviceAndCustomer.customerName,
          formattedDate: formattedDate,
          documentType: DocumentType.report,
          statusText: isDraft ? 'Pending' : 'Completed',
          isPending: isDraft,
          onTap: () {
            final id = isDraft ? report.serviceAndCustomer.jobRef : report.id!;
            context.push('/report-details/$id?draft=$isDraft');
          },
        );
      },
    );
  }
}
