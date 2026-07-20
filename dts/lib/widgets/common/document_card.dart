import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// The type of document for visual distinction
enum DocumentType { report, agreement, quotation }

class DocumentCard extends StatelessWidget {
  final String documentNumber;
  final String customerName;
  final String formattedDate;
  final DocumentType documentType;
  final String? statusText;
  final String? amount;
  final bool isPending;
  final VoidCallback onTap;

  const DocumentCard({
    super.key,
    required this.documentNumber,
    required this.customerName,
    required this.formattedDate,
    required this.documentType,
    required this.onTap,
    this.statusText,
    this.amount,
    this.isPending = false,
  });

  Color get _typeColor {
    switch (documentType) {
      case DocumentType.report:
        return AppColors.reportOrange;
      case DocumentType.agreement:
        return AppColors.agreementGreen;
      case DocumentType.quotation:
        return AppColors.quotationBlue;
    }
  }

  IconData get _typeIcon {
    switch (documentType) {
      case DocumentType.report:
        return Icons.description_outlined;
      case DocumentType.agreement:
        return Icons.handshake_outlined;
      case DocumentType.quotation:
        return Icons.request_quote_outlined;
    }
  }

  String get _typeLabel {
    switch (documentType) {
      case DocumentType.report:
        return 'Report';
      case DocumentType.agreement:
        return 'Agreement';
      case DocumentType.quotation:
        return 'Quotation';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Leading icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_typeIcon, color: _typeColor, size: 22),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: document number + type badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              documentNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildTypeBadge(),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Customer name
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),

                      // Bottom row: date + status or amount
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 11, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                          const Spacer(),
                          if (statusText != null) _buildStatusBadge(),
                          if (amount != null)
                            Text(
                              amount ?? '',
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
                ),

                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _typeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _typeLabel,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: _typeColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final bgColor = isPending
        ? AppColors.warning.withOpacity(0.12)
        : AppColors.success.withOpacity(0.12);
    final textColor = isPending ? AppColors.warning : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        statusText ?? '',
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
