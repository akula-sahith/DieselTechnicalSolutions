import 'package:flutter_riverpod/legacy.dart';
import '../models/estimate_model.dart';
import '../models/tax_invoice_model.dart';
import '../repositories/tax_invoice_repository.dart';
import 'tax_invoices_provider.dart';

class TaxInvoiceWizardState {
  final String? id;
  final String? invoiceNumber;
  final DateTime invoiceDate;
  final String customerName;
  final String address;
  final String contactPerson;
  final String contactNumber;
  final String gstinNumber;
  final String placeOfSupply;
  final TransportationDetails transportationDetails;
  final List<EstimateItem> items;
  final String termsAndConditions;
  final String? linkedEstimateId;
  
  final int currentStep;
  final bool isSubmitting;
  final String? error;
  final TaxInvoiceModel? submittedInvoice;

  TaxInvoiceWizardState({
    this.id,
    this.invoiceNumber,
    required this.invoiceDate,
    required this.customerName,
    required this.address,
    required this.contactPerson,
    required this.contactNumber,
    required this.gstinNumber,
    required this.placeOfSupply,
    required this.transportationDetails,
    required this.items,
    required this.termsAndConditions,
    this.linkedEstimateId,
    required this.currentStep,
    required this.isSubmitting,
    this.error,
    this.submittedInvoice,
  });

  factory TaxInvoiceWizardState.initial() {
    return TaxInvoiceWizardState(
      id: null,
      invoiceNumber: null,
      invoiceDate: DateTime.now(),
      customerName: '',
      address: '',
      contactPerson: '',
      contactNumber: '',
      gstinNumber: '',
      placeOfSupply: '',
      transportationDetails: TransportationDetails(),
      items: [],
      termsAndConditions: 'Thank you for doing business with us.\n*You want a tax bill that will be his higher.',
      linkedEstimateId: null,
      currentStep: 0,
      isSubmitting: false,
      error: null,
      submittedInvoice: null,
    );
  }

  TaxInvoiceWizardState copyWith({
    String? id,
    String? invoiceNumber,
    DateTime? invoiceDate,
    String? customerName,
    String? address,
    String? contactPerson,
    String? contactNumber,
    String? gstinNumber,
    String? placeOfSupply,
    TransportationDetails? transportationDetails,
    List<EstimateItem>? items,
    String? termsAndConditions,
    String? linkedEstimateId,
    int? currentStep,
    bool? isSubmitting,
    String? error,
    TaxInvoiceModel? submittedInvoice,
  }) {
    return TaxInvoiceWizardState(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      contactPerson: contactPerson ?? this.contactPerson,
      contactNumber: contactNumber ?? this.contactNumber,
      gstinNumber: gstinNumber ?? this.gstinNumber,
      placeOfSupply: placeOfSupply ?? this.placeOfSupply,
      transportationDetails: transportationDetails ?? this.transportationDetails,
      items: items ?? this.items,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      linkedEstimateId: linkedEstimateId ?? this.linkedEstimateId,
      currentStep: currentStep ?? this.currentStep,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      submittedInvoice: submittedInvoice ?? this.submittedInvoice,
    );
  }

  TaxInvoiceModel toTaxInvoiceModel() {
    return TaxInvoiceModel(
      id: id,
      invoiceDate: invoiceDate,
      placeOfSupply: placeOfSupply.isNotEmpty ? placeOfSupply : null,
      billTo: EstimateCustomerDetails(
        customerName: customerName,
        address: address,
        contactPerson: contactPerson.isNotEmpty ? contactPerson : null,
        contactNumber: contactNumber,
        gstinNumber: gstinNumber.isNotEmpty ? gstinNumber : null,
      ),
      transportationDetails: transportationDetails,
      items: items,
      termsAndConditions: termsAndConditions.isNotEmpty ? termsAndConditions : null,
      linkedEstimateId: linkedEstimateId,
    );
  }
}

class TaxInvoiceWizardNotifier extends StateNotifier<TaxInvoiceWizardState> {
  final TaxInvoiceRepository _repository;
  final TaxInvoicesNotifier _invoicesNotifier;

  TaxInvoiceWizardNotifier(this._repository, this._invoicesNotifier) : super(TaxInvoiceWizardState.initial());

  void reset() {
    state = TaxInvoiceWizardState.initial();
  }

  void loadFromInvoice(TaxInvoiceModel invoice) {
    state = TaxInvoiceWizardState(
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      invoiceDate: invoice.invoiceDate,
      customerName: invoice.billTo.customerName,
      address: invoice.billTo.address,
      contactPerson: invoice.billTo.contactPerson ?? '',
      contactNumber: invoice.billTo.contactNumber,
      gstinNumber: invoice.billTo.gstinNumber ?? '',
      placeOfSupply: invoice.placeOfSupply ?? '',
      transportationDetails: invoice.transportationDetails ?? TransportationDetails(),
      items: invoice.items,
      termsAndConditions: invoice.termsAndConditions ?? '',
      linkedEstimateId: invoice.linkedEstimateId,
      currentStep: 0,
      isSubmitting: false,
      error: null,
      submittedInvoice: null,
    );
  }

  void loadFromEstimate(EstimateModel estimate) {
    state = TaxInvoiceWizardState(
      id: null,
      invoiceNumber: null,
      invoiceDate: DateTime.now(),
      customerName: estimate.estimateFor.customerName,
      address: estimate.estimateFor.address,
      contactPerson: estimate.estimateFor.contactPerson ?? '',
      contactNumber: estimate.estimateFor.contactNumber,
      gstinNumber: estimate.estimateFor.gstinNumber ?? '',
      placeOfSupply: estimate.placeOfSupply ?? '',
      transportationDetails: TransportationDetails(),
      items: estimate.items,
      termsAndConditions: 'Thank you for doing business with us.\n*100% advance is mandatory',
      linkedEstimateId: estimate.id,
      currentStep: 0,
      isSubmitting: false,
      error: null,
      submittedInvoice: null,
    );
  }

  void updateStep(int step) => state = state.copyWith(currentStep: step);
  
  // Setters
  void updateInvoiceDate(DateTime date) => state = state.copyWith(invoiceDate: date);
  void updatePlaceOfSupply(String pos) => state = state.copyWith(placeOfSupply: pos);
  
  void updateCustomerName(String name) => state = state.copyWith(customerName: name);
  void updateAddress(String address) => state = state.copyWith(address: address);
  void updateContactPerson(String person) => state = state.copyWith(contactPerson: person);
  void updateContactNumber(String number) => state = state.copyWith(contactNumber: number);
  void updateGstinNumber(String gstin) => state = state.copyWith(gstinNumber: gstin);
  
  void updateTermsAndConditions(String terms) => state = state.copyWith(termsAndConditions: terms);

  // Transportation Details
  void updateVehicleNumber(String val) => state = state.copyWith(transportationDetails: TransportationDetails(vehicleNumber: val, transportName: state.transportationDetails.transportName, lrNumber: state.transportationDetails.lrNumber, dispatchDetails: state.transportationDetails.dispatchDetails, deliveryDetails: state.transportationDetails.deliveryDetails));
  void updateTransportName(String val) => state = state.copyWith(transportationDetails: TransportationDetails(vehicleNumber: state.transportationDetails.vehicleNumber, transportName: val, lrNumber: state.transportationDetails.lrNumber, dispatchDetails: state.transportationDetails.dispatchDetails, deliveryDetails: state.transportationDetails.deliveryDetails));
  void updateLrNumber(String val) => state = state.copyWith(transportationDetails: TransportationDetails(vehicleNumber: state.transportationDetails.vehicleNumber, transportName: state.transportationDetails.transportName, lrNumber: val, dispatchDetails: state.transportationDetails.dispatchDetails, deliveryDetails: state.transportationDetails.deliveryDetails));
  void updateDispatchDetails(String val) => state = state.copyWith(transportationDetails: TransportationDetails(vehicleNumber: state.transportationDetails.vehicleNumber, transportName: state.transportationDetails.transportName, lrNumber: state.transportationDetails.lrNumber, dispatchDetails: val, deliveryDetails: state.transportationDetails.deliveryDetails));
  void updateDeliveryDetails(String val) => state = state.copyWith(transportationDetails: TransportationDetails(vehicleNumber: state.transportationDetails.vehicleNumber, transportName: state.transportationDetails.transportName, lrNumber: state.transportationDetails.lrNumber, dispatchDetails: state.transportationDetails.dispatchDetails, deliveryDetails: val));

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
    
    if (state.linkedEstimateId != null) {
      return true;
    }

    switch (state.currentStep) {
      case 0: // Customer
        if (state.customerName.isEmpty || state.address.isEmpty || state.contactNumber.isEmpty) {
          state = state.copyWith(error: 'Please fill in required customer details.');
          return false;
        }
        return true;
      case 1: // Transportation
        // Transportation can be optional, no strict validation
        return true;
      case 2: // Items
        if (state.items.isEmpty) {
          state = state.copyWith(error: 'Please add at least one item.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<bool> submitInvoice() async {
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

      final payload = state.toTaxInvoiceModel();
      TaxInvoiceModel result;

      if (state.id != null) {
        result = await _repository.updateTaxInvoice(id: state.id!, taxInvoice: payload);
      } else {
        result = await _repository.createTaxInvoice(taxInvoice: payload);
      }

      await _invoicesNotifier.refresh();

      state = state.copyWith(
        isSubmitting: false,
        submittedInvoice: result,
        invoiceNumber: result.invoiceNumber,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

final taxInvoiceWizardProvider = StateNotifierProvider.autoDispose<TaxInvoiceWizardNotifier, TaxInvoiceWizardState>((ref) {
  final repo = ref.watch(taxInvoiceRepositoryProvider);
  final invoices = ref.read(taxInvoicesProvider.notifier);
  return TaxInvoiceWizardNotifier(repo, invoices);
});
