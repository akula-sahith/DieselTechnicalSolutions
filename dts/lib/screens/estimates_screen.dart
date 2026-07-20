import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../providers/estimates_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/common/document_card.dart';
import '../widgets/common/search_bar_widget.dart';
import '../widgets/common/empty_state_widget.dart';

class EstimatesScreen extends ConsumerStatefulWidget {
  const EstimatesScreen({super.key});

  @override
  ConsumerState<EstimatesScreen> createState() => _EstimatesScreenState();
}

class _EstimatesScreenState extends ConsumerState<EstimatesScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(estimatesProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(estimatesProvider);
      if (!state.isLoading && state.hasMore) {
        ref.read(estimatesProvider.notifier).loadEstimates();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimatesState = ref.watch(estimatesProvider);
    final estimatesNotifier = ref.read(estimatesProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Estimates'),
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
          Container(
            color: AppColors.background,
            child: SearchBarWidget(
              controller: _searchController,
              hintText: 'Search estimates...',
              onChanged: (val) => estimatesNotifier.search(val),
              onClear: () => estimatesNotifier.search(''),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await estimatesNotifier.refresh();
              },
              child: _buildListContent(estimatesState),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'create_estimate_fab',
        onPressed: () => context.push('/create-estimate'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: -1),
    );
  }

  Widget _buildListContent(EstimatesState state) {
    if (state.estimates.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.estimates.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          EmptyStateWidget(
            icon: Icons.error_outline_rounded,
            title: 'Something went wrong',
            subtitle: state.error!,
            actionLabel: 'Retry',
            onAction: () => ref.read(estimatesProvider.notifier).refresh(),
          ),
        ],
      );
    }

    if (state.estimates.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          EmptyStateWidget(
            icon: Icons.receipt_long_outlined,
            title: 'No Estimates Found',
            subtitle: 'Create your first estimate.',
            actionLabel: 'Create Estimate',
            onAction: () => context.push('/create-estimate'),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 4, bottom: 80), // bottom padding for fab
      itemCount: state.estimates.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.estimates.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final estimate = state.estimates[index];
        final formattedDate = DateFormat('dd MMM yyyy').format(estimate.estimateDate);

        return DocumentCard(
          documentNumber: estimate.estimateNumber ?? 'Pending',
          customerName: estimate.estimateFor.customerName,
          formattedDate: formattedDate,
          documentType: DocumentType.quotation, // Reuse quotation styling
          statusText: estimate.status.toUpperCase(),
          isPending: estimate.status == 'draft',
          amount: '₹${(estimate.totalAmount ?? 0).toStringAsFixed(2)}',
          onTap: () {
            context.push('/estimate-details/${estimate.id}');
          },
        );
      },
    );
  }
}
