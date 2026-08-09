import 'dart:convert';

class PurchaseBillModel {
  final String? id;
  final String? billNumber;
  final String vendorName;
  final DateTime billDate;
  final double amount;
  final double taxAmount;
  final String attachmentUrl;
  final String? remarks;
  final String status; // "pending" | "paid"
  final DateTime? createdAt;

  PurchaseBillModel({
    this.id,
    this.billNumber,
    required this.vendorName,
    required this.billDate,
    required this.amount,
    this.taxAmount = 0.0,
    required this.attachmentUrl,
    this.remarks,
    this.status = 'pending',
    this.createdAt,
  });

  factory PurchaseBillModel.fromJson(Map<String, dynamic> json) {
    return PurchaseBillModel(
      id: json['_id'] ?? json['id'],
      billNumber: json['billNumber'],
      vendorName: json['vendorName'] ?? '',
      billDate: json['billDate'] != null 
          ? DateTime.tryParse(json['billDate'].toString()) ?? DateTime.now() 
          : DateTime.now(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      attachmentUrl: json['attachmentUrl'] ?? '',
      remarks: json['remarks'],
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'billNumber': billNumber,
      'vendorName': vendorName,
      'billDate': billDate.toIso8601String(),
      'amount': amount,
      'taxAmount': taxAmount,
      'attachmentUrl': attachmentUrl,
      'remarks': remarks,
      'status': status,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}
