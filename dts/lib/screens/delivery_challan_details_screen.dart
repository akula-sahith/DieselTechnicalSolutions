import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../models/delivery_challan_model.dart';
import '../repositories/delivery_challan_repository.dart';
import '../providers/delivery_challans_provider.dart';
import '../services/pdf_service.dart';
import 'pdf_viewer_screen.dart';

class DeliveryChallanDetailsScreen extends ConsumerStatefulWidget {
  final String challanId;
  final DeliveryChallanModel? initialChallan;

  const DeliveryChallanDetailsScreen({
    super.key,
    required this.challanId,
    this.initialChallan,
  });

  @override
  ConsumerState<DeliveryChallanDetailsScreen> createState() =>
      _DeliveryChallanDetailsScreenState();
}

class _DeliveryChallanDetailsScreenState
    extends ConsumerState<DeliveryChallanDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DeliveryChallanModel? _challan;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialChallan != null) {
      _challan = widget.initialChallan;
      _isLoading = false;
    }
    _loadChallan();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChallan() async {
    if (_challan == null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final repo = ref.read(deliveryChallanRepositoryProvider);
      final challan = await repo.getDeliveryChallanById(widget.challanId);
      setState(() {
        _challan = challan;
        _isLoading = false;
      });
    } catch (e) {
      if (_challan == null) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _downloadPdf() async {
    if (_challan == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Generating Delivery Challan PDF...'),
          duration: Duration(seconds: 1)),
    );
    try {
      final pdfService = ref.read(pdfServiceProvider);
      await pdfService.printOrSaveDeliveryChallanPdf(_challan!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to generate PDF: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _sharePdf() async {
    if (_challan == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Preparing Delivery Challan PDF for sharing...'),
          duration: Duration(seconds: 1)),
    );
    try {
      final pdfService = ref.read(pdfServiceProvider);
      await pdfService.shareDeliveryChallanPdf(_challan!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to share PDF: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _viewAsPdf() {
    if (_challan == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          title: 'Challan ${_challan!.challanNumber ?? ''}',
          pdfBuilder: () {
            final pdfService = ref.read(pdfServiceProvider);
            return pdfService.generateDeliveryChallanPdf(_challan!);
          },
        ),
      ),
    );
  }

  void _deleteChallan() async {
    if (_challan == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Delivery Challan'),
        content: const Text(
            'Are you sure you want to delete this delivery challan? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleting delivery challan...')),
      );
      try {
        await ref
            .read(deliveryChallanRepositoryProvider)
            .deleteDeliveryChallan(widget.challanId);
        ref.read(deliveryChallansProvider.notifier).refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Delivery Challan deleted successfully.')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to delete: $e'),
                backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _challan == null) {
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
                  onPressed: _loadChallan,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final challan = _challan!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Challan No. ${challan.challanNumber ?? ''}'),
            Text(
              challan.deliveryChallanFor.customerName,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _viewAsPdf,
            tooltip: 'View as PDF',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'download') _downloadPdf();
              if (value == 'share') _sharePdf();
              if (value == 'edit') {
                context.push('/create-delivery-challan', extra: challan);
              }
              if (value == 'delete') _deleteChallan();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text('Edit Delivery Challan'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download_rounded, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text('Download PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_rounded, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text('Share PDF'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete Delivery Challan',
                        style: TextStyle(color: AppColors.error)),
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
            Tab(text: 'Details'),
            Tab(text: 'Items'),
            Tab(text: 'Sign-off'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(challan),
                _buildItemsTab(challan),
                _buildSignaturesTab(challan),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sharePdf,
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share PDF'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _downloadPdf,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Download PDF'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(DeliveryChallanModel challan) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Delivery Challan',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          challan.status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildDetailRow('Challan Number', challan.challanNumber ?? '-'),
                  _buildDetailRow(
                      'Date', DateFormat('dd-MM-yyyy').format(challan.challanDate)),
                  _buildDetailRow('Place of Supply', challan.placeOfSupply),
                  _buildDetailRow(
                      'Total Quantity', '${challan.totalQuantity}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Delivery Challan For',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  const Divider(height: 20),
                  _buildDetailRow('Customer Name', challan.deliveryChallanFor.customerName),
                  _buildDetailRow('Address', challan.deliveryChallanFor.address),
                  if (challan.deliveryChallanFor.contactPerson != null &&
                      challan.deliveryChallanFor.contactPerson!.isNotEmpty)
                    _buildDetailRow('Contact Person', challan.deliveryChallanFor.contactPerson!),
                  _buildDetailRow('Contact No.', challan.deliveryChallanFor.contactNumber),
                  if (challan.deliveryChallanFor.gstinNumber != null &&
                      challan.deliveryChallanFor.gstinNumber!.isNotEmpty)
                    _buildDetailRow('GSTIN', challan.deliveryChallanFor.gstinNumber!),
                  _buildDetailRow('State', challan.deliveryChallanFor.state),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Transportation Details',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  const Divider(height: 20),
                  _buildDetailRow(
                      'Vehicle Number',
                      challan.transportationDetails.vehicleNumber?.isNotEmpty == true
                          ? challan.transportationDetails.vehicleNumber!
                          : 'N/A'),
                  _buildDetailRow(
                      'Destination',
                      challan.transportationDetails.destinationLocation?.isNotEmpty == true
                          ? challan.transportationDetails.destinationLocation!
                          : 'N/A'),
                  _buildDetailRow(
                      'Transport Name',
                      challan.transportationDetails.transportName?.isNotEmpty == true
                          ? challan.transportationDetails.transportName!
                          : 'N/A'),
                  _buildDetailRow(
                      'LR Number',
                      challan.transportationDetails.lrNumber?.isNotEmpty == true
                          ? challan.transportationDetails.lrNumber!
                          : 'N/A'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTab(DeliveryChallanModel challan) {
    if (challan.items.isEmpty) {
      return const Center(child: Text('No items found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challan.items.length,
      itemBuilder: (context, index) {
        final item = challan.items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  radius: 14,
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.itemName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      if (item.hsnSac != null && item.hsnSac!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('HSN/SAC: ${item.hsnSac}',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                Text('Qty: ${item.quantity}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignaturesTab(DeliveryChallanModel challan) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Terms & Conditions',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  const Divider(height: 20),
                  Text(
                    challan.termsAndConditions ?? 'No terms specified.',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Signatures & Acknowledgements',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  const Divider(height: 20),
                  _buildDetailRow('Received By',
                      challan.receivedBy?.name?.isNotEmpty == true ? challan.receivedBy!.name! : 'N/A'),
                  _buildDetailRow('Received Comment',
                      challan.receivedBy?.comment?.isNotEmpty == true ? challan.receivedBy!.comment! : 'N/A'),
                  const Divider(height: 16),
                  _buildDetailRow('Delivered By',
                      challan.deliveredBy?.name?.isNotEmpty == true ? challan.deliveredBy!.name! : 'N/A'),
                  _buildDetailRow('Delivered Comment',
                      challan.deliveredBy?.comment?.isNotEmpty == true ? challan.deliveredBy!.comment! : 'N/A'),
                  const Divider(height: 16),
                  const Text('Authorized Signatory',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('For: Diesel Technical Solutions',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
