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
import '../services/pdf_service.dart';
import '../repositories/tax_invoice_repository.dart';

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

  void _showReportOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Generate Merged PDF Report',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                title: const Text('Last 3 Months'),
                onTap: () {
                  Navigator.pop(context);
                  _generateReport(DateTime.now().subtract(const Duration(days: 90)), DateTime.now(), 'Last_3_Months');
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                title: const Text('Last 6 Months'),
                onTap: () {
                  Navigator.pop(context);
                  _generateReport(DateTime.now().subtract(const Duration(days: 180)), DateTime.now(), 'Last_6_Months');
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                title: const Text('Last 1 Year'),
                onTap: () {
                  Navigator.pop(context);
                  _generateReport(DateTime.now().subtract(const Duration(days: 365)), DateTime.now(), 'Last_1_Year');
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range_outlined, color: AppColors.primary),
                title: const Text('Customized Date Range'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    _generateReport(picked.start, picked.end, 'Custom_${DateFormat('dd-MM-yyyy').format(picked.start)}_to_${DateFormat('dd-MM-yyyy').format(picked.end)}');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateReport(DateTime from, DateTime to, String label) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Fetching invoices...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final repo = ref.read(taxInvoiceRepositoryProvider);
      final dateFromStr = DateFormat('yyyy-MM-dd').format(from);
      final dateToStr = DateFormat('yyyy-MM-dd').format(to);

      final response = await repo.getTaxInvoices(
        dateFrom: dateFromStr,
        dateTo: dateToStr,
        all: true,
      );

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog

      if (response.taxInvoices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No tax invoices found for: ${label.replaceAll('_', ' ')}'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      // Show options dialog to print/save or share
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Report: ${label.replaceAll('_', ' ')}'),
          content: Text('Found ${response.taxInvoices.length} tax invoice(s). Choose an action to perform:'),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share PDF'),
              onPressed: () async {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generating PDF to share...'), duration: Duration(seconds: 1)),
                );
                try {
                  final pdfService = ref.read(pdfServiceProvider);
                  await pdfService.shareMergedTaxInvoicesPdf(
                    response.taxInvoices,
                    'TaxInvoices_Report_$label',
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to share PDF: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print/Save'),
              onPressed: () async {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generating PDF for printing...'), duration: Duration(seconds: 1)),
                );
                try {
                  final pdfService = ref.read(pdfServiceProvider);
                  await pdfService.printOrSaveMergedTaxInvoicesPdf(
                    response.taxInvoices,
                    'TaxInvoices_Report_$label',
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e'), backgroundColor: AppColors.error),
        );
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
            icon: const Icon(Icons.summarize_outlined),
            onPressed: _showReportOptionsSheet,
            tooltip: 'Generate PDF Report',
          ),
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
