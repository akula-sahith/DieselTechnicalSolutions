import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/financial_analytics_model.dart';
import '../repositories/analytics_repository.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/common/adaptive_layout.dart';

class WeekDocumentsScreen extends ConsumerStatefulWidget {
  final String startDate;
  final String endDate;
  final String label;

  const WeekDocumentsScreen({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.label,
  });

  @override
  ConsumerState<WeekDocumentsScreen> createState() => _WeekDocumentsScreenState();
}

class _WeekDocumentsScreenState extends ConsumerState<WeekDocumentsScreen> {
  bool _isLoading = true;
  String? _error;
  WeekDocumentsResponse? _response;

  @override
  void initState() {
    super.initState();
    _fetchWeekDocuments();
  }

  Future<void> _fetchWeekDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(analyticsRepositoryProvider);
      final res = await repo.getWeekDocuments(widget.startDate, widget.endDate);
      setState(() {
        _response = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##,##0.00', 'en_IN').format(amount);
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'tax invoice':
        return AppColors.primary;
      case 'cash invoice':
        return AppColors.accent;
      case 'estimate':
        return const Color(0xFFD97706);
      case 'agreement':
      case 'quotation':
        return const Color(0xFF059669);
      case 'service report':
        return AppColors.reportOrange;
      case 'purchase bill':
        return const Color(0xFF7C3AED);
      case 'delivery challan':
        return const Color(0xFF0891B2);
      default:
        return AppColors.textSecondary;
    }
  }

  void _onDocumentTap(WeekDocumentItem doc) {
    final type = doc.documentType.toLowerCase();
    if (type == 'tax invoice') {
      context.push('/tax-invoice-details/${doc.id}');
    } else if (type == 'cash invoice') {
      context.push('/billing-invoice-details/${doc.id}');
    } else if (type == 'estimate') {
      context.push('/estimate-details/${doc.id}');
    } else if (type == 'agreement' || type == 'quotation') {
      context.push('/agreement-details/${doc.id}');
    } else if (type == 'service report') {
      context.push('/report-details/${doc.id}?draft=false');
    } else if (type == 'delivery challan') {
      context.push('/delivery-challan-details/${doc.id}');
    } else if (type == 'purchase bill') {
      context.push('/purchase-bills');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateRangeText = _response?.dateRangeLabel.isNotEmpty == true
        ? _response!.dateRangeLabel
        : (widget.label.isNotEmpty ? widget.label : 'Selected Week');

    return AdaptiveLayout(
      currentRoute: '/week-documents',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Week Documents'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchWeekDocuments,
            ),
          ],
        ),
        bottomNavigationBar: const CustomBottomNavBar(currentIndex: -1),
        body: Column(
          children: [
            // Week Date Range Banner Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.date_range_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        dateRangeText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (_response != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_response!.totalCount} document(s) recorded during this week',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: _isLoading
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
                                onPressed: _fetchWeekDocuments,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _response == null || _response!.documents.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_outlined, size: 48, color: AppColors.textLight),
                                  SizedBox(height: 12),
                                  Text(
                                    'No documents found for this week.',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchWeekDocuments,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                itemCount: _response!.documents.length,
                                itemBuilder: (context, index) {
                                  final doc = _response!.documents[index];
                                  final typeColor = _getTypeColor(doc.documentType);
                                  final formattedDate = DateFormat('dd MMM yyyy').format(doc.date);

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: AppColors.border.withOpacity(0.5)),
                                    ),
                                    child: InkWell(
                                      onTap: () => _onDocumentTap(doc),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: typeColor.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    doc.documentType.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: typeColor,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    doc.status,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF475569),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  doc.documentNumber,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                                if (doc.amount != null)
                                                  Text(
                                                    '₹${_formatCurrency(doc.amount!)}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              doc.customerName,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textLight),
                                                const SizedBox(width: 4),
                                                Text(
                                                  formattedDate,
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                                ),
                                                const Spacer(),
                                                const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textLight),
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
      ),
    );
  }
}
