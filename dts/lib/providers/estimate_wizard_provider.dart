import 'package:flutter_riverpod/legacy.dart';
import '../models/estimate_model.dart';
import '../repositories/estimate_repository.dart';
import 'estimates_provider.dart';

class EstimateWizardState {
  final String? id;
  final String status;
  final String? estimateNumber;
  final DateTime estimateDate;
  final String customerName;
  final String address;
  final String contactPerson;
  final String contactNumber;
  final String gstinNumber;
  final String placeOfSupply;
  final List<EstimateItem> items;
  final String termsAndConditions;
  
  final int currentStep;
  final bool isSubmitting;
  final String? error;
  final EstimateModel? submittedEstimate;

  EstimateWizardState({
    this.id,
    required this.status,
    this.estimateNumber,
    required this.estimateDate,
    required this.customerName,
    required this.address,
    required this.contactPerson,
    required this.contactNumber,
    required this.gstinNumber,
    required this.placeOfSupply,
    required this.items,
    required this.termsAndConditions,
    required this.currentStep,
    required this.isSubmitting,
    this.error,
    this.submittedEstimate,
  });

  factory EstimateWizardState.initial() {
    return EstimateWizardState(
      id: null,
      status: 'draft',
      estimateNumber: null,
      estimateDate: DateTime.now(),
      customerName: '',
      address: '',
      contactPerson: '',
      contactNumber: '',
      gstinNumber: '',
      placeOfSupply: '',
      items: [],
      termsAndConditions: 'Thank you for doing business with us.\n*100% advance is mandatory',
      currentStep: 0,
      isSubmitting: false,
      error: null,
      submittedEstimate: null,
    );
  }

  EstimateWizardState copyWith({
    String? id,
    String? status,
    String? estimateNumber,
    DateTime? estimateDate,
    String? customerName,
    String? address,
    String? contactPerson,
    String? contactNumber,
    String? gstinNumber,
    String? placeOfSupply,
    List<EstimateItem>? items,
    String? termsAndConditions,
    int? currentStep,
    bool? isSubmitting,
    String? error,
    EstimateModel? submittedEstimate,
  }) {
    return EstimateWizardState(
      id: id ?? this.id,
      status: status ?? this.status,
      estimateNumber: estimateNumber ?? this.estimateNumber,
      estimateDate: estimateDate ?? this.estimateDate,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      contactPerson: contactPerson ?? this.contactPerson,
      contactNumber: contactNumber ?? this.contactNumber,
      gstinNumber: gstinNumber ?? this.gstinNumber,
      placeOfSupply: placeOfSupply ?? this.placeOfSupply,
      items: items ?? this.items,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      currentStep: currentStep ?? this.currentStep,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error, // intentionally reset if not provided
      submittedEstimate: submittedEstimate ?? this.submittedEstimate,
    );
  }

  EstimateModel toEstimateModel() {
    return EstimateModel(
      id: id,
      status: status,
      estimateDate: estimateDate,
      placeOfSupply: placeOfSupply.isNotEmpty ? placeOfSupply : null,
      estimateFor: EstimateCustomerDetails(
        customerName: customerName,
        address: address,
        contactPerson: contactPerson.isNotEmpty ? contactPerson : null,
        contactNumber: contactNumber,
        gstinNumber: gstinNumber.isNotEmpty ? gstinNumber : null,
      ),
      items: items,
      termsAndConditions: termsAndConditions.isNotEmpty ? termsAndConditions : null,
    );
  }
}

class EstimateWizardNotifier extends StateNotifier<EstimateWizardState> {
  final EstimateRepository _repository;
  final EstimatesNotifier _estimatesNotifier;

  EstimateWizardNotifier(this._repository, this._estimatesNotifier) : super(EstimateWizardState.initial());

  void reset() {
    state = EstimateWizardState.initial();
  }

  void loadFromEstimate(EstimateModel estimate) {
    state = EstimateWizardState(
      id: estimate.id,
      status: estimate.status,
      estimateNumber: estimate.estimateNumber,
      estimateDate: estimate.estimateDate,
      customerName: estimate.estimateFor.customerName,
      address: estimate.estimateFor.address,
      contactPerson: estimate.estimateFor.contactPerson ?? '',
      contactNumber: estimate.estimateFor.contactNumber,
      gstinNumber: estimate.estimateFor.gstinNumber ?? '',
      placeOfSupply: estimate.placeOfSupply ?? '',
      items: estimate.items,
      termsAndConditions: estimate.termsAndConditions ?? '',
      currentStep: 0,
      isSubmitting: false,
      error: null,
      submittedEstimate: null,
    );
  }

  void updateStep(int step) => state = state.copyWith(currentStep: step);
  
  // Setters
  void updateEstimateDate(DateTime date) => state = state.copyWith(estimateDate: date);
  void updatePlaceOfSupply(String pos) => state = state.copyWith(placeOfSupply: pos);
  
  void updateCustomerName(String name) => state = state.copyWith(customerName: name);
  void updateAddress(String address) => state = state.copyWith(address: address);
  void updateContactPerson(String person) => state = state.copyWith(contactPerson: person);
  void updateContactNumber(String number) => state = state.copyWith(contactNumber: number);
  void updateGstinNumber(String gstin) => state = state.copyWith(gstinNumber: gstin);
  
  void updateTermsAndConditions(String terms) => state = state.copyWith(termsAndConditions: terms);

  // Items
  void addItem(EstimateItem item) {
    state = state.copyWith(items: [...state.items, item]);
  }
  
  void removeItem(int index) {
    final newItems = List<EstimateItem>.from(state.items)..removeAt(index);
    state = state.copyWith(items: newItems);
  }

  bool validateCurrentStep() {
    state = state.copyWith(error: null);
    
    switch (state.currentStep) {
      case 0:
        if (state.customerName.isEmpty || state.address.isEmpty || state.contactNumber.isEmpty) {
          state = state.copyWith(error: 'Please fill in required customer details.');
          return false;
        }
        return true;
      case 1:
        if (state.items.isEmpty) {
          state = state.copyWith(error: 'Please add at least one item.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<bool> submitEstimate() async {
    state = state.copyWith(isSubmitting: true, error: null);

    try {
      if (state.items.isEmpty) {
        state = state.copyWith(isSubmitting: false, error: 'At least one item is required.');
        return false;
      }
      if (state.customerName.isEmpty || state.address.isEmpty || state.contactNumber.isEmpty) {
        state = state.copyWith(isSubmitting: false, error: 'Customer Name, Address, and Contact Number are required.');
        return false;
      }

      final payload = state.toEstimateModel();
      EstimateModel result;

      if (state.id != null) {
        result = await _repository.updateEstimate(id: state.id!, estimate: payload);
      } else {
        result = await _repository.createEstimate(estimate: payload);
      }

      await _estimatesNotifier.refresh();

      state = state.copyWith(
        isSubmitting: false,
        submittedEstimate: result,
        status: result.status,
        estimateNumber: result.estimateNumber,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

final estimateWizardProvider = StateNotifierProvider.autoDispose<EstimateWizardNotifier, EstimateWizardState>((ref) {
  final repo = ref.watch(estimateRepositoryProvider);
  final estimates = ref.read(estimatesProvider.notifier);
  return EstimateWizardNotifier(repo, estimates);
});
