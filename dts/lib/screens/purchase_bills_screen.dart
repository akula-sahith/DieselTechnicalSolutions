import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_colors.dart';
import '../models/purchase_bill_model.dart';
import '../providers/purchase_bills_provider.dart';
import '../repositories/purchase_bill_repository.dart';
import '../providers/dashboard_stats_provider.dart';

class PurchaseBillsScreen extends ConsumerStatefulWidget {
  const PurchaseBillsScreen({super.key});

  @override
  ConsumerState<PurchaseBillsScreen> createState() => _PurchaseBillsScreenState();
}

class _PurchaseBillsScreenState extends ConsumerState<PurchaseBillsScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedStatus = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty) return;
    final uri = Uri.parse(urlString);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open attachment url.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open attachment: $e')),
      );
    }
  }

  void _showAddEditBillDialog({PurchaseBillModel? existingBill}) {
    final imagePicker = ImagePicker();
    File? selectedFile;
    
    final vendorNameCtrl = TextEditingController(text: existingBill?.vendorName ?? '');
    final billNumberCtrl = TextEditingController(text: existingBill?.billNumber ?? '');
    final amountCtrl = TextEditingController(text: existingBill?.amount != null ? existingBill!.amount.toString() : '');
    final taxAmountCtrl = TextEditingController(text: existingBill?.taxAmount != null ? existingBill!.taxAmount.toString() : '');
    final remarksCtrl = TextEditingController(text: existingBill?.remarks ?? '');
    String status = existingBill?.status ?? 'pending';
    DateTime billDate = existingBill?.billDate ?? DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              existingBill == null ? 'Upload Purchase Bill' : 'Edit Purchase Bill',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Attachment Selection
                  if (existingBill == null) ...[
                    if (selectedFile == null) ...[
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await imagePicker.pickImage(source: ImageSource.gallery);
                          if (picked != null) {
                            setState(() => selectedFile = File(picked.path));
                          }
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Pick from Gallery'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await imagePicker.pickImage(source: ImageSource.camera);
                          if (picked != null) {
                            setState(() => selectedFile = File(picked.path));
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Capture using Camera'),
                      ),
                    ] else ...[
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                          image: DecorationImage(
                            image: FileImage(selectedFile!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => setState(() => selectedFile = null),
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        label: const Text('Remove Photo', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                    const Divider(height: 24),
                  ],

                  // Vendor Name
                  TextFormField(
                    controller: vendorNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Vendor Name *',
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bill Number
                  TextFormField(
                    controller: billNumberCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Bill Number',
                      prefixIcon: Icon(Icons.receipt),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bill Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: billDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => billDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Text(DateFormat('dd-MM-yyyy').format(billDate)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bill Amount
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Total Bill Amount (₹) *',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tax Amount
                  TextFormField(
                    controller: taxAmountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'GST Tax Amount (₹)',
                      prefixIcon: Icon(Icons.percent),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Remarks
                  TextFormField(
                    controller: remarksCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Remarks',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.info),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => status = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final vendorName = vendorNameCtrl.text.trim();
                  final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                  final taxAmount = double.tryParse(taxAmountCtrl.text) ?? 0.0;

                  if (vendorName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vendor Name is required'), backgroundColor: AppColors.error),
                    );
                    return;
                  }

                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid positive bill amount'), backgroundColor: AppColors.error),
                    );
                    return;
                  }

                  if (existingBill == null && selectedFile == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please capture or select a bill photo'), backgroundColor: AppColors.error),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(existingBill == null ? 'Uploading bill...' : 'Updating bill...')),
                  );

                  try {
                    final repo = ref.read(purchaseBillRepositoryProvider);
                    if (existingBill == null) {
                      await repo.createPurchaseBill(
                        vendorName: vendorName,
                        amount: amount,
                        taxAmount: taxAmount,
                        billNumber: billNumberCtrl.text.trim(),
                        billDate: billDate,
                        remarks: remarksCtrl.text.trim(),
                        status: status,
                        attachmentFile: selectedFile!,
                      );
                    } else {
                      await repo.updatePurchaseBill(
                        id: existingBill.id!,
                        vendorName: vendorName,
                        amount: amount,
                        taxAmount: taxAmount,
                        billNumber: billNumberCtrl.text.trim(),
                        billDate: billDate,
                        remarks: remarksCtrl.text.trim(),
                        status: status,
                      );
                    }

                    // Reload lists and stats
                    ref.read(purchaseBillsProvider.notifier).refresh();
                    ref.read(dashboardStatsProvider.notifier).fetchStats();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(existingBill == null ? 'Bill uploaded successfully!' : 'Bill updated successfully!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Operation failed: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteBill(PurchaseBillModel bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Purchase Bill'),
        content: Text('Are you sure you want to delete the bill from "${bill.vendorName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleting bill...')));
      try {
        final repo = ref.read(purchaseBillRepositoryProvider);
        await repo.deletePurchaseBill(bill.id!);
        ref.read(purchaseBillsProvider.notifier).refresh();
        ref.read(dashboardStatsProvider.notifier).fetchStats();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bill deleted successfully!'), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseBillsProvider);
    final notifier = ref.read(purchaseBillsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Purchase Bills'),
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search by vendor...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: notifier.search,
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: '', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedStatus = val);
                      notifier.filterStatus(val);
                    }
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: state.isLoading && state.purchaseBills.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: ${state.error}'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => notifier.refresh(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : state.purchaseBills.isEmpty
                        ? const Center(child: Text('No purchase bills found.'))
                        : RefreshIndicator(
                            onRefresh: () => notifier.refresh(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: state.purchaseBills.length,
                              itemBuilder: (context, index) {
                                final bill = state.purchaseBills[index];
                                final isPaid = bill.status.toLowerCase() == 'paid';
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isPaid ? AppColors.success.withOpacity(0.5) : AppColors.warning.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: isPaid ? AppColors.success : AppColors.warning,
                                          width: 5,
                                        ),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                bill.vendorName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: (isPaid ? AppColors.success : AppColors.warning).withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                bill.status.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isPaid ? AppColors.success : AppColors.warning,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (bill.billNumber != null && bill.billNumber!.isNotEmpty)
                                          Text('Bill No: ${bill.billNumber}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                        Text('Date: ${DateFormat('dd-MM-yyyy').format(bill.billDate)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                        const Divider(height: 24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Amount: ₹${bill.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                if (bill.taxAmount > 0)
                                                  Text('GST Tax: ₹${bill.taxAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.open_in_new, color: AppColors.primary),
                                                  tooltip: 'View Bill Attachment',
                                                  onPressed: () => _launchUrl(bill.attachmentUrl),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                                                  tooltip: 'Edit Bill Metadata',
                                                  onPressed: () => _showAddEditBillDialog(existingBill: bill),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                                  tooltip: 'Delete Bill',
                                                  onPressed: () => _deleteBill(bill),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditBillDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
