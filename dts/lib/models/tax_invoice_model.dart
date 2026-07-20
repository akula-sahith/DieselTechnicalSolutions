import 'dart:convert';
import 'estimate_model.dart'; // To reuse EstimateCustomerDetails and EstimateItem

class TransportationDetails {
  final String? vehicleNumber;
  final String? transportName;
  final String? lrNumber;
  final String? dispatchDetails;
  final String? deliveryDetails;

  TransportationDetails({
    this.vehicleNumber,
    this.transportName,
    this.lrNumber,
    this.dispatchDetails,
    this.deliveryDetails,
  });

  factory TransportationDetails.fromJson(Map<String, dynamic> json) {
    return TransportationDetails(
      vehicleNumber: json['vehicleNumber'],
      transportName: json['transportName'],
      lrNumber: json['lrNumber'],
      dispatchDetails: json['dispatchDetails'],
      deliveryDetails: json['deliveryDetails'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
      if (transportName != null) 'transportName': transportName,
      if (lrNumber != null) 'lrNumber': lrNumber,
      if (dispatchDetails != null) 'dispatchDetails': dispatchDetails,
      if (deliveryDetails != null) 'deliveryDetails': deliveryDetails,
    };
  }
}

class InvoicePaymentHistory {
  final double amountReceived;
  final DateTime paymentDate;
  final String? paymentMethod;
  final String? referenceNumber;

  InvoicePaymentHistory({
    required this.amountReceived,
    required this.paymentDate,
    this.paymentMethod,
    this.referenceNumber,
  });

  factory InvoicePaymentHistory.fromJson(Map<String, dynamic> json) {
    return InvoicePaymentHistory(
      amountReceived: (json['amountReceived'] as num?)?.toDouble() ?? 0.0,
      paymentDate: json['paymentDate'] != null 
          ? DateTime.tryParse(json['paymentDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      paymentMethod: json['paymentMethod'],
      referenceNumber: json['referenceNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amountReceived': amountReceived,
      'paymentDate': paymentDate.toIso8601String(),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (referenceNumber != null) 'referenceNumber': referenceNumber,
    };
  }
}

class InvoicePaymentDetails {
  final double? totalAmount;
  final double? advanceAmountReceived;
  final double? remainingAmount;
  final String status; // "Unpaid" | "Partially Paid" | "Paid"
  final List<InvoicePaymentHistory> paymentHistory;

  InvoicePaymentDetails({
    this.totalAmount,
    this.advanceAmountReceived,
    this.remainingAmount,
    this.status = 'Unpaid',
    this.paymentHistory = const [],
  });

  factory InvoicePaymentDetails.fromJson(Map<String, dynamic> json) {
    final historyRaw = json['paymentHistory'] as List?;
    final historyList = historyRaw != null 
        ? historyRaw.map((e) => InvoicePaymentHistory.fromJson(e as Map<String, dynamic>)).toList()
        : <InvoicePaymentHistory>[];

    return InvoicePaymentDetails(
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      advanceAmountReceived: (json['advanceAmountReceived'] as num?)?.toDouble(),
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble(),
      status: json['status'] ?? 'Unpaid',
      paymentHistory: historyList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'paymentHistory': paymentHistory.map((e) => e.toJson()).toList(),
      if (totalAmount != null) 'totalAmount': totalAmount,
      if (advanceAmountReceived != null) 'advanceAmountReceived': advanceAmountReceived,
      if (remainingAmount != null) 'remainingAmount': remainingAmount,
    };
  }
}

class TaxInvoiceModel {
  final String? id;
  final String? invoiceNumber;
  final DateTime invoiceDate;
  final EstimateCustomerDetails billTo;
  final String? placeOfSupply;
  final TransportationDetails? transportationDetails;
  final List<EstimateItem> items;
  final String? termsAndConditions;
  final double? subtotal;
  final double? totalTax;
  final double? totalAmount;
  final String? amountInWords;
  final InvoicePaymentDetails? paymentDetails;
  final String? linkedEstimateId;
  final String? technicianSignatureUrl;
  final String? customerSignatureUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Extra payment data returned by the backend endpoint alongside the document
  final EstimatePaymentData? paymentData;
  final BankDetails? companyBankDetails; // The company config returned by backend

  TaxInvoiceModel({
    this.id,
    this.invoiceNumber,
    required this.invoiceDate,
    required this.billTo,
    this.placeOfSupply,
    this.transportationDetails,
    required this.items,
    this.termsAndConditions,
    this.subtotal,
    this.totalTax,
    this.totalAmount,
    this.amountInWords,
    this.paymentDetails,
    this.linkedEstimateId,
    this.technicianSignatureUrl,
    this.customerSignatureUrl,
    this.createdAt,
    this.updatedAt,
    this.paymentData,
    this.companyBankDetails,
  });

  factory TaxInvoiceModel.fromJson(Map<String, dynamic> json) {
    final docJson = json['taxInvoice'] ?? json; // Sometimes wrapped
    
    final itemsRaw = docJson['items'] as List?;
    final itemsList = itemsRaw != null
        ? itemsRaw.map((e) => EstimateItem.fromJson(e as Map<String, dynamic>)).toList()
        : <EstimateItem>[];

    EstimatePaymentData? paymentData;
    if (json.containsKey('payment') && json['payment'] != null) {
      paymentData = EstimatePaymentData.fromJson(json['payment']);
    }

    BankDetails? companyBankDetailsObj;
    if (json.containsKey('bankDetails') && json['bankDetails'] != null) {
      companyBankDetailsObj = BankDetails.fromJson(json['bankDetails']);
    }

    return TaxInvoiceModel(
      id: docJson['_id'] ?? docJson['id'],
      invoiceNumber: docJson['invoiceNumber'],
      invoiceDate: docJson['invoiceDate'] != null
          ? DateTime.tryParse(docJson['invoiceDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      billTo: EstimateCustomerDetails.fromJson(docJson['billTo'] ?? {}),
      placeOfSupply: docJson['placeOfSupply'],
      transportationDetails: docJson['transportationDetails'] != null 
          ? TransportationDetails.fromJson(docJson['transportationDetails']) 
          : null,
      items: itemsList,
      termsAndConditions: docJson['termsAndConditions'],
      subtotal: (docJson['subtotal'] as num?)?.toDouble(),
      totalTax: (docJson['totalTax'] as num?)?.toDouble(),
      totalAmount: (docJson['totalAmount'] as num?)?.toDouble(),
      amountInWords: docJson['amountInWords'],
      paymentDetails: docJson['paymentDetails'] != null
          ? InvoicePaymentDetails.fromJson(docJson['paymentDetails'])
          : null,
      linkedEstimateId: docJson['linkedEstimateId'],
      technicianSignatureUrl: docJson['technicianSignatureUrl'],
      customerSignatureUrl: docJson['customerSignatureUrl'],
      createdAt: docJson['createdAt'] != null
          ? DateTime.tryParse(docJson['createdAt'].toString())
          : null,
      updatedAt: docJson['updatedAt'] != null
          ? DateTime.tryParse(docJson['updatedAt'].toString())
          : null,
      paymentData: paymentData,
      companyBankDetails: companyBankDetailsObj,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'invoiceDate': invoiceDate.toIso8601String(),
      'billTo': billTo.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
    };

    if (id != null) map['id'] = id;
    if (invoiceNumber != null) map['invoiceNumber'] = invoiceNumber;
    if (placeOfSupply != null) map['placeOfSupply'] = placeOfSupply;
    if (transportationDetails != null) map['transportationDetails'] = transportationDetails!.toJson();
    if (termsAndConditions != null) map['termsAndConditions'] = termsAndConditions;
    if (paymentDetails != null) map['paymentDetails'] = paymentDetails!.toJson();
    if (linkedEstimateId != null) map['linkedEstimateId'] = linkedEstimateId;
    if (technicianSignatureUrl != null) map['technicianSignatureUrl'] = technicianSignatureUrl;
    if (customerSignatureUrl != null) map['customerSignatureUrl'] = customerSignatureUrl;

    return map;
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}
