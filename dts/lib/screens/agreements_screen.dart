import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../providers/agreements_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/common/document_card.dart';
import '../widgets/common/search_bar_widget.dart';
import '../widgets/common/empty_state_widget.dart';

class AgreementsScreen extends ConsumerStatefulWidget {
  const AgreementsScreen({super.key});

  @override
  ConsumerState<AgreementsScreen> createState() => _AgreementsScreenState();
}

class _AgreementsScreenState extends ConsumerState<AgreementsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(agreementsProvider.notifier).refresh();
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
      final state = ref.read(agreementsProvider);
      if (!state.isLoading && state.page <= state.totalPages) {
        ref.read(agreementsProvider.notifier).fetchAgreements();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final agreementsState = ref.watch(agreementsProvider);
    final agreementsNotifier = ref.read(agreementsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AMC Proposals'),
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
          // Search + Filter Area
          Container(
            color: AppColors.background,
            child: Column(
              children: [
                SearchBarWidget(
                  controller: _searchController,
                  hintText: 'Search agreements & quotations...',
                  onChanged: (val) => agreementsNotifier.search(val),
                  onClear: () => agreementsNotifier.search(''),
                ),
                // Document Type Filter Chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      _buildFilterChip('All', ''),
                      const SizedBox(width: 8),
                      _buildFilterChip('Agreements', 'Agreement'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Quotations', 'Quotation'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main list area
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await agreementsNotifier.refresh();
              },
              child: _buildListContent(agreementsState),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'create_agreement_fab',
        onPressed: () => context.push('/create-agreement'),
        backgroundColor: AppColors.agreementGreen,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildFilterChip(String label, String docType) {
    final activeDocType = ref.watch(agreementsProvider).documentTypeFilter;
    final isSelected = activeDocType == docType;

    return GestureDetector(
      onTap: () {
        ref.read(agreementsProvider.notifier).filterByDocumentType(docType);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildListContent(AgreementsState state) {
    if (state.agreements.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.agreements.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          EmptyStateWidget(
            icon: Icons.error_outline_rounded,
            title: 'Something went wrong',
            subtitle: state.error!,
            actionLabel: 'Retry',
            onAction: () => ref.read(agreementsProvider.notifier).refresh(),
          ),
        ],
      );
    }

    if (state.agreements.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          EmptyStateWidget(
            icon: Icons.handshake_outlined,
            title: 'No Proposals Found',
            subtitle: 'Create your first AMC agreement\nor quotation to get started.',
            actionLabel: 'Create Proposal',
            onAction: () => context.push('/create-agreement'),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      itemCount: state.agreements.length + (state.page <= state.totalPages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.agreements.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final agreement = state.agreements[index];
        final formattedDate = DateFormat('dd MMM yyyy').format(agreement.date);

        return DocumentCard(
          documentNumber: agreement.offerNumber ?? 'Offer # Pending',
          customerName: agreement.customerName,
          formattedDate: formattedDate,
          documentType: agreement.documentType == 'Agreement'
              ? DocumentType.agreement
              : DocumentType.quotation,
          amount: '₹${agreement.grandTotal.toStringAsFixed(2)}',
          onTap: () {
            context.push('/agreement-details/${agreement.id}');
          },
        );
      },
    );
  }
}
