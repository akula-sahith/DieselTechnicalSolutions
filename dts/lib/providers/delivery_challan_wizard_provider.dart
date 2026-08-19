import 'package:flutter_riverpod/legacy.dart';
import '../models/estimate_model.dart';
import '../models/delivery_challan_model.dart';
import '../repositories/delivery_challan_repository.dart';
import 'delivery_challans_provider.dart';

class DeliveryChallanWizardState {
  final String? id;
  final String? challanNumber;
  final DateTime challanDate;
  final String customerName;
  final String address;
  final String contactPerson;
  final String contactNumber;
  final String gstinNumber;
  final String state;
  final String placeOfSupply;
  final DeliveryChallanTransportationDetails transportationDetails;
  final List<DeliveryChallanItem> items;
  final String termsAndConditions;
  final ChallanSignatory receivedBy;
  final ChallanSignatory deliveredBy;
  final String? authorizedSignatureUrl;
  final String? linkedEstimateId;

  final int currentStep;
  final bool isSubmitting;
  final String? error;
  final DeliveryChallanModel? submittedChallan;

  DeliveryChallanWizardState({
    this.id,
    this.challanNumber,
    required this.challanDate,
    required this.customerName,
    required this.address,
    required this.contactPerson,
    required this.contactNumber,
    required this.gstinNumber,
    required this.state,
    required this.placeOfSupply,
    required this.transportationDetails,
    required this.items,
    required this.termsAndConditions,
    required this.receivedBy,
    required this.deliveredBy,
    this.authorizedSignatureUrl,
    this.linkedEstimateId,
    required this.currentStep,
    required this.isSubmitting,
    this.error,
    this.submittedChallan,
  });

  factory DeliveryChallanWizardState.initial() {
    return DeliveryChallanWizardState(
      id: null,
      challanNumber: null,
      challanDate: DateTime.now(),
      customerName: '',
      address: '',
      contactPerson: '',
      contactNumber: '',
      gstinNumber: '',
      state: '36-Telangana',
      placeOfSupply: '36-Telangana',
      transportationDetails: DeliveryChallanTransportationDetails(),
      items: [],
      termsAndConditions:
          'Thank you for doing business with us.\n1. All disputes subject to Secunderabad Jurisdiction only\n2. Does not include erection & commissioning at site\n3. Transit insurance from factory to site will be buyer\'s responsibility\n4. Interest @ 24% p.a. will be charged on balance payments, if material not collected against confirmed order within one week of our intimation of material being ready for dispatch',
      receivedBy: ChallanSignatory(),
      deliveredBy: ChallanSignatory(),
      authorizedSignatureUrl: null,
      linkedEstimateId: null,
      currentStep: 0,
      isSubmitting: false,
      error: null,
      submittedChallan: null,
    );
  }

  DeliveryChallanWizardState copyWith({
    String? id,
    String? challanNumber,
    DateTime? challanDate,
    String? customerName,
    String? address,
    String? contactPerson,
    String? contactNumber,
    String? gstinNumber,
    String? state,
    String? placeOfSupply,
    DeliveryChallanTransportationDetails? transportationDetails,
    List<DeliveryChallanItem>? items,
    String? termsAndConditions,
    ChallanSignatory? receivedBy,
    ChallanSignatory? deliveredBy,
    String? authorizedSignatureUrl,
    String? linkedEstimateId,
    int? currentStep,
    bool? isSubmitting,
    String? error,
    DeliveryChallanModel? submittedChallan,
  }) {
    return DeliveryChallanWizardState(
      id: id ?? this.id,
      challanNumber: challanNumber ?? this.challanNumber,
      challanDate: challanDate ?? this.challanDate,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      contactPerson: contactPerson ?? this.contactPerson,
      contactNumber: contactNumber ?? this.contactNumber,
      gstinNumber: gstinNumber ?? this.gstinNumber,
      state: state ?? this.state,
      placeOfSupply: placeOfSupply ?? this.placeOfSupply,
      transportationDetails: transportationDetails ?? this.transportationDetails,
      items: items ?? this.items,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      receivedBy: receivedBy ?? this.receivedBy,
      deliveredBy: deliveredBy ?? this.deliveredBy,
      authorizedSignatureUrl: authorizedSignatureUrl ?? this.authorizedSignatureUrl,
      linkedEstimateId: linkedEstimateId ?? this.linkedEstimateId,
      currentStep: currentStep ?? this.currentStep,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      submittedChallan: submittedChallan ?? this.submittedChallan,
    );
  }

  DeliveryChallanModel toDeliveryChallanModel() {
    final double totalQty = items.fold<double>(0, (p, e) => p + e.quantity);
    return DeliveryChallanModel(
      id: id,
      challanNumber: challanNumber,
      challanDate: challanDate,
      deliveryChallanFor: DeliveryChallanCustomerDetails(
        customerName: customerName,
        address: address,
        contactPerson: contactPerson.isNotEmpty ? contactPerson : null,
        contactNumber: contactNumber,
        gstinNumber: gstinNumber.isNotEmpty ? gstinNumber : null,
        state: state,
      ),
      transportationDetails: transportationDetails,
      placeOfSupply: placeOfSupply.isNotEmpty ? placeOfSupply : '36-Telangana',
      items: items,
      totalQuantity: totalQty,
      termsAndConditions: termsAndConditions.isNotEmpty ? termsAndConditions : null,
      receivedBy: receivedBy,
      deliveredBy: deliveredBy,
      authorizedSignatureUrl: authorizedSignatureUrl,
      linkedEstimateId: linkedEstimateId,
      status: 'issued',
    );
  }
}

class DeliveryChallanWizardNotifier extends StateNotifier<DeliveryChallanWizardState> {
  final DeliveryChallanRepository _repository;
  final DeliveryChallansNotifier _challansNotifier;

  DeliveryChallanWizardNotifier(this._repository, this._challansNotifier)
      : super(DeliveryChallanWizardState.initial());

  void reset() {
    state = DeliveryChallanWizardState.initial();
  }

  void loadFromChallan(DeliveryChallanModel challan) {
    state = DeliveryChallanWizardState(
      id: challan.id,
      challanNumber: challan.challanNumber,
      challanDate: challan.challanDate,
      customerName: challan.deliveryChallanFor.customerName,
      address: challan.deliveryChallanFor.address,
      contactPerson: challan.deliveryChallanFor.contactPerson ?? '',
      contactNumber: challan.deliveryChallanFor.contactNumber,
      gstinNumber: challan.deliveryChallanFor.gstinNumber ?? '',
      state: challan.deliveryChallanFor.state,
      placeOfSupply: challan.placeOfSupply,
      transportationDetails: challan.transportationDetails,
      items: List.from(challan.items),
      termsAndConditions: challan.termsAndConditions ?? '',
      receivedBy: challan.receivedBy ?? ChallanSignatory(),
      deliveredBy: challan.deliveredBy ?? ChallanSignatory(),
      authorizedSignatureUrl: challan.authorizedSignatureUrl,
      linkedEstimateId: challan.linkedEstimateId,
      currentStep: 0,
      isSubmitting: false,
      error: null,
      submittedChallan: null,
    );
  }

  void loadFromEstimate(EstimateModel estimate) {
    final carriedItems = estimate.items
        .map((item) => DeliveryChallanItem(
              itemName: item.itemName,
              hsnSac: item.hsnSac,
              quantity: item.quantity,
            ))
        .toList();

    state = DeliveryChallanWizardState(
      id: null,
      challanNumber: null,
      challanDate: DateTime.now(),
      customerName: estimate.estimateFor.customerName,
      address: estimate.estimateFor.address,
      contactPerson: estimate.estimateFor.contactPerson ?? '',
      contactNumber: estimate.estimateFor.contactNumber,
      gstinNumber: estimate.estimateFor.gstinNumber ?? '',
      state: '36-Telangana',
      placeOfSupply: estimate.placeOfSupply ?? '36-Telangana',
      transportationDetails: DeliveryChallanTransportationDetails(),
      items: carriedItems,
      termsAndConditions:
          'Thank you for doing business with us.\n1. All disputes subject to Secunderabad Jurisdiction only\n2. Does not include erection & commissioning at site\n3. Transit insurance from factory to site will be buyer\'s responsibility\n4. Interest @ 24% p.a. will be charged on balance payments, if material not collected against confirmed order within one week of our intimation of material being ready for dispatch',
      receivedBy: ChallanSignatory(),
      deliveredBy: ChallanSignatory(),
      authorizedSignatureUrl: estimate.technicianSignatureUrl,
      linkedEstimateId: estimate.id,
      currentStep: 0,
      isSubmitting: false,
      error: null,
      submittedChallan: null,
    );
  }

  void updateStep(int step) => state = state.copyWith(currentStep: step);

  void updateChallanNumber(String? number) =>
      state = state.copyWith(challanNumber: (number == null || number.isEmpty) ? null : number);
  void updateChallanDate(DateTime date) => state = state.copyWith(challanDate: date);
  void updatePlaceOfSupply(String pos) => state = state.copyWith(placeOfSupply: pos);

  void updateCustomerName(String name) => state = state.copyWith(customerName: name);
  void updateAddress(String address) => state = state.copyWith(address: address);
  void updateContactPerson(String person) => state = state.copyWith(contactPerson: person);
  void updateContactNumber(String number) => state = state.copyWith(contactNumber: number);
  void updateGstinNumber(String gstin) => state = state.copyWith(gstinNumber: gstin);
  void updateState(String st) => state = state.copyWith(state: st);

  void updateTermsAndConditions(String terms) =>
      state = state.copyWith(termsAndConditions: terms);

  // Transportation Details
  void updateVehicleNumber(String val) {
    state = state.copyWith(
      transportationDetails: DeliveryChallanTransportationDetails(
        vehicleNumber: val,
        dispatchDate: state.transportationDetails.dispatchDate,
        destinationLocation: state.transportationDetails.destinationLocation,
        transportName: state.transportationDetails.transportName,
        lrNumber: state.transportationDetails.lrNumber,
      ),
    );
  }

  void updateDispatchDate(DateTime? val) {
    state = state.copyWith(
      transportationDetails: DeliveryChallanTransportationDetails(
        vehicleNumber: state.transportationDetails.vehicleNumber,
        dispatchDate: val,
        destinationLocation: state.transportationDetails.destinationLocation,
        transportName: state.transportationDetails.transportName,
        lrNumber: state.transportationDetails.lrNumber,
      ),
    );
  }

  void updateDestinationLocation(String val) {
    state = state.copyWith(
      transportationDetails: DeliveryChallanTransportationDetails(
        vehicleNumber: state.transportationDetails.vehicleNumber,
        dispatchDate: state.transportationDetails.dispatchDate,
        destinationLocation: val,
        transportName: state.transportationDetails.transportName,
        lrNumber: state.transportationDetails.lrNumber,
      ),
    );
  }

  void updateTransportName(String val) {
    state = state.copyWith(
      transportationDetails: DeliveryChallanTransportationDetails(
        vehicleNumber: state.transportationDetails.vehicleNumber,
        dispatchDate: state.transportationDetails.dispatchDate,
        destinationLocation: state.transportationDetails.destinationLocation,
        transportName: val,
        lrNumber: state.transportationDetails.lrNumber,
      ),
    );
  }

  void updateLrNumber(String val) {
    state = state.copyWith(
      transportationDetails: DeliveryChallanTransportationDetails(
        vehicleNumber: state.transportationDetails.vehicleNumber,
        dispatchDate: state.transportationDetails.dispatchDate,
        destinationLocation: state.transportationDetails.destinationLocation,
        transportName: state.transportationDetails.transportName,
        lrNumber: val,
      ),
    );
  }

  // Items
  void addItem(DeliveryChallanItem item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void updateItemQuantity(int index, double quantity) {
    if (index >= 0 && index < state.items.length) {
      final newItems = List<DeliveryChallanItem>.from(state.items);
      newItems[index] = DeliveryChallanItem(
        itemName: newItems[index].itemName,
        hsnSac: newItems[index].hsnSac,
        quantity: quantity,
      );
      state = state.copyWith(items: newItems);
    }
  }

  void removeItem(int index) {
    final newItems = List<DeliveryChallanItem>.from(state.items)..removeAt(index);
    state = state.copyWith(items: newItems);
  }

  // Signatories
  void updateReceivedBy({String? name, String? comment, DateTime? date, String? signatureUrl}) {
    state = state.copyWith(
      receivedBy: ChallanSignatory(
        name: name ?? state.receivedBy.name,
        comment: comment ?? state.receivedBy.comment,
        date: date ?? state.receivedBy.date,
        signatureUrl: signatureUrl ?? state.receivedBy.signatureUrl,
      ),
    );
  }

  void updateDeliveredBy({String? name, String? comment, DateTime? date, String? signatureUrl}) {
    state = state.copyWith(
      deliveredBy: ChallanSignatory(
        name: name ?? state.deliveredBy.name,
        comment: comment ?? state.deliveredBy.comment,
        date: date ?? state.deliveredBy.date,
        signatureUrl: signatureUrl ?? state.deliveredBy.signatureUrl,
      ),
    );
  }

  bool validateCurrentStep() {
    state = state.copyWith(error: null);

    switch (state.currentStep) {
      case 0: // Customer
        if (state.customerName.isEmpty || state.address.isEmpty) {
          state = state.copyWith(error: 'Please fill in Customer Name and Address.');
          return false;
        }
        return true;
      case 1: // Transportation
        return true;
      case 2: // Items
        if (state.items.isEmpty) {
          state = state.copyWith(error: 'Please add at least one item.');
          return false;
        }
        return true;
      case 3: // Signatures / Terms
        return true;
      default:
        return true;
    }
  }

  Future<bool> submitChallan() async {
    state = state.copyWith(isSubmitting: true, error: null);

    try {
      if (state.items.isEmpty) {
        state = state.copyWith(
            isSubmitting: false, error: 'At least one item is required.');
        return false;
      }
      if (state.customerName.isEmpty || state.address.isEmpty) {
        state = state.copyWith(
            isSubmitting: false, error: 'Customer Name and Address are required.');
        return false;
      }

      final payload = state.toDeliveryChallanModel();
      DeliveryChallanModel result;

      if (state.id != null) {
        result = await _repository.updateDeliveryChallan(
            id: state.id!, deliveryChallan: payload);
      } else if (state.linkedEstimateId != null) {
        result = await _repository.convertEstimateToDeliveryChallan(
            estimateId: state.linkedEstimateId!, deliveryChallan: payload);
      } else {
        result = await _repository.createDeliveryChallan(deliveryChallan: payload);
      }

      await _challansNotifier.refresh();

      state = state.copyWith(
        isSubmitting: false,
        submittedChallan: result,
        challanNumber: result.challanNumber,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

final deliveryChallanWizardProvider = StateNotifierProvider.autoDispose<
    DeliveryChallanWizardNotifier, DeliveryChallanWizardState>((ref) {
  final repo = ref.watch(deliveryChallanRepositoryProvider);
  final challans = ref.read(deliveryChallansProvider.notifier);
  return DeliveryChallanWizardNotifier(repo, challans);
});
