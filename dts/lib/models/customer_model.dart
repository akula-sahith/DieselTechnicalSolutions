import 'dart:convert';
import 'estimate_model.dart';
import 'tax_invoice_model.dart';

class CustomerInvoiceHistory {
  final String invoiceNumber;
  final DateTime invoiceDate;
  final double invoiceAmount;

  CustomerInvoiceHistory({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.invoiceAmount,
  });

  factory CustomerInvoiceHistory.fromJson(Map<String, dynamic> json) {
    return CustomerInvoiceHistory(
      invoiceNumber: json['invoiceNumber'] ?? '',
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.tryParse(json['invoiceDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      invoiceAmount: (json['invoiceAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate.toIso8601String(),
      'invoiceAmount': invoiceAmount,
    };
  }
}

class CustomerEstimateHistory {
  final String estimateNumber;
  final DateTime estimateDate;
  final double estimateAmount;

  CustomerEstimateHistory({
    required this.estimateNumber,
    required this.estimateDate,
    required this.estimateAmount,
  });

  factory CustomerEstimateHistory.fromJson(Map<String, dynamic> json) {
    return CustomerEstimateHistory(
      estimateNumber: json['estimateNumber'] ?? '',
      estimateDate: json['estimateDate'] != null
          ? DateTime.tryParse(json['estimateDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      estimateAmount: (json['estimateAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimateNumber': estimateNumber,
      'estimateDate': estimateDate.toIso8601String(),
      'estimateAmount': estimateAmount,
    };
  }
}

class CustomerModel {
  final String? id;
  final String customerName;
  final String companyName;
  final String gstNumber;
  final String contactPerson;
  final String mobileNumber;
  final String email;
  final String address;
  final List<CustomerEstimateHistory> estimateHistory;
  final List<CustomerInvoiceHistory> invoiceHistory;
  
  // Filled in by detail API
  final List<EstimateModel> estimates;
  final List<TaxInvoiceModel> taxInvoices;

  CustomerModel({
    this.id,
    required this.customerName,
    required this.companyName,
    required this.gstNumber,
    required this.contactPerson,
    required this.mobileNumber,
    required this.email,
    required this.address,
    required this.estimateHistory,
    required this.invoiceHistory,
    this.estimates = const [],
    this.taxInvoices = const [],
  });

  int get totalInvoices => invoiceHistory.length;

  DateTime? get lastInvoiceDate {
    if (invoiceHistory.isEmpty) return null;
    return invoiceHistory
        .map((h) => h.invoiceDate)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  double get totalBusinessAmount {
    if (invoiceHistory.isEmpty) return 0.0;
    return invoiceHistory.map((h) => h.invoiceAmount).fold(0.0, (sum, amt) => sum + amt);
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    final invoiceHistoryRaw = json['invoiceHistory'] as List?;
    final invoiceHistoryList = invoiceHistoryRaw != null
        ? invoiceHistoryRaw.map((e) => CustomerInvoiceHistory.fromJson(e as Map<String, dynamic>)).toList()
        : <CustomerInvoiceHistory>[];

    final estimateHistoryRaw = json['estimateHistory'] as List?;
    final estimateHistoryList = estimateHistoryRaw != null
        ? estimateHistoryRaw.map((e) => CustomerEstimateHistory.fromJson(e as Map<String, dynamic>)).toList()
        : <CustomerEstimateHistory>[];

    final estimatesRaw = json['estimates'] as List?;
    final estimatesList = estimatesRaw != null
        ? estimatesRaw.map((e) => EstimateModel.fromJson(e as Map<String, dynamic>)).toList()
        : <EstimateModel>[];

    final taxInvoicesRaw = json['taxInvoices'] as List?;
    final taxInvoicesList = taxInvoicesRaw != null
        ? taxInvoicesRaw.map((e) => TaxInvoiceModel.fromJson(e as Map<String, dynamic>)).toList()
        : <TaxInvoiceModel>[];

    return CustomerModel(
      id: json['_id'] ?? json['id'],
      customerName: json['customerName'] ?? '',
      companyName: json['companyName'] ?? '',
      gstNumber: json['gstNumber'] ?? '',
      contactPerson: json['contactPerson'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      estimateHistory: estimateHistoryList,
      invoiceHistory: invoiceHistoryList,
      estimates: estimatesList,
      taxInvoices: taxInvoicesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'customerName': customerName,
      'companyName': companyName,
      'gstNumber': gstNumber,
      'contactPerson': contactPerson,
      'mobileNumber': mobileNumber,
      'email': email,
      'address': address,
      'estimateHistory': estimateHistory.map((e) => e.toJson()).toList(),
      'invoiceHistory': invoiceHistory.map((e) => e.toJson()).toList(),
    };
  }
}
