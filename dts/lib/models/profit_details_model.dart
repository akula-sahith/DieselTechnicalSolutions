class ProfitItemDetails {
  final String itemName;
  final String itemType; // 'product' or 'service'
  final String serviceProvider; // 'self' or 'other'
  final double costPrice;
  final double sellingPrice;
  final double profit;

  ProfitItemDetails({
    required this.itemName,
    this.itemType = 'product',
    this.serviceProvider = 'self',
    this.costPrice = 0.0,
    required this.sellingPrice,
    required this.profit,
  });

  factory ProfitItemDetails.fromJson(Map<String, dynamic> json) {
    return ProfitItemDetails(
      itemName: json['itemName'] ?? '',
      itemType: json['itemType'] ?? 'product',
      serviceProvider: json['serviceProvider'] ?? 'self',
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'itemType': itemType,
      'serviceProvider': serviceProvider,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'profit': profit,
    };
  }
}

class ProfitDetails {
  final double netProfit;
  final double totalCost;
  final double transportationFee;
  final double profitMargin;
  final DateTime? calculatedAt;
  final List<ProfitItemDetails> items;

  ProfitDetails({
    required this.netProfit,
    required this.totalCost,
    this.transportationFee = 0.0,
    required this.profitMargin,
    this.calculatedAt,
    required this.items,
  });

  factory ProfitDetails.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List?;
    final itemList = rawItems != null
        ? rawItems.map((e) => ProfitItemDetails.fromJson(e as Map<String, dynamic>)).toList()
        : <ProfitItemDetails>[];

    return ProfitDetails(
      netProfit: (json['netProfit'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
      transportationFee: (json['transportationFee'] as num?)?.toDouble() ?? 0.0,
      profitMargin: (json['profitMargin'] as num?)?.toDouble() ?? 0.0,
      calculatedAt: json['calculatedAt'] != null
          ? DateTime.tryParse(json['calculatedAt'].toString())
          : null,
      items: itemList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'netProfit': netProfit,
      'totalCost': totalCost,
      'transportationFee': transportationFee,
      'profitMargin': profitMargin,
      'calculatedAt': calculatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
