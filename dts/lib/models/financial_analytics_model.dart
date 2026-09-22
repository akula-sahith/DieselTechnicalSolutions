class CountAndAmount {
  final int count;
  final double totalAmount;

  CountAndAmount({required this.count, required this.totalAmount});

  factory CountAndAmount.fromJson(Map<String, dynamic> json) {
    return CountAndAmount(
      count: (json['count'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MonthlyDetailModel {
  final int year;
  final int month;
  final String monthName;
  final double totalRevenue;
  final double totalCosts;
  final double netProfit;
  final int totalTransactions;
  final CountAndAmount taxInvoices;
  final CountAndAmount cashInvoices;
  final CountAndAmount purchaseBills;
  final CountAndAmount estimates;
  final CountAndAmount agreements;
  final CountAndAmount serviceReports;
  final CountAndAmount deliveryChallans;
  final List<WeeklyDetailItem> weeklyAnalytics;

  MonthlyDetailModel({
    required this.year,
    required this.month,
    required this.monthName,
    required this.totalRevenue,
    required this.totalCosts,
    required this.netProfit,
    required this.totalTransactions,
    required this.taxInvoices,
    required this.cashInvoices,
    required this.purchaseBills,
    required this.estimates,
    required this.agreements,
    required this.serviceReports,
    required this.deliveryChallans,
    required this.weeklyAnalytics,
  });

  factory MonthlyDetailModel.fromJson(Map<String, dynamic> json) {
    final summary = json['monthSummary'] as Map<String, dynamic>? ?? {};
    final rev = json['revenueBreakdown'] as Map<String, dynamic>? ?? {};
    final cost = json['costBreakdown'] as Map<String, dynamic>? ?? {};
    final docs = json['documentAnalysis'] as Map<String, dynamic>? ?? {};

    final weeksRaw = json['weeklyAnalytics'] as List?;
    final weeks = weeksRaw != null
        ? weeksRaw.map((e) => WeeklyDetailItem.fromJson(e as Map<String, dynamic>)).toList()
        : <WeeklyDetailItem>[];

    return MonthlyDetailModel(
      year: (json['year'] as num?)?.toInt() ?? 2026,
      month: (json['month'] as num?)?.toInt() ?? 9,
      monthName: json['monthName'] ?? '',
      totalRevenue: (summary['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalCosts: (summary['totalCosts'] as num?)?.toDouble() ?? 0.0,
      netProfit: (summary['netProfit'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: (summary['totalTransactions'] as num?)?.toInt() ?? 0,
      taxInvoices: CountAndAmount.fromJson(rev['taxInvoices'] as Map<String, dynamic>? ?? {}),
      cashInvoices: CountAndAmount.fromJson(rev['cashInvoices'] as Map<String, dynamic>? ?? {}),
      purchaseBills: CountAndAmount.fromJson(cost['purchaseBills'] as Map<String, dynamic>? ?? {}),
      estimates: CountAndAmount.fromJson(docs['estimates'] as Map<String, dynamic>? ?? {}),
      agreements: CountAndAmount.fromJson(docs['agreements'] as Map<String, dynamic>? ?? {}),
      serviceReports: CountAndAmount.fromJson(docs['serviceReports'] as Map<String, dynamic>? ?? {}),
      deliveryChallans: CountAndAmount.fromJson(docs['deliveryChallans'] as Map<String, dynamic>? ?? {}),
      weeklyAnalytics: weeks,
    );
  }
}

class WeeklyDetailItem {
  final String weekLabel;
  final String startDate;
  final String endDate;
  final String dateRangeLabel;
  final double revenue;
  final double costs;
  final double profit;
  final int documentsCount;

  WeeklyDetailItem({
    required this.weekLabel,
    required this.startDate,
    required this.endDate,
    required this.dateRangeLabel,
    required this.revenue,
    required this.costs,
    required this.profit,
    required this.documentsCount,
  });

  factory WeeklyDetailItem.fromJson(Map<String, dynamic> json) {
    return WeeklyDetailItem(
      weekLabel: json['weekLabel'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      dateRangeLabel: json['dateRangeLabel'] ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      costs: (json['costs'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
      documentsCount: (json['documentsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class WeekDocumentItem {
  final String id;
  final String documentNumber;
  final String documentType;
  final String customerName;
  final DateTime date;
  final double? amount;
  final String status;
  final Map<String, dynamic>? rawDocument;

  WeekDocumentItem({
    required this.id,
    required this.documentNumber,
    required this.documentType,
    required this.customerName,
    required this.date,
    this.amount,
    required this.status,
    this.rawDocument,
  });

  factory WeekDocumentItem.fromJson(Map<String, dynamic> json) {
    return WeekDocumentItem(
      id: json['id']?.toString() ?? '',
      documentNumber: json['documentNumber'] ?? '',
      documentType: json['documentType'] ?? '',
      customerName: json['customerName'] ?? '',
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() : DateTime.now(),
      amount: (json['amount'] as num?)?.toDouble(),
      status: json['status'] ?? '',
      rawDocument: json['rawDocument'] as Map<String, dynamic>?,
    );
  }
}

class WeekDocumentsResponse {
  final String dateRangeLabel;
  final String startDate;
  final String endDate;
  final int totalCount;
  final List<WeekDocumentItem> documents;

  WeekDocumentsResponse({
    required this.dateRangeLabel,
    required this.startDate,
    required this.endDate,
    required this.totalCount,
    required this.documents,
  });

  factory WeekDocumentsResponse.fromJson(Map<String, dynamic> json) {
    final listRaw = json['documents'] as List?;
    final docsList = listRaw != null
        ? listRaw.map((e) => WeekDocumentItem.fromJson(e as Map<String, dynamic>)).toList()
        : <WeekDocumentItem>[];

    return WeekDocumentsResponse(
      dateRangeLabel: json['dateRangeLabel'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      documents: docsList,
    );
  }
}
