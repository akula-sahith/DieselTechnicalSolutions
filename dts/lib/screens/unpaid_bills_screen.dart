import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/tax_invoice_model.dart';
import '../models/billing_invoice_model.dart';
import '../models/purchase_bill_model.dart';
import '../repositories/tax_invoice_repository.dart';
import '../repositories/billing_invoice_repository.dart';
import '../repositories/purchase_bill_repository.dart';
import '../widgets/bottom_nav_bar.dart';

class UnpaidBillsScreen extends ConsumerStatefulWidget {
  const UnpaidBillsScreen({super.key});

  @override
  ConsumerState<UnpaidBillsScreen> createState() => _UnpaidBillsScreenState();
}

class _UnpaidBillsScreenState extends ConsumerState<UnpaidBillsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  List<TaxInvoiceModel> _unpaidTaxInvoices = [];
  List<BillingInvoiceModel> _unpaidCashInvoices = [];
  List<PurchaseBillModel> _unpaidPurchaseBills = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUnpaidData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUnpaidData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final taxRepo = ref.read(taxInvoiceRepositoryProvider);
      final cashRepo = ref.read(billingInvoiceRepositoryProvider);
      final billRepo = ref.read(purchaseBillRepositoryProvider);

      final taxRes = await taxRepo.getTaxInvoices(all: true, paymentStatus: 'unpaid,partially_paid');
      final cashRes = await cashRepo.getBillingInvoices(all: true, paymentStatus: 'unpaid,partially_paid');
      final billRes = await billRepo.getPurchaseBills(all: true, status: 'pending');

      setState(() {
        _unpaidTaxInvoices = taxRes.taxInvoices
            .where((i) => i.paymentStatus.toLowerCase() != 'paid')
            .toList();
        _unpaidCashInvoices = cashRes.billingInvoices
            .where((i) => i.paymentStatus.toLowerCase() != 'paid')
            .toList();
        _unpaidPurchaseBills = billRes.purchaseBills
            .where((b) => b.status.toLowerCase() != 'paid')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double get _totalCustomerReceivables {
    final taxSum = _unpaidTaxInvoices.fold<double>(0.0, (s, i) => s + i.outstandingAmount);
    final cashSum = _unpaidCashInvoices.fold<double>(0.0, (s, i) => s + i.outstandingAmount);
    return taxSum + cashSum;
  }

  double get _totalVendorPayables {
    return _unpaidPurchaseBills.fold<double>(0.0, (s, b) => s + b.amount);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Unpaid Bills & Receivables'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUnpaidData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Customer Receivables (${_unpaidTaxInvoices.length + _unpaidCashInvoices.length})'),
            Tab(text: 'Supplier Payables (${_unpaidPurchaseBills.length})'),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: -1),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchUnpaidData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchUnpaidData,
                  child: Column(
                    children: [
                      // Header Stats Overview Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFEE2E2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Customer Outstanding',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.error,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currencyFmt.format(_totalCustomerReceivables),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_unpaidTaxInvoices.length + _unpaidCashInvoices.length} unpaid bill(s)',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFEF3C7)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Supplier Bills Payable',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFD97706),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currencyFmt.format(_totalVendorPayables),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_unpaidPurchaseBills.length} pending bill(s)',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildCustomerReceivablesTab(),
                            _buildSupplierPayablesTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCustomerReceivablesTab() {
    final List<dynamic> combinedList = [
      ..._unpaidTaxInvoices,
      ..._unpaidCashInvoices,
    ];

    combinedList.sort((a, b) {
      final dateA = a is TaxInvoiceModel ? a.invoiceDate : (b as BillingInvoiceModel).invoiceDate;
      final dateB = b is TaxInvoiceModel ? b.invoiceDate : (a as BillingInvoiceModel).invoiceDate;
      return dateB.compareTo(dateA);
    });

    if (combinedList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
            SizedBox(height: 12),
            Text('No unpaid customer invoices!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('All customer tax and cash invoices are paid.', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 80),
      itemCount: combinedList.length,
      itemBuilder: (context, index) {
        final item = combinedList[index];
        final isTax = item is TaxInvoiceModel;
        final String docNumber = isTax
            ? (item.invoiceNumber ?? 'INV-XXXX')
            : (item as BillingInvoiceModel).invoiceNumber ?? 'BILL-XXXX';
        final String customerName = isTax ? item.billTo.customerName : (item as BillingInvoiceModel).billTo.customerName;
        final DateTime invoiceDate = isTax ? item.invoiceDate : (item as BillingInvoiceModel).invoiceDate;
        final double totalAmount = isTax ? (item.totalAmount ?? 0.0) : (item as BillingInvoiceModel).totalAmount ?? 0.0;
        final double outstanding = isTax ? item.outstandingAmount : (item as BillingInvoiceModel).outstandingAmount;
        final double received = isTax ? item.receivedAmount : (item as BillingInvoiceModel).receivedAmount;
        final String statusRaw = isTax ? item.paymentStatus : (item as BillingInvoiceModel).paymentStatus;
        final String id = isTax ? item.id! : (item as BillingInvoiceModel).id!;

        final isPartiallyPaid = statusRaw.toLowerCase().contains('partially');
        final statusText = isPartiallyPaid ? 'PARTIALLY PAID' : 'UNPAID';
        final statusColor = isPartiallyPaid ? AppColors.warning : AppColors.error;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: statusColor.withOpacity(0.4)),
          ),
          child: InkWell(
            onTap: () {
              if (isTax) {
                context.push('/tax-invoice-details/$id', extra: item);
              } else {
                context.push('/billing-invoice-details/$id', extra: item);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isTax ? AppColors.primary.withOpacity(0.1) : Colors.cyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isTax ? 'TAX INVOICE' : 'CASH INVOICE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isTax ? AppColors.primary : Colors.cyan[800],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(docNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                  const SizedBox(height: 2),
                  Text(customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(DateFormat('dd MMM yyyy').format(invoiceDate), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total: ₹${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text('Received: ₹${received.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.success)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Outstanding:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            '₹${outstanding.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupplierPayablesTab() {
    if (_unpaidPurchaseBills.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
            SizedBox(height: 12),
            Text('No pending purchase bills!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('All supplier purchase bills are paid.', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 80),
      itemCount: _unpaidPurchaseBills.length,
      itemBuilder: (context, index) {
        final bill = _unpaidPurchaseBills[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.warning.withOpacity(0.5)),
          ),
          child: InkWell(
            onTap: () => context.push('/purchase-bills'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        bill.vendorName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PENDING',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (bill.billNumber != null && bill.billNumber!.isNotEmpty)
                    Text('Bill No: ${bill.billNumber}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text('Date: ${DateFormat('dd-MM-yyyy').format(bill.billDate)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('GST Tax: ₹${bill.taxAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text(
                        'Amount Payable: ₹${bill.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.error),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
