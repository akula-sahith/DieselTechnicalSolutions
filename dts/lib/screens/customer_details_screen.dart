import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../models/customer_model.dart';
import '../repositories/customer_repository.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/document_card.dart';

class CustomerDetailsScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailsScreen({
    super.key,
    required this.customerId,
  });

  @override
  ConsumerState<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends ConsumerState<CustomerDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CustomerModel? _customer;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCustomerDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(customerRepositoryProvider);
      final customer = await repo.getCustomerById(widget.customerId);
      setState(() {
        _customer = customer;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadCustomerDetails,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final customer = _customer!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer.customerName),
            if (customer.companyName.isNotEmpty)
              Text(
                customer.companyName,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'share') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing customer details feature coming soon.')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_rounded, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text('Share Customer Details'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Estimates'),
            Tab(text: 'Tax Invoices'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(customer),
          _buildEstimatesTab(customer),
          _buildInvoicesTab(customer),
        ],
      ),
    );
  }

  Widget _buildProfileTab(CustomerModel customer) {
    final lastInvoice = customer.lastInvoiceDate != null
        ? DateFormat('dd-MM-yyyy').format(customer.lastInvoiceDate!)
        : '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Customer Information
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow('Customer Name', customer.customerName),
                  _buildDetailRow('Company Name', customer.companyName.isNotEmpty ? customer.companyName : '-'),
                  _buildDetailRow('Contact Person', customer.contactPerson.isNotEmpty ? customer.contactPerson : '-'),
                  _buildDetailRow('Mobile Number', customer.mobileNumber),
                  _buildDetailRow('Email', customer.email.isNotEmpty ? customer.email : '-'),
                  _buildDetailRow('GST Number', customer.gstNumber.isNotEmpty ? customer.gstNumber : '-'),
                  _buildDetailRow('Address', customer.address.isNotEmpty ? customer.address : '-'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Business Information
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Business Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow('Total Invoices', customer.totalInvoices.toString()),
                  _buildDetailRow('Last Invoice Date', lastInvoice),
                  _buildDetailRow(
                    'Total Business Amount',
                    '₹${customer.totalBusinessAmount.toStringAsFixed(2)}',
                    isBold: true,
                    valueColor: AppColors.accent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimatesTab(CustomerModel customer) {
    if (customer.estimates.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.request_quote_outlined, size: 48, color: AppColors.textLight),
              SizedBox(height: 12),
              Text(
                'No Estimate History',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              SizedBox(height: 4),
              Text(
                'No estimates have been created for this customer yet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: customer.estimates.length,
      itemBuilder: (context, index) {
        final estimate = customer.estimates[index];
        final formattedDate = DateFormat('dd MMM yyyy').format(estimate.estimateDate);

        return DocumentCard(
          documentNumber: estimate.estimateNumber ?? 'Pending',
          customerName: estimate.estimateFor.customerName,
          formattedDate: formattedDate,
          documentType: DocumentType.quotation,
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

  Widget _buildInvoicesTab(CustomerModel customer) {
    if (customer.taxInvoices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_outlined, size: 48, color: AppColors.textLight),
              SizedBox(height: 12),
              Text(
                'No Tax Invoice History',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              SizedBox(height: 4),
              Text(
                'No tax invoices have been created for this customer yet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: customer.taxInvoices.length,
      itemBuilder: (context, index) {
        final invoice = customer.taxInvoices[index];
        final formattedDate = DateFormat('dd MMM yyyy').format(invoice.invoiceDate);
        final paymentStatus = invoice.paymentDetails?.status ?? 'Unpaid';

        return DocumentCard(
          documentNumber: invoice.invoiceNumber ?? 'Pending',
          customerName: invoice.billTo.customerName,
          formattedDate: formattedDate,
          documentType: DocumentType.agreement,
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

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
