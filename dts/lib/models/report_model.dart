import 'dart:convert';

class ServiceChecklistItem {
  final String parameter;
  final String status; // 'ok', 'req', 'n/a'

  ServiceChecklistItem({
    required this.parameter,
    required this.status,
  });

  factory ServiceChecklistItem.fromJson(Map<String, dynamic> json) {
    return ServiceChecklistItem(
      parameter: json['parameter'] ?? '',
      status: json['status'] ?? 'ok',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parameter': parameter,
      'status': status,
    };
  }
}

class PartsUsedItem {
  final String partDescription;
  final String qty;

  PartsUsedItem({
    required this.partDescription,
    required this.qty,
  });

  factory PartsUsedItem.fromJson(Map<String, dynamic> json) {
    return PartsUsedItem(
      partDescription: json['partDescription'] ?? '',
      qty: json['qty'] ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partDescription': partDescription,
      'qty': qty,
    };
  }
}

class ServiceAndCustomer {
  final String jobRef;
  final DateTime dateTime;
  final String customerName;
  final String siteLocation;
  final String contactPerson;
  final String contactNumber;

  ServiceAndCustomer({
    required this.jobRef,
    required this.dateTime,
    required this.customerName,
    required this.siteLocation,
    required this.contactPerson,
    required this.contactNumber,
  });

  factory ServiceAndCustomer.fromJson(Map<String, dynamic> json) {
    return ServiceAndCustomer(
      jobRef: json['jobRef'] ?? '',
      dateTime: json['dateTime'] != null 
          ? DateTime.tryParse(json['dateTime'].toString()) ?? DateTime.now() 
          : DateTime.now(),
      customerName: json['customerName'] ?? '',
      siteLocation: json['siteLocation'] ?? '',
      contactPerson: json['contactPerson'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobRef': jobRef,
      'dateTime': dateTime.toIso8601String(),
      'customerName': customerName,
      'siteLocation': siteLocation,
      'contactPerson': contactPerson,
      'contactNumber': contactNumber,
    };
  }
}

class EquipmentAndEngine {
  final String generatorMakeModel;
  final String capacity;
  final String engineSerialNo;
  final String alternatorSerialNo;
  final String hourMeter;
  final int? hours;
  final String batteryStatusVolt;

  EquipmentAndEngine({
    required this.generatorMakeModel,
    required this.capacity,
    required this.engineSerialNo,
    required this.alternatorSerialNo,
    required this.hourMeter,
    this.hours,
    required this.batteryStatusVolt,
  });

  factory EquipmentAndEngine.fromJson(Map<String, dynamic> json) {
    return EquipmentAndEngine(
      generatorMakeModel: json['generatorMakeModel'] ?? '',
      capacity: json['capacity'] ?? '',
      engineSerialNo: json['engineSerialNo'] ?? '',
      alternatorSerialNo: json['alternatorSerialNo'] ?? '',
      hourMeter: json['hourMeter'] ?? '',
      hours: json['hours'] != null ? int.tryParse(json['hours'].toString()) : null,
      batteryStatusVolt: json['batteryStatusVolt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'generatorMakeModel': generatorMakeModel,
      'capacity': capacity,
      'engineSerialNo': engineSerialNo,
      'alternatorSerialNo': alternatorSerialNo,
      'hourMeter': hourMeter,
      'hours': hours,
      'batteryStatusVolt': batteryStatusVolt,
    };
  }
}

class RemarksAndActionPlan {
  final String observations;
  final DateTime? nextServiceDueDate;
  final int? nextServiceDueHours;

  RemarksAndActionPlan({
    required this.observations,
    this.nextServiceDueDate,
    this.nextServiceDueHours,
  });

  factory RemarksAndActionPlan.fromJson(Map<String, dynamic> json) {
    return RemarksAndActionPlan(
      observations: json['observations'] ?? '',
      nextServiceDueDate: json['nextServiceDueDate'] != null 
          ? DateTime.tryParse(json['nextServiceDueDate'].toString()) 
          : null,
      nextServiceDueHours: json['nextServiceDueHours'] != null 
          ? int.tryParse(json['nextServiceDueHours'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'observations': observations,
      'nextServiceDueDate': nextServiceDueDate?.toIso8601String(),
      'nextServiceDueHours': nextServiceDueHours,
    };
  }
}

class Authorization {
  final String technicianName;
  final String technicianSignatureUrl;
  final String customerRepresentativeName;
  final String customerPhotoUrl;
  final DateTime? technicianDate;
  final DateTime? customerDate;

  Authorization({
    required this.technicianName,
    required this.technicianSignatureUrl,
    required this.customerRepresentativeName,
    required this.customerPhotoUrl,
    this.technicianDate,
    this.customerDate,
  });

  factory Authorization.fromJson(Map<String, dynamic> json) {
    return Authorization(
      technicianName: json['technicianName'] ?? '',
      technicianSignatureUrl: json['technicianSignatureUrl'] ?? '',
      customerRepresentativeName: json['customerRepresentativeName'] ?? '',
      customerPhotoUrl: json['customerPhotoUrl'] ?? '',
      technicianDate: json['technicianDate'] != null 
          ? DateTime.tryParse(json['technicianDate'].toString()) 
          : null,
      customerDate: json['customerDate'] != null 
          ? DateTime.tryParse(json['customerDate'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'technicianName': technicianName,
      'technicianSignatureUrl': technicianSignatureUrl,
      'customerRepresentativeName': customerRepresentativeName,
      'customerPhotoUrl': customerPhotoUrl,
      'technicianDate': technicianDate?.toIso8601String(),
      'customerDate': customerDate?.toIso8601String(),
    };
  }
}

class ReportModel {
  final String? id;
  final ServiceAndCustomer serviceAndCustomer;
  final EquipmentAndEngine equipmentAndEngine;
  final List<ServiceChecklistItem> serviceChecklist;
  final List<PartsUsedItem> partsUsed;
  final RemarksAndActionPlan remarksAndActionPlan;
  final Authorization authorization;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReportModel({
    this.id,
    required this.serviceAndCustomer,
    required this.equipmentAndEngine,
    required this.serviceChecklist,
    required this.partsUsed,
    required this.remarksAndActionPlan,
    required this.authorization,
    this.createdAt,
    this.updatedAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    // Check if the structure is nested or flat
    final hasNestedCustomer = json.containsKey('serviceAndCustomer');
    
    final customerData = hasNestedCustomer 
        ? json['serviceAndCustomer'] as Map<String, dynamic>
        : json;
    
    final equipmentData = hasNestedCustomer
        ? json['equipmentAndEngine'] as Map<String, dynamic>
        : json;

    final remarksData = hasNestedCustomer
        ? json['remarksAndActionPlan'] as Map<String, dynamic>
        : json;

    final authData = hasNestedCustomer
        ? json['authorization'] as Map<String, dynamic>
        : json;

    final checklistRaw = json['serviceChecklist'] as List?;
    final checklist = checklistRaw != null
        ? checklistRaw.map((e) => ServiceChecklistItem.fromJson(e as Map<String, dynamic>)).toList()
        : <ServiceChecklistItem>[];

    final partsRaw = json['partsUsed'] as List?;
    final parts = partsRaw != null
        ? partsRaw.map((e) => PartsUsedItem.fromJson(e as Map<String, dynamic>)).toList()
        : <PartsUsedItem>[];

    return ReportModel(
      id: json['_id'] ?? json['id'],
      serviceAndCustomer: ServiceAndCustomer.fromJson(customerData),
      equipmentAndEngine: EquipmentAndEngine.fromJson(equipmentData),
      serviceChecklist: checklist,
      partsUsed: parts,
      remarksAndActionPlan: RemarksAndActionPlan.fromJson(remarksData),
      authorization: Authorization.fromJson(authData),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  // Serializes to the flat format expected by the create report API or a nested format
  Map<String, dynamic> toJson({bool flat = true}) {
    if (flat) {
      final map = <String, dynamic>{};
      map.addAll(serviceAndCustomer.toJson());
      map.addAll(equipmentAndEngine.toJson());
      map.addAll(remarksAndActionPlan.toJson());
      map.addAll(authorization.toJson());
      map['serviceChecklist'] = serviceChecklist.map((e) => e.toJson()).toList();
      map['partsUsed'] = partsUsed.map((e) => e.toJson()).toList();
      return map;
    } else {
      return {
        'id': id,
        'serviceAndCustomer': serviceAndCustomer.toJson(),
        'equipmentAndEngine': equipmentAndEngine.toJson(),
        'serviceChecklist': serviceChecklist.map((e) => e.toJson()).toList(),
        'partsUsed': partsUsed.map((e) => e.toJson()).toList(),
        'remarksAndActionPlan': remarksAndActionPlan.toJson(),
        'authorization': authorization.toJson(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
    }
  }

  String toJsonString() {
    return jsonEncode(toJson(flat: true));
  }
}
