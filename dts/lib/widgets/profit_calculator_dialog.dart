import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/profit_details_model.dart';

class ProfitCalculatorItemData {
  final String itemName;
  final double sellingPrice;
  final double quantity;
  String itemType; // 'product' or 'service'
  String serviceProvider; // 'self' or 'other'
  TextEditingController costController;

  ProfitCalculatorItemData({
    required this.itemName,
    required this.sellingPrice,
    required this.quantity,
    this.itemType = 'product',
    this.serviceProvider = 'self',
    required this.costController,
  });

  double get calculatedCost {
    final rawCost = double.tryParse(costController.text.trim()) ?? 0.0;
    if (itemType == 'service') {
      if (serviceProvider == 'self') {
        return 0.0; // Self service charge cost is 0 => 100% profit
      } else {
        return rawCost; // Other service vendor cost
      }
    } else {
      // Product / Material cost
      return rawCost * quantity;
    }
  }

  double get calculatedProfit {
    return sellingPrice - calculatedCost;
  }
}

class ProfitCalculatorDialog extends StatefulWidget {
  final String invoiceTitle;
  final List<Map<String, dynamic>> rawItems; // [{itemName, quantity, pricePerUnit, amount}]
  final double invoiceTotalAmount;
  final ProfitDetails? initialProfitDetails;
  final Function(ProfitDetails profitDetails) onSave;

  const ProfitCalculatorDialog({
    super.key,
    required this.invoiceTitle,
    required this.rawItems,
    required this.invoiceTotalAmount,
    this.initialProfitDetails,
    required this.onSave,
  });

  @override
  State<ProfitCalculatorDialog> createState() => _ProfitCalculatorDialogState();
}

class _ProfitCalculatorDialogState extends State<ProfitCalculatorDialog> {
  late List<ProfitCalculatorItemData> _itemDataList;

  @override
  void initState() {
    super.initState();
    _itemDataList = [];

    final initialItemsMap = <String, ProfitItemDetails>{};
    if (widget.initialProfitDetails != null) {
      for (final pi in widget.initialProfitDetails!.items) {
        initialItemsMap[pi.itemName] = pi;
      }
    }

    for (final raw in widget.rawItems) {
      final name = (raw['itemName'] ?? 'Item').toString();
      final qty = (raw['quantity'] as num?)?.toDouble() ?? 1.0;
      final priceUnit = (raw['pricePerUnit'] as num?)?.toDouble() ?? 0.0;
      final totalSell = (raw['amount'] as num?)?.toDouble() ?? (qty * priceUnit);

      final prevSaved = initialItemsMap[name];

      // Smart default detection for service charge
      String type = prevSaved?.itemType ?? 'product';
      if (prevSaved == null) {
        final lowerName = name.toLowerCase();
        if (lowerName.contains('service') ||
            lowerName.contains('charge') ||
            lowerName.contains('labor') ||
            lowerName.contains('labour') ||
            lowerName.contains('visit') ||
            lowerName.contains('transport') ||
            lowerName.contains('repair') ||
            lowerName.contains('work')) {
          type = 'service';
        }
      }

      String provider = prevSaved?.serviceProvider ?? 'self';
      double initialCost = prevSaved?.costPrice ?? 0.0;

      _itemDataList.add(
        ProfitCalculatorItemData(
          itemName: name,
          sellingPrice: totalSell,
          quantity: qty,
          itemType: type,
          serviceProvider: provider,
          costController: TextEditingController(
            text: initialCost > 0 ? initialCost.toStringAsFixed(2) : '',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final item in _itemDataList) {
      item.costController.dispose();
    }
    super.dispose();
  }

  double get _totalRevenue {
    return widget.invoiceTotalAmount > 0
        ? widget.invoiceTotalAmount
        : _itemDataList.fold<double>(0.0, (sum, i) => sum + i.sellingPrice);
  }

  double get _totalCost {
    return _itemDataList.fold<double>(0.0, (sum, i) => sum + i.calculatedCost);
  }

  double get _netProfit {
    return _totalRevenue - _totalCost;
  }

  double get _profitMargin {
    if (_totalRevenue <= 0) return 0.0;
    return (_netProfit / _totalRevenue) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.analytics_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profit Calculator',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.invoiceTitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Live Calculation Summary Header Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _netProfit >= 0 ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _netProfit >= 0 ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimated Net Profit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFmt.format(_netProfit),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _netProfit >= 0 ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (_netProfit >= 0 ? AppColors.success : AppColors.error).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Margin: ${_profitMargin.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _netProfit >= 0 ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Revenue: ${currencyFmt.format(_totalRevenue)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        'Total Cost: ${currencyFmt.format(_totalCost)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Item Details Breakdown List
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Item Cost Breakdown:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_itemDataList.length, (index) {
                      final item = _itemDataList[index];
                      final isService = item.itemType == 'service';
                      final isSelf = item.serviceProvider == 'self';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${index + 1}. ${item.itemName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Sell: ${currencyFmt.format(item.sellingPrice)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Item Type Toggle (Product / Material vs Service Charge)
                              Row(
                                children: [
                                  const Text('Item Type: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  SegmentedButton<String>(
                                    segments: const [
                                      ButtonSegment(
                                        value: 'product',
                                        label: Text('Product/Part', style: TextStyle(fontSize: 11)),
                                        icon: Icon(Icons.inventory_2_outlined, size: 14),
                                      ),
                                      ButtonSegment(
                                        value: 'service',
                                        label: Text('Service Charge', style: TextStyle(fontSize: 11)),
                                        icon: Icon(Icons.build_outlined, size: 14),
                                      ),
                                    ],
                                    selected: {item.itemType},
                                    onSelectionChanged: (Set<String> newSelection) {
                                      setState(() {
                                        item.itemType = newSelection.first;
                                      });
                                    },
                                    style: const ButtonStyle(
                                      visualDensity: VisualDensity.compact,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // If Service Charge -> Ask Self vs Other
                              if (isService) ...[
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text('Service Work Done By: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      ChoiceChip(
                                        label: const Text('Self (Direct Profit)', style: TextStyle(fontSize: 11)),
                                        selected: isSelf,
                                        selectedColor: AppColors.success.withOpacity(0.2),
                                        onSelected: (val) {
                                          if (val) {
                                            setState(() {
                                              item.serviceProvider = 'self';
                                            });
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      ChoiceChip(
                                        label: const Text('Other Vendor', style: TextStyle(fontSize: 11)),
                                        selected: !isSelf,
                                        selectedColor: AppColors.warning.withOpacity(0.2),
                                        onSelected: (val) {
                                          if (val) {
                                            setState(() {
                                              item.serviceProvider = 'other';
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],

                              // Cost Input
                              if (isService && isSelf) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '100% of ${currencyFmt.format(item.sellingPrice)} added directly to profit! (Cost: ₹0.00)',
                                          style: const TextStyle(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: item.costController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          labelText: isService
                                              ? 'Vendor / Other Cost (₹)'
                                              : 'Unit Purchase Cost (₹)',
                                          hintText: '0.00',
                                          isDense: true,
                                          prefixIcon: const Icon(Icons.currency_rupee, size: 16),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Cost: ${currencyFmt.format(item.calculatedCost)}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                        Text(
                                          'Profit: ${currencyFmt.format(item.calculatedProfit)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: item.calculatedProfit >= 0 ? AppColors.success : AppColors.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final profitItems = _itemDataList.map((i) {
                          final costVal = double.tryParse(i.costController.text.trim()) ?? 0.0;
                          return ProfitItemDetails(
                            itemName: i.itemName,
                            itemType: i.itemType,
                            serviceProvider: i.serviceProvider,
                            costPrice: costVal,
                            sellingPrice: i.sellingPrice,
                            profit: i.calculatedProfit,
                          );
                        }).toList();

                        final profitDetails = ProfitDetails(
                          netProfit: _netProfit,
                          totalCost: _totalCost,
                          profitMargin: _profitMargin,
                          calculatedAt: DateTime.now(),
                          items: profitItems,
                        );

                        widget.onSave(profitDetails);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Profit'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
