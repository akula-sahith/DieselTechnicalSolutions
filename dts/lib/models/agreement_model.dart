import 'dart:convert';

class DescriptionItem {
  final String description;
  final double quantity;
  final double rate;
  final double subTotal;

  DescriptionItem({
    required this.description,
    required this.quantity,
    required this.rate,
    required this.subTotal,
  });

  factory DescriptionItem.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num?)?.toDouble() ?? 0.0;
    final r = (json['rate'] as num?)?.toDouble() ?? 0.0;
    return DescriptionItem(
      description: json['description'] ?? '',
      quantity: qty,
      rate: r,
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? (qty * r),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'rate': rate,
      'subTotal': subTotal,
    };
  }
}

class AgreementModel {
  final String? id;
  final String documentType; // 'Agreement' or 'Quotation'
  final String? offerNumber;
  final DateTime date;
  final String customerName;
  final String completeAddress;
  final String contactPerson;
  final String mobileNumber;
  final List<DescriptionItem> descriptionItems;
  final bool gstRequired;
  final double gstPercentage;
  final double totalBeforeGST;
  final double gstAmount;
  final double grandTotal;
  final String? amountInWords;
  final String technicianSignatureUrl;
  final String? customerSignatureUrl;
  final String? termsAndConditions;
  final String? paymentTerms;
  final String? offerValidity;
  final String? notes;
  final String? footerText;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AgreementModel({
    this.id,
    required this.documentType,
    this.offerNumber,
    required this.date,
    required this.customerName,
    required this.completeAddress,
    required this.contactPerson,
    required this.mobileNumber,
    required this.descriptionItems,
    required this.gstRequired,
    required this.gstPercentage,
    required this.totalBeforeGST,
    required this.gstAmount,
    required this.grandTotal,
    this.amountInWords,
    required this.technicianSignatureUrl,
    this.customerSignatureUrl,
    this.termsAndConditions,
    this.paymentTerms,
    this.offerValidity,
    this.notes,
    this.footerText,
    this.createdAt,
    this.updatedAt,
  });

  factory AgreementModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['descriptionItems'] as List?;
    final items = itemsRaw != null
        ? itemsRaw.map((e) => DescriptionItem.fromJson(e as Map<String, dynamic>)).toList()
        : <DescriptionItem>[];

    return AgreementModel(
      id: json['_id'] ?? json['id'],
      documentType: json['documentType'] ?? 'Agreement',
      offerNumber: json['offerNumber'],
      date: json['date'] != null 
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() 
          : DateTime.now(),
      customerName: json['customerName'] ?? '',
      completeAddress: json['completeAddress'] ?? '',
      contactPerson: json['contactPerson'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      descriptionItems: items,
      gstRequired: json['gstRequired'] == true || json['gstRequired'] == 'true',
      gstPercentage: (json['gstPercentage'] as num?)?.toDouble() ?? 0.0,
      totalBeforeGST: (json['totalBeforeGST'] as num?)?.toDouble() ?? 0.0,
      gstAmount: (json['gstAmount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      amountInWords: json['amountInWords'],
      technicianSignatureUrl: json['technicianSignatureUrl'] ?? '',
      customerSignatureUrl: json['customerSignatureUrl'],
      termsAndConditions: json['termsAndConditions'],
      paymentTerms: json['paymentTerms'],
      offerValidity: json['offerValidity'],
      notes: json['notes'],
      footerText: json['footerText'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson({bool flat = false}) {
    final map = <String, dynamic>{
      'documentType': documentType,
      'date': date.toIso8601String(),
      'customerName': customerName,
      'completeAddress': completeAddress,
      'contactPerson': contactPerson,
      'mobileNumber': mobileNumber,
      'descriptionItems': descriptionItems.map((e) => e.toJson()).toList(),
      'gstRequired': gstRequired,
      'gstPercentage': gstPercentage,
      'totalBeforeGST': totalBeforeGST,
      'gstAmount': gstAmount,
      'grandTotal': grandTotal,
      'technicianSignatureUrl': technicianSignatureUrl,
    };

    if (customerSignatureUrl != null) {
      map['customerSignatureUrl'] = customerSignatureUrl;
    }
    if (termsAndConditions != null) {
      map['termsAndConditions'] = termsAndConditions;
    }
    if (paymentTerms != null) {
      map['paymentTerms'] = paymentTerms;
    }
    if (offerValidity != null) {
      map['offerValidity'] = offerValidity;
    }
    if (notes != null) {
      map['notes'] = notes;
    }
    if (footerText != null) {
      map['footerText'] = footerText;
    }
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}
