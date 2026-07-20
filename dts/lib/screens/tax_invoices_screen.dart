import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../providers/tax_invoices_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/common/document_card.dart';
import '../widgets/common/search_bar_widget.dart';
import '../widgets/common/empty_state_widget.dart';

class TaxInvoicesScreen extends ConsumerStatefulWidget {
  const TaxInvoicesScreen({super.key});

  @override
  ConsumerState<TaxInvoicesScreen> createState() => _TaxInvoicesScreenState();
}

class _TaxInvoicesScreenState extends ConsumerState<TaxInvoicesScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taxInvoicesProvider.notifier).refresh();
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
      final state = ref.read(taxInvoicesProvider);
      if (!state.isLoading && state.hasMore) {
        ref.read(taxInvoicesProvider.notifier).loadTaxInvoices();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoicesState = ref.watch(taxInvoicesProvider);
    final invoicesNotifier = ref.read(taxInvoicesProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tax Invoices'),
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
              hintText: 'Search invoices...',
              onChanged: (val) => invoicesNotifier.search(val),
              onClear: () => invoicesNotifier.search(''),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await invoicesNotifier.refresh();
              },
              child: _buildListContent(invoicesState),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'create_invoice_fab',
        onPressed: () => context.push('/create-tax-invoice'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: -1),
    );
  }

  Widget _buildListContent(TaxInvoicesState state) {
    if (state.taxInvoices.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.taxInvoices.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          EmptyStateWidget(
            icon: Icons.error_outline_rounded,
            title: 'Something went wrong',
            subtitle: state.error!,
            actionLabel: 'Retry',
            onAction: () => ref.read(taxInvoicesProvider.notifier).refresh(),
          ),
        ],
      );
    }

    if (state.taxInvoices.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          EmptyStateWidget(
            icon: Icons.receipt,
            title: 'No Invoices Found',
            subtitle: 'Create a tax invoice or convert from an estimate.',
            actionLabel: 'Create Invoice',
            onAction: () => context.push('/create-tax-invoice'),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      itemCount: state.taxInvoices.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.taxInvoices.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final invoice = state.taxInvoices[index];
        final formattedDate = DateFormat('dd MMM yyyy').format(invoice.invoiceDate);
        final paymentStatus = invoice.paymentDetails?.status ?? 'Unpaid';

        return DocumentCard(
          documentNumber: invoice.invoiceNumber ?? 'Pending',
          customerName: invoice.billTo.customerName,
          formattedDate: formattedDate,
          documentType: DocumentType.agreement, // Reuse agreement style for invoice
          statusText: paymentStatus,
          isPending: paymentStatus == 'Unpaid',
          amount: '₹${(invoice.totalAmount ?? 0).toStringAsFixed(2)}',
          onTap: () {
            context.push('/tax-invoice-details/${invoice.id}', extra: invoice);
          },
        );
      },
    );
  }
}
