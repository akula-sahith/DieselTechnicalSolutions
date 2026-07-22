import 'dart:convert';

class EstimateCustomerDetails {
  final String customerName;
  final String address;
  final String? contactPerson;
  final String contactNumber;
  final String? gstinNumber;

  EstimateCustomerDetails({
    required this.customerName,
    required this.address,
    this.contactPerson,
    required this.contactNumber,
    this.gstinNumber,
  });

  factory EstimateCustomerDetails.fromJson(Map<String, dynamic> json) {
    return EstimateCustomerDetails(
      customerName: json['customerName'] ?? '',
      address: json['address'] ?? '',
      contactPerson: json['contactPerson'],
      contactNumber: json['contactNumber'] ?? '',
      gstinNumber: json['gstinNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'address': address,
      if (contactPerson != null) 'contactPerson': contactPerson,
      'contactNumber': contactNumber,
      if (gstinNumber != null) 'gstinNumber': gstinNumber,
    };
  }
}

class EstimateItem {
  final String itemName;
  final String? hsnSac;
  final double quantity;
  final double pricePerUnit;
  final bool taxApplicable;
  final double gstPercentage;
  final double? sgst;
  final double? cgst;
  final double? amount;

  EstimateItem({
    required this.itemName,
    this.hsnSac,
    required this.quantity,
    required this.pricePerUnit,
    this.taxApplicable = true,
    this.gstPercentage = 18.0,
    this.sgst,
    this.cgst,
    this.amount,
  });

  factory EstimateItem.fromJson(Map<String, dynamic> json) {
    return EstimateItem(
      itemName: json['itemName'] ?? '',
      hsnSac: json['hsnSac'],
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
      taxApplicable: json['taxApplicable'] ?? true,
      gstPercentage: (json['gstPercentage'] as num?)?.toDouble() ?? 18.0,
      sgst: (json['sgst'] as num?)?.toDouble(),
      cgst: (json['cgst'] as num?)?.toDouble(),
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      if (hsnSac != null) 'hsnSac': hsnSac,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'taxApplicable': taxApplicable,
      'gstPercentage': gstPercentage,
      if (sgst != null) 'sgst': sgst,
      if (cgst != null) 'cgst': cgst,
      if (amount != null) 'amount': amount,
    };
  }
}

class BankDetails {
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String upiId;
  final String? qrCodeUrl;
  final String? companyName;
  final String? gstNumber;

  BankDetails({
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.upiId,
    this.qrCodeUrl,
    this.companyName,
    this.gstNumber,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      bankName: json['bankName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
      upiId: json['upiId'] ?? '',
      qrCodeUrl: json['qrCodeUrl'],
      companyName: json['companyName'],
      gstNumber: json['gstNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'upiId': upiId,
      if (qrCodeUrl != null) 'qrCodeUrl': qrCodeUrl,
      if (companyName != null) 'companyName': companyName,
      if (gstNumber != null) 'gstNumber': gstNumber,
    };
  }
}

class EstimatePaymentData {
  final String? qrBase64;
  final String? clickToPayLink;
  final String? upiPaymentUri;
  final double? payableAmount;
  final String? companyUpiId;
  final String? companyName;

  EstimatePaymentData({
    this.qrBase64,
    this.clickToPayLink,
    this.upiPaymentUri,
    this.payableAmount,
    this.companyUpiId,
    this.companyName,
  });

  factory EstimatePaymentData.fromJson(Map<String, dynamic> json) {
    return EstimatePaymentData(
      qrBase64: json['qrBase64'],
      clickToPayLink: json['clickToPayLink'],
      upiPaymentUri: json['upiPaymentUri'],
      payableAmount: (json['payableAmount'] as num?)?.toDouble(),
      companyUpiId: json['companyUpiId'],
      companyName: json['companyName'],
    );
  }
}

class EstimateModel {
  final String? id;
  final String? estimateNumber;
  final DateTime estimateDate;
  final EstimateCustomerDetails estimateFor;
  final String? placeOfSupply;
  final List<EstimateItem> items;
  final BankDetails? bankDetails;
  final String? termsAndConditions;
  final double? subtotal;
  final double? totalTax;
  final double? totalAmount;
  final String? amountInWords;
  final String status;
  final String? technicianSignatureUrl;
  final String? customerSignatureUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Extra payment data returned by the backend endpoint alongside the document
  final EstimatePaymentData? paymentData;

  EstimateModel({
    this.id,
    this.estimateNumber,
    required this.estimateDate,
    required this.estimateFor,
    this.placeOfSupply,
    required this.items,
    this.bankDetails,
    this.termsAndConditions,
    this.subtotal,
    this.totalTax,
    this.totalAmount,
    this.amountInWords,
    this.status = 'draft',
    this.technicianSignatureUrl,
    this.customerSignatureUrl,
    this.createdAt,
    this.updatedAt,
    this.paymentData,
  });

  factory EstimateModel.fromJson(Map<String, dynamic> json) {
    final docJson = json['estimate'] ?? json; // Sometimes wrapped
    
    final itemsRaw = docJson['items'] as List?;
    final itemsList = itemsRaw != null
        ? itemsRaw.map((e) => EstimateItem.fromJson(e as Map<String, dynamic>)).toList()
        : <EstimateItem>[];

    EstimatePaymentData? paymentData;
    if (json.containsKey('payment') && json['payment'] != null) {
      paymentData = EstimatePaymentData.fromJson(json['payment']);
    }

    BankDetails? bankDetailsObj;
    if (docJson['bankDetails'] != null) {
      bankDetailsObj = BankDetails.fromJson(docJson['bankDetails']);
    } else if (json.containsKey('bankDetails') && json['bankDetails'] != null) {
      // In some responses, bank details might be adjacent to the document
      bankDetailsObj = BankDetails.fromJson(json['bankDetails']);
    }

    return EstimateModel(
      id: docJson['_id'] ?? docJson['id'],
      estimateNumber: docJson['estimateNumber'],
      estimateDate: docJson['estimateDate'] != null
          ? DateTime.tryParse(docJson['estimateDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      estimateFor: EstimateCustomerDetails.fromJson(docJson['estimateFor'] ?? {}),
      placeOfSupply: docJson['placeOfSupply'],
      items: itemsList,
      bankDetails: bankDetailsObj,
      termsAndConditions: docJson['termsAndConditions'],
      subtotal: (docJson['subtotal'] as num?)?.toDouble(),
      totalTax: (docJson['totalTax'] as num?)?.toDouble(),
      totalAmount: (docJson['totalAmount'] as num?)?.toDouble(),
      amountInWords: docJson['amountInWords'],
      status: docJson['status'] ?? 'draft',
      technicianSignatureUrl: docJson['technicianSignatureUrl'] ?? docJson['authorizedSignatureUrl'],
      customerSignatureUrl: docJson['customerSignatureUrl'],
      createdAt: docJson['createdAt'] != null
          ? DateTime.tryParse(docJson['createdAt'].toString())
          : null,
      updatedAt: docJson['updatedAt'] != null
          ? DateTime.tryParse(docJson['updatedAt'].toString())
          : null,
      paymentData: paymentData,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'estimateDate': estimateDate.toIso8601String(),
      'estimateFor': estimateFor.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
      'status': status,
    };

    if (id != null) map['id'] = id;
    if (estimateNumber != null) map['estimateNumber'] = estimateNumber;
    if (placeOfSupply != null) map['placeOfSupply'] = placeOfSupply;
    if (bankDetails != null) map['bankDetails'] = bankDetails!.toJson();
    if (termsAndConditions != null) map['termsAndConditions'] = termsAndConditions;
    if (technicianSignatureUrl != null) map['technicianSignatureUrl'] = technicianSignatureUrl;
    if (customerSignatureUrl != null) map['customerSignatureUrl'] = customerSignatureUrl;

    return map;
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}
