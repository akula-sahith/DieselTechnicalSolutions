import 'dart:convert';
import 'estimate_model.dart';
import 'tax_invoice_model.dart';

class BillingItem {
  final String itemName;
  final String? hsnSac;
  final double quantity;
  final double pricePerUnit;
  final double? amount;

  BillingItem({
    required this.itemName,
    this.hsnSac,
    required this.quantity,
    required this.pricePerUnit,
    this.amount,
  });

  factory BillingItem.fromJson(Map<String, dynamic> json) {
    return BillingItem(
      itemName: json['itemName'] ?? '',
      hsnSac: json['hsnSac'],
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      if (hsnSac != null) 'hsnSac': hsnSac,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      if (amount != null) 'amount': amount,
    };
  }
}

class BillingInvoiceModel {
  final String? id;
  final String? invoiceNumber;
  final DateTime invoiceDate;
  final EstimateCustomerDetails billTo;
  final String? placeOfSupply;
  final TransportationDetails? transportationDetails;
  final List<BillingItem> items;
  final String? termsAndConditions;
  final double? totalAmount;
  final String? amountInWords;
  final String? linkedEstimateId;
  final String? technicianSignatureUrl;
  final String? customerSignatureUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  final EstimatePaymentData? paymentData;
  final BankDetails? companyBankDetails;

  BillingInvoiceModel({
    this.id,
    this.invoiceNumber,
    required this.invoiceDate,
    required this.billTo,
    this.placeOfSupply,
    this.transportationDetails,
    required this.items,
    this.termsAndConditions,
    this.totalAmount,
    this.amountInWords,
    this.linkedEstimateId,
    this.technicianSignatureUrl,
    this.customerSignatureUrl,
    this.createdAt,
    this.updatedAt,
    this.paymentData,
    this.companyBankDetails,
  });

  factory BillingInvoiceModel.fromJson(Map<String, dynamic> json) {
    final docJson = json['billingInvoice'] ?? json;
    
    final itemsRaw = docJson['items'] as List?;
    final itemsList = itemsRaw != null
        ? itemsRaw.map((e) => BillingItem.fromJson(e as Map<String, dynamic>)).toList()
        : <BillingItem>[];

    EstimatePaymentData? paymentData;
    if (json.containsKey('payment') && json['payment'] != null) {
      paymentData = EstimatePaymentData.fromJson(json['payment']);
    }

    BankDetails? companyBankDetailsObj;
    if (json.containsKey('bankDetails') && json['bankDetails'] != null) {
      companyBankDetailsObj = BankDetails.fromJson(json['bankDetails']);
    }

    return BillingInvoiceModel(
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
      totalAmount: (docJson['totalAmount'] as num?)?.toDouble(),
      amountInWords: docJson['amountInWords'],
      linkedEstimateId: docJson['linkedEstimateId'] is Map
          ? (docJson['linkedEstimateId']['_id'] ?? docJson['linkedEstimateId']['id'])?.toString()
          : docJson['linkedEstimateId']?.toString(),
      technicianSignatureUrl: docJson['technicianSignatureUrl'] ?? docJson['authorizedSignatureUrl'],
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
    if (linkedEstimateId != null) map['linkedEstimateId'] = linkedEstimateId;
    if (technicianSignatureUrl != null) map['technicianSignatureUrl'] = technicianSignatureUrl;
    if (customerSignatureUrl != null) map['customerSignatureUrl'] = customerSignatureUrl;

    return map;
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}
