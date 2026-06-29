import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/report_model.dart';
import '../repositories/report_repository.dart';
import 'auth_provider.dart';
import 'reports_provider.dart';

class ReportWizardState {
  final int currentStep;
  
  // Step 1
  final String jobRef;
  final DateTime dateTime;
  final String customerName;
  final String siteLocation;
  final String contactPerson;
  final String contactNumber;

  // Step 2
  final String generatorMakeModel;
  final String capacity;
  final String engineSerialNo;
  final String alternatorSerialNo;
  final String hourMeter;
  final int? hours;
  final String batteryStatusVolt;

  // Step 3
  final List<ServiceChecklistItem> serviceChecklist;

  // Step 4
  final List<PartsUsedItem> partsUsed;

  // Step 5
  final String observations;
  final DateTime? nextServiceDueDate;
  final int? nextServiceDueHours;

  // Step 6
  final String technicianName;
  final String customerRepresentativeName;
  final File? technicianSignatureFile;
  final File? customerPhotoFile;
  final DateTime technicianDate;
  final DateTime customerDate;

  // Statuses
  final bool isSubmitting;
  final String? error;
  final ReportModel? submittedReport;

  ReportWizardState({
    required this.currentStep,
    required this.jobRef,
    required this.dateTime,
    required this.customerName,
    required this.siteLocation,
    required this.contactPerson,
    required this.contactNumber,
    required this.generatorMakeModel,
    required this.capacity,
    required this.engineSerialNo,
    required this.alternatorSerialNo,
    required this.hourMeter,
    this.hours,
    required this.batteryStatusVolt,
    required this.serviceChecklist,
    required this.partsUsed,
    required this.observations,
    this.nextServiceDueDate,
    this.nextServiceDueHours,
    required this.technicianName,
    required this.customerRepresentativeName,
    this.technicianSignatureFile,
    this.customerPhotoFile,
    required this.technicianDate,
    required this.customerDate,
    required this.isSubmitting,
    this.error,
    this.submittedReport,
  });

  factory ReportWizardState.initial(String defaultTechName) {
    // Generate a default ticket reference like DTS-2026-01234
    final now = DateTime.now();
    final randomDigits = Random().nextInt(90000) + 10000;
    final defaultJobRef = 'DTS-${now.year}-$randomDigits';

    final defaultChecklist = [
      'Engine Oil Level & Quality',
      'Coolant Level & Protection',
      'Water Separator Draining',
      'Exhaust / Silencer Leakage',
      'Fuel Filter Replacement',
      'Radiator Fins & Core Check',
      'Battery Terminals & Charging',
      'AVM (Anti-Vibration Mounts)',
    ].map((param) => ServiceChecklistItem(parameter: param, status: 'ok')).toList();

    return ReportWizardState(
      currentStep: 0,
      jobRef: defaultJobRef,
      dateTime: now,
      customerName: '',
      siteLocation: '',
      contactPerson: '',
      contactNumber: '',
      generatorMakeModel: '',
      capacity: '',
      engineSerialNo: '',
      alternatorSerialNo: '',
      hourMeter: '',
      hours: null,
      batteryStatusVolt: '',
      serviceChecklist: defaultChecklist,
      partsUsed: [],
      observations: '',
      nextServiceDueDate: null,
      nextServiceDueHours: null,
      technicianName: defaultTechName,
      customerRepresentativeName: '',
      technicianSignatureFile: null,
      customerPhotoFile: null,
      technicianDate: now,
      customerDate: now,
      isSubmitting: false,
    );
  }

  ReportWizardState copyWith({
    int? currentStep,
    String? jobRef,
    DateTime? dateTime,
    String? customerName,
    String? siteLocation,
    String? contactPerson,
    String? contactNumber,
    String? generatorMakeModel,
    String? capacity,
    String? engineSerialNo,
    String? alternatorSerialNo,
    String? hourMeter,
    int? hours,
    String? batteryStatusVolt,
    List<ServiceChecklistItem>? serviceChecklist,
    List<PartsUsedItem>? partsUsed,
    String? observations,
    DateTime? nextServiceDueDate,
    int? nextServiceDueHours,
    String? technicianName,
    String? customerRepresentativeName,
    File? technicianSignatureFile,
    File? customerPhotoFile,
    DateTime? technicianDate,
    DateTime? customerDate,
    bool? isSubmitting,
    String? error,
    ReportModel? submittedReport,
  }) {
    return ReportWizardState(
      currentStep: currentStep ?? this.currentStep,
      jobRef: jobRef ?? this.jobRef,
      dateTime: dateTime ?? this.dateTime,
      customerName: customerName ?? this.customerName,
      siteLocation: siteLocation ?? this.siteLocation,
      contactPerson: contactPerson ?? this.contactPerson,
      contactNumber: contactNumber ?? this.contactNumber,
      generatorMakeModel: generatorMakeModel ?? this.generatorMakeModel,
      capacity: capacity ?? this.capacity,
      engineSerialNo: engineSerialNo ?? this.engineSerialNo,
      alternatorSerialNo: alternatorSerialNo ?? this.alternatorSerialNo,
      hourMeter: hourMeter ?? this.hourMeter,
      hours: hours ?? this.hours,
      batteryStatusVolt: batteryStatusVolt ?? this.batteryStatusVolt,
      serviceChecklist: serviceChecklist ?? this.serviceChecklist,
      partsUsed: partsUsed ?? this.partsUsed,
      observations: observations ?? this.observations,
      nextServiceDueDate: nextServiceDueDate ?? this.nextServiceDueDate,
      nextServiceDueHours: nextServiceDueHours ?? this.nextServiceDueHours,
      technicianName: technicianName ?? this.technicianName,
      customerRepresentativeName: customerRepresentativeName ?? this.customerRepresentativeName,
      technicianSignatureFile: technicianSignatureFile ?? this.technicianSignatureFile,
      customerPhotoFile: customerPhotoFile ?? this.customerPhotoFile,
      technicianDate: technicianDate ?? this.technicianDate,
      customerDate: customerDate ?? this.customerDate,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      submittedReport: submittedReport ?? this.submittedReport,
    );
  }

  ReportModel toReportModel({String signatureUrl = '', String photoUrl = ''}) {
    return ReportModel(
      serviceAndCustomer: ServiceAndCustomer(
        jobRef: jobRef,
        dateTime: dateTime,
        customerName: customerName,
        siteLocation: siteLocation,
        contactPerson: contactPerson,
        contactNumber: contactNumber,
      ),
      equipmentAndEngine: EquipmentAndEngine(
        generatorMakeModel: generatorMakeModel,
        capacity: capacity,
        engineSerialNo: engineSerialNo,
        alternatorSerialNo: alternatorSerialNo,
        hourMeter: hourMeter,
        hours: hours,
        batteryStatusVolt: batteryStatusVolt,
      ),
      serviceChecklist: serviceChecklist,
      partsUsed: partsUsed,
      remarksAndActionPlan: RemarksAndActionPlan(
        observations: observations,
        nextServiceDueDate: nextServiceDueDate,
        nextServiceDueHours: nextServiceDueHours,
      ),
      authorization: Authorization(
        technicianName: technicianName,
        technicianSignatureUrl: signatureUrl,
        customerRepresentativeName: customerRepresentativeName,
        customerPhotoUrl: photoUrl,
        technicianDate: technicianDate,
        customerDate: customerDate,
      ),
    );
  }
}

final reportWizardProvider = StateNotifierProvider.autoDispose<ReportWizardNotifier, ReportWizardState>((ref) {
  final repo = ref.watch(reportRepositoryProvider);
  final auth = ref.watch(authProvider);
  final reports = ref.read(reportsProvider.notifier);
  final defaultTechName = auth.userName ?? 'Siva';
  return ReportWizardNotifier(repo, reports, defaultTechName);
});

class ReportWizardNotifier extends StateNotifier<ReportWizardState> {
  final ReportRepository _repository;
  final ReportsNotifier _reportsNotifier;

  ReportWizardNotifier(this._repository, this._reportsNotifier, String defaultTechName)
      : super(ReportWizardState.initial(defaultTechName));

  void updateStep(int step) {
    if (step >= 0 && step < 7) {
      state = state.copyWith(currentStep: step);
    }
  }

  // Step 1 setters
  void updateJobRef(String value) => state = state.copyWith(jobRef: value);
  void updateDateTime(DateTime value) => state = state.copyWith(dateTime: value);
  void updateCustomerName(String value) => state = state.copyWith(customerName: value);
  void updateSiteLocation(String value) => state = state.copyWith(siteLocation: value);
  void updateContactPerson(String value) => state = state.copyWith(contactPerson: value);
  void updateContactNumber(String value) => state = state.copyWith(contactNumber: value);

  // Step 2 setters
  void updateGeneratorMakeModel(String value) => state = state.copyWith(generatorMakeModel: value);
  void updateCapacity(String value) => state = state.copyWith(capacity: value);
  void updateEngineSerialNo(String value) => state = state.copyWith(engineSerialNo: value);
  void updateAlternatorSerialNo(String value) => state = state.copyWith(alternatorSerialNo: value);
  void updateHourMeter(String value) => state = state.copyWith(hourMeter: value);
  void updateHours(int? value) => state = state.copyWith(hours: value);
  void updateBatteryStatusVolt(String value) => state = state.copyWith(batteryStatusVolt: value);

  // Step 3 setters
  void updateChecklistItem(String parameter, String status) {
    final newList = state.serviceChecklist.map((item) {
      if (item.parameter == parameter) {
        return ServiceChecklistItem(parameter: parameter, status: status);
      }
      return item;
    }).toList();
    state = state.copyWith(serviceChecklist: newList);
  }

  // Step 4 setters
  void addPart(String partDescription, String qty) {
    final newList = [...state.partsUsed, PartsUsedItem(partDescription: partDescription, qty: qty)];
    state = state.copyWith(partsUsed: newList);
  }

  void removePart(int index) {
    final newList = List<PartsUsedItem>.from(state.partsUsed)..removeAt(index);
    state = state.copyWith(partsUsed: newList);
  }

  // Step 5 setters
  void updateObservations(String value) => state = state.copyWith(observations: value);
  void updateNextServiceDueDate(DateTime? value) => state = state.copyWith(nextServiceDueDate: value);
  void updateNextServiceDueHours(int? value) => state = state.copyWith(nextServiceDueHours: value);

  // Step 6 setters
  void updateTechnicianName(String value) => state = state.copyWith(technicianName: value);
  void updateCustomerRepresentativeName(String value) => state = state.copyWith(customerRepresentativeName: value);
  void updateTechnicianSignature(File? file) => state = state.copyWith(technicianSignatureFile: file);
  void updateCustomerPhoto(File? file) => state = state.copyWith(customerPhotoFile: file);
  void updateTechnicianDate(DateTime value) => state = state.copyWith(technicianDate: value);
  void updateCustomerDate(DateTime value) => state = state.copyWith(customerDate: value);

  // Draft helper
  Future<void> saveAsDraft() async {
    final draft = state.toReportModel(
      signatureUrl: state.technicianSignatureFile?.path ?? '',
      photoUrl: state.customerPhotoFile?.path ?? '',
    );
    await _reportsNotifier.saveDraft(draft);
  }

  // Validates current step
  bool validateCurrentStep(BuildContext context) {
    state = state.copyWith(error: null);
    switch (state.currentStep) {
      case 0:
        if (state.jobRef.isEmpty || state.customerName.isEmpty) {
          state = state.copyWith(error: 'Job Ref and Customer Name are required.');
          return false;
        }
        return true;
      case 1:
        // Optional steps or simple constraints
        return true;
      case 2:
        return true;
      case 3:
        return true;
      case 4:
        return true;
      case 5:
        if (state.technicianName.isEmpty || state.customerRepresentativeName.isEmpty) {
          state = state.copyWith(error: 'Both Technician and Representative names are required.');
          return false;
        }
        if (state.technicianSignatureFile == null) {
          state = state.copyWith(error: 'Technician Signature is required.');
          return false;
        }
        if (state.customerPhotoFile == null) {
          state = state.copyWith(error: 'Customer Photo is required.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  // Submission to API
  Future<bool> submitReport() async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      if (state.technicianSignatureFile == null || state.customerPhotoFile == null) {
        state = state.copyWith(
          isSubmitting: false,
          error: 'Signature and Customer Photo are required for submission.',
        );
        return false;
      }

      final reportPayload = state.toReportModel();
      final result = await _repository.createReport(
        report: reportPayload,
        signatureFile: state.technicianSignatureFile!,
        photoFile: state.customerPhotoFile!,
      );

      // If this report was a draft, delete the draft
      await _reportsNotifier.deleteDraft(state.jobRef);
      
      // Refresh backend reports list
      await _reportsNotifier.refresh();

      state = state.copyWith(
        isSubmitting: false,
        submittedReport: result,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      );
      return false;
    }
  }
}
