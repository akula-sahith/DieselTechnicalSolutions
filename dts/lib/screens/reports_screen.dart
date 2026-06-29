import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../providers/reports_provider.dart';
import '../widgets/bottom_nav_bar.dart';

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

    // Combine drafts and reports matching search (if local filtering drafts)
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
        title: const Text('All Reports'),

        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by Job Ref, Customer, Site...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(reportsProvider.notifier).search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
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
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildListContent(ReportsState state, List<dynamic> items) {
    if (items.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.insert_drive_file_outlined, size: 80, color: AppColors.textLight.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  'No Service Reports Found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try searching for something else\nor create a new report.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (state.error != null && items.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(reportsProvider.notifier).refresh();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
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
        final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(report.serviceAndCustomer.dateTime);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            onTap: () {
              final id = isDraft ? report.serviceAndCustomer.jobRef : report.id!;
              context.push('/report-details/$id?draft=$isDraft');
            },
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description_outlined, color: AppColors.primary),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    report.serviceAndCustomer.jobRef,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildStatusBadge(isDraft),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  report.serviceAndCustomer.customerName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textLight),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(bool isDraft) {
    final text = isDraft ? 'Pending' : 'Completed';
    final bgColor = isDraft ? AppColors.warning.withOpacity(0.15) : AppColors.success.withOpacity(0.15);
    final textColor = isDraft ? AppColors.warning : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
