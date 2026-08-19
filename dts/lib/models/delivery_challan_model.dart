import 'dart:convert';

class DeliveryChallanCustomerDetails {
  final String customerName;
  final String address;
  final String? contactPerson;
  final String contactNumber;
  final String? gstinNumber;
  final String state;

  DeliveryChallanCustomerDetails({
    required this.customerName,
    required this.address,
    this.contactPerson,
    required this.contactNumber,
    this.gstinNumber,
    this.state = '36-Telangana',
  });

  factory DeliveryChallanCustomerDetails.fromJson(Map<String, dynamic> json) {
    return DeliveryChallanCustomerDetails(
      customerName: json['customerName'] ?? '',
      address: json['address'] ?? '',
      contactPerson: json['contactPerson'],
      contactNumber: json['contactNumber'] ?? '',
      gstinNumber: json['gstinNumber'],
      state: json['state'] ?? '36-Telangana',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'address': address,
      if (contactPerson != null) 'contactPerson': contactPerson,
      'contactNumber': contactNumber,
      if (gstinNumber != null) 'gstinNumber': gstinNumber,
      'state': state,
    };
  }
}

class DeliveryChallanTransportationDetails {
  final String? vehicleNumber;
  final DateTime? dispatchDate;
  final String? destinationLocation;
  final String? transportName;
  final String? lrNumber;

  DeliveryChallanTransportationDetails({
    this.vehicleNumber,
    this.dispatchDate,
    this.destinationLocation,
    this.transportName,
    this.lrNumber,
  });

  factory DeliveryChallanTransportationDetails.fromJson(Map<String, dynamic> json) {
    return DeliveryChallanTransportationDetails(
      vehicleNumber: json['vehicleNumber'],
      dispatchDate: json['dispatchDate'] != null
          ? DateTime.tryParse(json['dispatchDate'].toString())
          : null,
      destinationLocation: json['destinationLocation'],
      transportName: json['transportName'],
      lrNumber: json['lrNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
      if (dispatchDate != null) 'dispatchDate': dispatchDate!.toIso8601String(),
      if (destinationLocation != null) 'destinationLocation': destinationLocation,
      if (transportName != null) 'transportName': transportName,
      if (lrNumber != null) 'lrNumber': lrNumber,
    };
  }
}

class DeliveryChallanItem {
  final String itemName;
  final String? hsnSac;
  final double quantity;

  DeliveryChallanItem({
    required this.itemName,
    this.hsnSac,
    required this.quantity,
  });

  factory DeliveryChallanItem.fromJson(Map<String, dynamic> json) {
    return DeliveryChallanItem(
      itemName: json['itemName'] ?? '',
      hsnSac: json['hsnSac'],
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      if (hsnSac != null) 'hsnSac': hsnSac,
      'quantity': quantity,
    };
  }
}

class ChallanSignatory {
  final String? name;
  final String? comment;
  final DateTime? date;
  final String? signatureUrl;

  ChallanSignatory({
    this.name,
    this.comment,
    this.date,
    this.signatureUrl,
  });

  factory ChallanSignatory.fromJson(Map<String, dynamic> json) {
    return ChallanSignatory(
      name: json['name'],
      comment: json['comment'],
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      signatureUrl: json['signatureUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (comment != null) 'comment': comment,
      if (date != null) 'date': date!.toIso8601String(),
      if (signatureUrl != null) 'signatureUrl': signatureUrl,
    };
  }
}

class DeliveryChallanModel {
  final String? id;
  final String? challanNumber;
  final DateTime challanDate;
  final DeliveryChallanCustomerDetails deliveryChallanFor;
  final DeliveryChallanTransportationDetails transportationDetails;
  final String placeOfSupply;
  final List<DeliveryChallanItem> items;
  final double totalQuantity;
  final String? termsAndConditions;
  final ChallanSignatory? receivedBy;
  final ChallanSignatory? deliveredBy;
  final String? authorizedSignatureUrl;
  final String? pdfUrl;
  final String? linkedEstimateId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DeliveryChallanModel({
    this.id,
    this.challanNumber,
    required this.challanDate,
    required this.deliveryChallanFor,
    required this.transportationDetails,
    this.placeOfSupply = '36-Telangana',
    required this.items,
    this.totalQuantity = 0.0,
    this.termsAndConditions,
    this.receivedBy,
    this.deliveredBy,
    this.authorizedSignatureUrl,
    this.pdfUrl,
    this.linkedEstimateId,
    this.status = 'issued',
    this.createdAt,
    this.updatedAt,
  });

  factory DeliveryChallanModel.fromJson(Map<String, dynamic> json) {
    final docJson = json['deliveryChallan'] ?? json;

    final itemsRaw = docJson['items'] as List?;
    final itemsList = itemsRaw != null
        ? itemsRaw.map((e) => DeliveryChallanItem.fromJson(e as Map<String, dynamic>)).toList()
        : <DeliveryChallanItem>[];

    return DeliveryChallanModel(
      id: docJson['_id'] ?? docJson['id'],
      challanNumber: docJson['challanNumber'],
      challanDate: docJson['challanDate'] != null
          ? DateTime.tryParse(docJson['challanDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      deliveryChallanFor:
          DeliveryChallanCustomerDetails.fromJson(docJson['deliveryChallanFor'] ?? {}),
      transportationDetails: DeliveryChallanTransportationDetails.fromJson(
          docJson['transportationDetails'] ?? {}),
      placeOfSupply: docJson['placeOfSupply'] ?? '36-Telangana',
      items: itemsList,
      totalQuantity: (docJson['totalQuantity'] as num?)?.toDouble() ??
          itemsList.fold<double>(0, (p, e) => p + e.quantity),
      termsAndConditions: docJson['termsAndConditions'],
      receivedBy: docJson['receivedBy'] != null
          ? ChallanSignatory.fromJson(docJson['receivedBy'])
          : null,
      deliveredBy: docJson['deliveredBy'] != null
          ? ChallanSignatory.fromJson(docJson['deliveredBy'])
          : null,
      authorizedSignatureUrl: docJson['authorizedSignatureUrl'],
      pdfUrl: docJson['pdfUrl'],
      linkedEstimateId: docJson['linkedEstimateId'],
      status: docJson['status'] ?? 'issued',
      createdAt: docJson['createdAt'] != null
          ? DateTime.tryParse(docJson['createdAt'].toString())
          : null,
      updatedAt: docJson['updatedAt'] != null
          ? DateTime.tryParse(docJson['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'challanDate': challanDate.toIso8601String(),
      'deliveryChallanFor': deliveryChallanFor.toJson(),
      'transportationDetails': transportationDetails.toJson(),
      'placeOfSupply': placeOfSupply,
      'items': items.map((e) => e.toJson()).toList(),
      'status': status,
    };

    if (id != null) map['id'] = id;
    if (challanNumber != null) map['challanNumber'] = challanNumber;
    if (termsAndConditions != null) map['termsAndConditions'] = termsAndConditions;
    if (receivedBy != null) map['receivedBy'] = receivedBy!.toJson();
    if (deliveredBy != null) map['deliveredBy'] = deliveredBy!.toJson();
    if (authorizedSignatureUrl != null) map['authorizedSignatureUrl'] = authorizedSignatureUrl;
    if (linkedEstimateId != null) map['linkedEstimateId'] = linkedEstimateId;

    return map;
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}
