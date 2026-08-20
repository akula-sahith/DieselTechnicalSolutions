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
import '../services/pdf_merger_service.dart';

class PurchaseBillsScreen extends ConsumerStatefulWidget {
  const PurchaseBillsScreen({super.key});

  @override
  ConsumerState<PurchaseBillsScreen> createState() => _PurchaseBillsScreenState();
}

class _PurchaseBillsScreenState extends ConsumerState<PurchaseBillsScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedStatus = '';

  // Multi-selection mode state
  bool _isSelectionMode = false;
  final Set<String> _selectedBillIds = {};

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open attachment url.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open attachment: $e')),
        );
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedBillIds.clear();
      }
    });
  }

  void _selectAllBills(List<PurchaseBillModel> bills) {
    setState(() {
      if (_selectedBillIds.length == bills.length) {
        _selectedBillIds.clear();
      } else {
        _selectedBillIds.clear();
        for (final bill in bills) {
          if (bill.id != null) {
            _selectedBillIds.add(bill.id!);
          }
        }
      }
    });
  }

  Future<void> _mergeSelectedBills(List<PurchaseBillModel> allBills) async {
    final selectedBills = allBills
        .where((b) => b.id != null && _selectedBillIds.contains(b.id))
        .toList();

    if (selectedBills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one purchase bill to merge.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Merging selected bills into PDF...')),
          ],
        ),
      ),
    );

    try {
      final pdfMerger = ref.read(pdfMergerServiceProvider);
      final pdfBytes = await pdfMerger.mergePurchaseBillsToPdf(selectedBills);

      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog

        // Show export options dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Merged ${selectedBills.length} Purchase Bills'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Successfully merged ${selectedBills.length} purchase bill(s) into a unified PDF document.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Text(
                  'Total Amount: ₹${selectedBills.fold<double>(0.0, (s, b) => s + b.amount).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  pdfMerger.shareMergedPdf(
                    pdfBytes,
                    'Merged_Purchase_Bills_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}',
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Share PDF'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  pdfMerger.printOrSaveMergedPdf(
                    pdfBytes,
                    'Merged_Purchase_Bills_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}',
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text('View / Print PDF'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to merge bills: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAddEditBillDialog({PurchaseBillModel? existingBill}) {
    final imagePicker = ImagePicker();
    final List<File> selectedFiles = [];

    final vendorNameCtrl = TextEditingController(text: existingBill?.vendorName ?? '');
    final billNumberCtrl = TextEditingController(text: existingBill?.billNumber ?? '');
    final amountCtrl = TextEditingController(
      text: existingBill?.amount != null ? existingBill!.amount.toString() : '',
    );
    final taxAmountCtrl = TextEditingController(
      text: existingBill?.taxAmount != null ? existingBill!.taxAmount.toString() : '',
    );
    final remarksCtrl = TextEditingController(text: existingBill?.remarks ?? '');
    String status = existingBill?.status ?? 'pending';
    DateTime billDate = existingBill?.billDate ?? DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
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
                  // Attachment / Multi-photo Selection
                  if (existingBill == null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final pickedList = await imagePicker.pickMultiImage();
                              if (pickedList.isNotEmpty) {
                                setState(() {
                                  for (final p in pickedList) {
                                    selectedFiles.add(File(p.path));
                                  }
                                });
                              }
                            },
                            icon: const Icon(Icons.photo_library, size: 18),
                            label: const Text('Gallery (Multi)', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await imagePicker.pickImage(source: ImageSource.camera);
                              if (picked != null) {
                                setState(() {
                                  selectedFiles.add(File(picked.path));
                                });
                              }
                            },
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: const Text('Camera', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (selectedFiles.isNotEmpty) ...[
                      Text(
                        '${selectedFiles.length} photo(s) attached (Will be merged into 1 PDF):',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedFiles.length,
                          itemBuilder: (context, idx) {
                            return Stack(
                              children: [
                                Container(
                                  width: 85,
                                  height: 85,
                                  margin: const EdgeInsets.only(right: 8, top: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primary),
                                    image: DecorationImage(
                                      image: FileImage(selectedFiles[idx]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedFiles.removeAt(idx);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'P${idx + 1}',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
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
                        context: dialogContext,
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
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final vendorName = vendorNameCtrl.text.trim();
                  final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                  final taxAmount = double.tryParse(taxAmountCtrl.text) ?? 0.0;

                  if (vendorName.isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Vendor Name is required'), backgroundColor: AppColors.error),
                    );
                    return;
                  }

                  if (amount <= 0) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid positive bill amount'), backgroundColor: AppColors.error),
                    );
                    return;
                  }

                  if (existingBill == null && selectedFiles.isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Please select or capture at least one bill photo'), backgroundColor: AppColors.error),
                    );
                    return;
                  }

                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(dialogContext);
                  messenger.showSnackBar(
                    SnackBar(content: Text(existingBill == null ? 'Merging photos & uploading bill...' : 'Updating bill...')),
                  );

                  try {
                    File attachmentToUpload;
                    if (selectedFiles.length == 1) {
                      attachmentToUpload = selectedFiles.first;
                    } else if (selectedFiles.length > 1) {
                      // Merge multiple photos into a single PDF before uploading!
                      final merger = ref.read(pdfMergerServiceProvider);
                      attachmentToUpload = await merger.mergeImageFilesToPdf(selectedFiles);
                    } else {
                      attachmentToUpload = File('');
                    }

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
                        attachmentFile: attachmentToUpload,
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
                        attachmentFile: selectedFiles.isNotEmpty ? attachmentToUpload : null,
                      );
                    }

                    // Reload lists and stats
                    ref.read(purchaseBillsProvider.notifier).refresh();
                    ref.read(dashboardStatsProvider.notifier).fetchStats();

                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(existingBill == null ? 'Purchase Bill uploaded & saved!' : 'Bill updated successfully!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
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
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(const SnackBar(content: Text('Deleting bill...')));
      try {
        final repo = ref.read(purchaseBillRepositoryProvider);
        await repo.deletePurchaseBill(bill.id!);
        ref.read(purchaseBillsProvider.notifier).refresh();
        ref.read(dashboardStatsProvider.notifier).fetchStats();
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Bill deleted successfully!'), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
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
        title: Text(_isSelectionMode ? '${_selectedBillIds.length} Selected' : 'Purchase Bills'),
        actions: [
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.library_add_check),
            tooltip: _isSelectionMode ? 'Cancel Multi-Select' : 'Merge Bills to PDF',
            onPressed: _toggleSelectionMode,
          ),
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Select All',
              onPressed: () => _selectAllBills(state.purchaseBills),
            ),
        ],
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
                                final isSelected = bill.id != null && _selectedBillIds.contains(bill.id);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppColors.primary
                                          : isPaid
                                              ? AppColors.success.withOpacity(0.5)
                                              : AppColors.warning.withOpacity(0.5),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: _isSelectionMode
                                        ? () {
                                            setState(() {
                                              if (bill.id != null) {
                                                if (isSelected) {
                                                  _selectedBillIds.remove(bill.id!);
                                                } else {
                                                  _selectedBillIds.add(bill.id!);
                                                }
                                              }
                                            });
                                          }
                                        : null,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
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
                                              if (_isSelectionMode)
                                                Padding(
                                                  padding: const EdgeInsets.only(right: 8.0),
                                                  child: Checkbox(
                                                    value: isSelected,
                                                    activeColor: AppColors.primary,
                                                    onChanged: (val) {
                                                      setState(() {
                                                        if (bill.id != null) {
                                                          if (val == true) {
                                                            _selectedBillIds.add(bill.id!);
                                                          } else {
                                                            _selectedBillIds.remove(bill.id!);
                                                          }
                                                        }
                                                      });
                                                    },
                                                  ),
                                                ),
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
                                              if (!_isSelectionMode)
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
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: _isSelectionMode
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    '${_selectedBillIds.length} bill(s) selected',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _selectedBillIds.isEmpty
                        ? null
                        : () => _mergeSelectedBills(state.purchaseBills),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Merge to PDF'),
                  ),
                ],
              ),
            )
          : null,
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddEditBillDialog(),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }
}
