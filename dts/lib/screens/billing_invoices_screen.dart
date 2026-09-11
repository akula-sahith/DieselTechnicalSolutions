import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../providers/billing_invoices_provider.dart';
import '../repositories/billing_invoice_repository.dart';
import '../services/pdf_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/common/document_card.dart';
import '../widgets/common/adaptive_layout.dart';
import '../widgets/common/desktop_table_widget.dart';

class BillingInvoicesScreen extends ConsumerStatefulWidget {
  const BillingInvoicesScreen({super.key});

  @override
  ConsumerState<BillingInvoicesScreen> createState() => _BillingInvoicesScreenState();
}

class _BillingInvoicesScreenState extends ConsumerState<BillingInvoicesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(billingInvoicesProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
                  'Generate Merged Cash Invoice Report',
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
                    _generateReport(
                      picked.start,
                      picked.end,
                      'Custom_${DateFormat('dd-MM-yyyy').format(picked.start)}_to_${DateFormat('dd-MM-yyyy').format(picked.end)}',
                    );
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
                Text('Fetching cash invoices...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final repo = ref.read(billingInvoiceRepositoryProvider);
      final dateFromStr = DateFormat('yyyy-MM-dd').format(from);
      final dateToStr = DateFormat('yyyy-MM-dd').format(to);

      final response = await repo.getBillingInvoices(
        dateFrom: dateFromStr,
        dateTo: dateToStr,
        all: true,
      );

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      if (response.billingInvoices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No cash invoices found for: ${label.replaceAll('_', ' ')}'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Report: ${label.replaceAll('_', ' ')}'),
          content: Text('Found ${response.billingInvoices.length} cash invoice(s). Choose an action:'),
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
                  await pdfService.shareMergedBillingInvoicesPdf(
                    response.billingInvoices,
                    'CashInvoices_Report_$label',
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
                  const SnackBar(content: Text('Generating PDF...'), duration: Duration(seconds: 1)),
                );
                try {
                  final pdfService = ref.read(pdfServiceProvider);
                  await pdfService.printOrSaveMergedBillingInvoicesPdf(
                    response.billingInvoices,
                    'CashInvoices_Report_$label',
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase().replaceAll('_', ' ')) {
      case 'paid':
        return AppColors.success;
      case 'partially paid':
        return AppColors.warning;
      case 'unpaid':
      default:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingInvoicesProvider);
    final notifier = ref.read(billingInvoicesProvider.notifier);

    return AdaptiveLayout(
      currentRoute: '/billing-invoices',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Cash Invoices'),
          actions: [
            IconButton(
              icon: const Icon(Icons.summarize_outlined),
              onPressed: _showReportOptionsSheet,
              tooltip: 'Generate Merged PDF Report',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => notifier.refresh(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/create-billing-invoice'),
          icon: const Icon(Icons.add),
          backgroundColor: AppColors.primary,
          label: const Text('Create Cash Invoice', style: TextStyle(color: Colors.white)),
        ),
        bottomNavigationBar: const CustomBottomNavBar(currentIndex: -1),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search Cash Invoices...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            notifier.loadBillingInvoices(search: '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                onSubmitted: (val) => notifier.loadBillingInvoices(search: val),
              ),
            ),
            Expanded(
              child: state.isLoading && state.billingInvoices.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(state.error!),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => notifier.refresh(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : state.billingInvoices.isEmpty
                          ? const Center(child: Text('No Cash Invoices found.'))
                          : RefreshIndicator(
                              onRefresh: () => notifier.refresh(),
                              child: AdaptiveLayout.isDesktop(context)
                                  ? ListView(
                                      children: [
                                        DesktopTableWidget(
                                          columns: const [
                                            DesktopTableColumn(label: 'Bill #', flex: 2),
                                            DesktopTableColumn(label: 'Customer', flex: 3),
                                            DesktopTableColumn(label: 'Date', flex: 2),
                                            DesktopTableColumn(label: 'Amount', flex: 2),
                                            DesktopTableColumn(label: 'Payment Status', flex: 2),
                                            DesktopTableColumn(label: 'Action', flex: 1),
                                          ],
                                          rows: state.billingInvoices.map((invoice) {
                                            final rawStatus = invoice.paymentStatus.replaceAll('_', ' ').toLowerCase();
                                            final statusText = rawStatus == 'paid'
                                                ? 'Paid'
                                                : (rawStatus == 'partially paid' ? 'Partially Paid' : 'Unpaid');
                                            final statusColor = _getStatusColor(rawStatus);

                                            return DesktopTableRow(
                                              onTap: () => context.push('/billing-invoice-details/${invoice.id}', extra: invoice),
                                              cells: [
                                                Text(
                                                  invoice.invoiceNumber ?? 'BILL-XXXX',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                                ),
                                                Text(
                                                  invoice.billTo.customerName,
                                                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                                ),
                                                Text(
                                                  DateFormat('dd MMM yyyy').format(invoice.invoiceDate),
                                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                                ),
                                                Text(
                                                  '₹${(invoice.totalAmount ?? 0).toStringAsFixed(2)}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    statusText,
                                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                                  ),
                                                ),
                                                OutlinedButton(
                                                  onPressed: () => context.push('/billing-invoice-details/${invoice.id}', extra: invoice),
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  child: const Text('View', style: TextStyle(fontSize: 12)),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                                      itemCount: state.billingInvoices.length,
                                      itemBuilder: (context, index) {
                                        final invoice = state.billingInvoices[index];
                                        final rawStatus = invoice.paymentStatus.replaceAll('_', ' ').toLowerCase();
                                        final statusText = rawStatus == 'paid'
                                            ? 'Paid'
                                            : (rawStatus == 'partially paid' ? 'Partially Paid' : 'Unpaid');

                                        return DocumentCard(
                                          documentNumber: invoice.invoiceNumber ?? 'BILL-XXXX',
                                          customerName: invoice.billTo.customerName,
                                          formattedDate: DateFormat('dd MMM yyyy').format(invoice.invoiceDate),
                                          documentType: DocumentType.agreement,
                                          statusText: statusText,
                                          isPending: statusText == 'Unpaid',
                                          amount: '₹${(invoice.totalAmount ?? 0).toStringAsFixed(2)}',
                                          onTap: () => context.push('/billing-invoice-details/${invoice.id}', extra: invoice),
                                        );
                                      },
                                    ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
