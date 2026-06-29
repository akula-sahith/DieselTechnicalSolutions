import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../providers/agreements_provider.dart';

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
        title: const Text('AMC Agreements & Quotations'),
      ),
      body: Column(
        children: [
          // Search and Filters Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: AppColors.primary,
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (val) => agreementsNotifier.search(val),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search agreements & quotations...',
                    hintStyle: const TextStyle(color: AppColors.textLight),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              agreementsNotifier.search('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Document Type Filter ChoiceChips
                Row(
                  children: [
                    _buildFilterChip('All', ''),
                    const SizedBox(width: 8),
                    _buildFilterChip('Agreements', 'Agreement'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Quotations', 'Quotation'),
                  ],
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
        onPressed: () {
          context.push('/create-agreement');
        },
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label, String docType) {
    final activeDocType = ref.watch(agreementsProvider).documentTypeFilter;
    final isSelected = activeDocType == docType;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(agreementsProvider.notifier).filterByDocumentType(docType);
        }
      },
      selectedColor: AppColors.accent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: Colors.white.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildListContent(AgreementsState state) {
    if (state.agreements.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.agreements.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.feed_outlined, size: 80, color: AppColors.textLight.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  'No Agreements or Quotations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create one or search with a different keyword.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (state.error != null && state.agreements.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
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
                      ref.read(agreementsProvider.notifier).refresh();
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
      padding: const EdgeInsets.symmetric(vertical: 8),
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
        final badgeColor = agreement.documentType == 'Agreement' ? AppColors.success : AppColors.secondary;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: () {
              context.push('/agreement-details/${agreement.id}');
            },
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                agreement.documentType == 'Agreement' ? Icons.handshake_outlined : Icons.request_quote_outlined,
                color: badgeColor,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    agreement.offerNumber ?? 'Offer # Pending',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    agreement.documentType,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  agreement.customerName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      '₹${agreement.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textLight),
          ),
        );
      },
    );
  }
}
