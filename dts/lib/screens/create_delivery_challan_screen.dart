import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/estimate_model.dart';
import '../models/delivery_challan_model.dart';
import '../providers/delivery_challan_wizard_provider.dart';
import '../widgets/stepper/stepper_progress_bar.dart';
import '../widgets/stepper/step_navigation.dart';
import '../widgets/stepper/step_container.dart';
import '../widgets/stepper/step_header.dart';

class CreateDeliveryChallanScreen extends ConsumerStatefulWidget {
  final EstimateModel? initialEstimate;
  final DeliveryChallanModel? initialChallan;

  const CreateDeliveryChallanScreen({
    super.key,
    this.initialEstimate,
    this.initialChallan,
  });

  @override
  ConsumerState<CreateDeliveryChallanScreen> createState() =>
      _CreateDeliveryChallanScreenState();
}

class _CreateDeliveryChallanScreenState
    extends ConsumerState<CreateDeliveryChallanScreen> {
  // Challan Details
  final _challanNumberCtrl = TextEditingController();
  final _placeOfSupplyCtrl = TextEditingController(text: '36-Telangana');

  // Customer Step
  final _customerNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _contactNumberCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _stateCtrl = TextEditingController(text: '36-Telangana');

  // Transportation Step
  final _vehicleNumberCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _transportNameCtrl = TextEditingController();
  final _lrNumberCtrl = TextEditingController();

  // Item Dialog / Editor
  final _itemNameCtrl = TextEditingController();
  final _hsnSacCtrl = TextEditingController();
  final _itemQtyCtrl = TextEditingController();

  // Terms & Signatures
  final _termsCtrl = TextEditingController();
  final _recNameCtrl = TextEditingController();
  final _recCommentCtrl = TextEditingController();
  final _delNameCtrl = TextEditingController();
  final _delCommentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(deliveryChallanWizardProvider.notifier);
      if (widget.initialChallan != null) {
        notifier.loadFromChallan(widget.initialChallan!);
      } else if (widget.initialEstimate != null) {
        notifier.loadFromEstimate(widget.initialEstimate!);
      } else {
        notifier.reset();
      }

      final state = ref.read(deliveryChallanWizardProvider);
      _challanNumberCtrl.text = state.challanNumber ?? '';
      _placeOfSupplyCtrl.text = state.placeOfSupply;

      _customerNameCtrl.text = state.customerName;
      _addressCtrl.text = state.address;
      _contactPersonCtrl.text = state.contactPerson;
      _contactNumberCtrl.text = state.contactNumber;
      _gstinCtrl.text = state.gstinNumber;
      _stateCtrl.text = state.state;

      _vehicleNumberCtrl.text = state.transportationDetails.vehicleNumber ?? '';
      _destinationCtrl.text = state.transportationDetails.destinationLocation ?? '';
      _transportNameCtrl.text = state.transportationDetails.transportName ?? '';
      _lrNumberCtrl.text = state.transportationDetails.lrNumber ?? '';

      _termsCtrl.text = state.termsAndConditions;
      _recNameCtrl.text = state.receivedBy.name ?? '';
      _recCommentCtrl.text = state.receivedBy.comment ?? '';
      _delNameCtrl.text = state.deliveredBy.name ?? '';
      _delCommentCtrl.text = state.deliveredBy.comment ?? '';
    });
  }

  @override
  void dispose() {
    _challanNumberCtrl.dispose();
    _placeOfSupplyCtrl.dispose();

    _customerNameCtrl.dispose();
    _addressCtrl.dispose();
    _contactPersonCtrl.dispose();
    _contactNumberCtrl.dispose();
    _gstinCtrl.dispose();
    _stateCtrl.dispose();

    _vehicleNumberCtrl.dispose();
    _destinationCtrl.dispose();
    _transportNameCtrl.dispose();
    _lrNumberCtrl.dispose();

    _itemNameCtrl.dispose();
    _hsnSacCtrl.dispose();
    _itemQtyCtrl.dispose();

    _termsCtrl.dispose();
    _recNameCtrl.dispose();
    _recCommentCtrl.dispose();
    _delNameCtrl.dispose();
    _delCommentCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectChallanDate(
      BuildContext context,
      DeliveryChallanWizardState state,
      DeliveryChallanWizardNotifier notifier) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: state.challanDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      notifier.updateChallanDate(picked);
    }
  }

  Future<void> _selectDispatchDate(
      BuildContext context,
      DeliveryChallanWizardState state,
      DeliveryChallanWizardNotifier notifier) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: state.transportationDetails.dispatchDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      notifier.updateDispatchDate(picked);
    }
  }

  void _handleNext(
      DeliveryChallanWizardState state, DeliveryChallanWizardNotifier notifier) {
    if (notifier.validateCurrentStep()) {
      notifier.updateStep(state.currentStep + 1);
    } else {
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleBack(
      DeliveryChallanWizardState state, DeliveryChallanWizardNotifier notifier) {
    if (state.currentStep > 0) notifier.updateStep(state.currentStep - 1);
  }

  void _submit(DeliveryChallanWizardNotifier notifier) async {
    final success = await notifier.submitChallan();
    if (success && mounted) {
      final submitted =
          ref.read(deliveryChallanWizardProvider).submittedChallan;
      if (submitted != null) {
        final docId = submitted.id;
        notifier.reset();
        context.go('/dashboard');
        if (docId != null) {
          context.push('/delivery-challan-details/$docId', extra: submitted);
        }
      }
    } else {
      final error = ref.read(deliveryChallanWizardProvider).error;
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deliveryChallanWizardProvider);
    final notifier = ref.read(deliveryChallanWizardProvider.notifier);

    final steps = ['Customer', 'Transport', 'Items', 'Terms & Signatures', 'Preview'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.initialChallan != null
            ? 'Edit Delivery Challan'
            : (widget.initialEstimate != null
                ? 'Convert to Delivery Challan'
                : 'Create Delivery Challan')),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              StepperProgressBar(steps: steps, currentStep: state.currentStep),
              Expanded(
                child: StepContainer(
                  child: _buildStepContent(state, notifier),
                ),
              ),
              StepNavigation(
                currentStep: state.currentStep,
                totalSteps: steps.length,
                onBack: () => _handleBack(state, notifier),
                onNext: state.currentStep == steps.length - 1
                    ? () => _submit(notifier)
                    : () => _handleNext(state, notifier),
                continueLabel: state.currentStep == steps.length - 1
                    ? 'Save Delivery Challan'
                    : 'Next',
                nextButtonColor: state.currentStep == steps.length - 1
                    ? AppColors.success
                    : null,
              ),
            ],
          ),
          if (state.isSubmitting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepContent(
      DeliveryChallanWizardState state, DeliveryChallanWizardNotifier notifier) {
    switch (state.currentStep) {
      case 0:
        return _buildCustomerStep(state, notifier);
      case 1:
        return _buildTransportStep(state, notifier);
      case 2:
        return _buildItemsStep(state, notifier);
      case 3:
        return _buildSignaturesStep(state, notifier);
      case 4:
        return _buildPreviewStep(state, notifier);
      default:
        return const SizedBox();
    }
  }

  Widget _buildCustomerStep(
      DeliveryChallanWizardState state, DeliveryChallanWizardNotifier notifier) {
    final dateStr = DateFormat('dd/MM/yyyy').format(state.challanDate);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepHeader(title: '1. CHALLAN & CUSTOMER DETAILS'),
          const SizedBox(height: 16),

          // Challan Details Group
          const Text(
            'Challan Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _challanNumberCtrl,
            decoration: const InputDecoration(
              labelText: 'Challan Number (Auto-assigned if empty)',
              hintText: 'e.g. 1',
            ),
            onChanged: (val) => notifier.updateChallanNumber(val.trim()),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _selectChallanDate(context, state, notifier),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Challan Date *',
                suffixIcon: Icon(Icons.calendar_today_rounded, color: AppColors.primary),
              ),
              child: Text(
                dateStr,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _placeOfSupplyCtrl,
            decoration: const InputDecoration(labelText: 'Place of Supply *'),
            onChanged: notifier.updatePlaceOfSupply,
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Customer Details Group
          const Text(
            'Delivery Challan For (Customer)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _customerNameCtrl,
            decoration: const InputDecoration(labelText: 'Customer / Company Name *'),
            onChanged: notifier.updateCustomerName,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Customer Address *'),
            onChanged: notifier.updateAddress,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contactPersonCtrl,
            decoration: const InputDecoration(labelText: 'Contact Person'),
            onChanged: notifier.updateContactPerson,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contactNumberCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Contact Number'),
            onChanged: notifier.updateContactNumber,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _gstinCtrl,
            decoration: const InputDecoration(labelText: 'GSTIN Number'),
            onChanged: notifier.updateGstinNumber,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _stateCtrl,
            decoration: const InputDecoration(labelText: 'State'),
            onChanged: notifier.updateState,
          ),
        ],
      ),
    );
  }

  Widget _buildTransportStep(
      DeliveryChallanWizardState state, DeliveryChallanWizardNotifier notifier) {
    final dispatchDate = state.transportationDetails.dispatchDate;
    final dispatchDateStr = dispatchDate != null
        ? DateFormat('dd/MM/yyyy').format(dispatchDate)
        : 'Select Dispatch Date';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepHeader(title: '2. TRANSPORTATION DETAILS'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _vehicleNumberCtrl,
            decoration:
                const InputDecoration(labelText: 'Vehicle / Transport Number (e.g. TS 08 UJ 2829)'),
            onChanged: notifier.updateVehicleNumber,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectDispatchDate(context, state, notifier),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Dispatch / Transport Date',
                suffixIcon: Icon(Icons.calendar_month_rounded, color: AppColors.primary),
              ),
              child: Text(
                dispatchDateStr,
                style: TextStyle(
                  fontSize: 14,
                  color: dispatchDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _destinationCtrl,
            decoration:
                const InputDecoration(labelText: 'Destination / Site Location (e.g. Chandenvalle)'),
            onChanged: notifier.updateDestinationLocation,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _transportNameCtrl,
            decoration: const InputDecoration(labelText: 'Transport Name / Transporter'),
            onChanged: notifier.updateTransportName,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lrNumberCtrl,
            decoration: const InputDecoration(labelText: 'LR Number / Consignment Note No.'),
            onChanged: notifier.updateLrNumber,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsStep(
      DeliveryChallanWizardState state, DeliveryChallanWizardNotifier notifier) {
    final totalQty = state.items.fold<double>(0, (p, e) => p + e.quantity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const StepHeader(title: '3. ITEMS & QUANTITIES'),
        const SizedBox(height: 16),
        if (state.items.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            child: const Center(child: Text('No items added.')),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text('${index + 1}',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(item.itemName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'HSN/SAC: ${item.hsnSac?.isNotEmpty == true ? item.hsnSac : "N/A"}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextFormField(
                          initialValue: item.quantity.toString(),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Qty',
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          onChanged: (val) {
                            final qty = double.tryParse(val) ?? 0;
                            if (qty >= 0) {
                              notifier.updateItemQuantity(index, qty);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => notifier.removeItem(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Quantity:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('$totalQty',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _showAddItemDialog(notifier),
          icon: const Icon(Icons.add),
          label: const Text('Add Item'),
        ),
      ],
    );
  }

  void _showAddItemDialog(DeliveryChallanWizardNotifier notifier) {
    _itemNameCtrl.clear();
    _hsnSacCtrl.clear();
    _itemQtyCtrl.text = '1';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Challan Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _itemNameCtrl,
                decoration: const InputDecoration(labelText: 'Item Name / Description *'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hsnSacCtrl,
                decoration: const InputDecoration(labelText: 'HSN / SAC'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _itemQtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Quantity *'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _itemNameCtrl.text.trim();
              final hsn = _hsnSacCtrl.text.trim();
              final qty = double.tryParse(_itemQtyCtrl.text) ?? 0;
              if (name.isNotEmpty && qty > 0) {
                notifier.addItem(
                  DeliveryChallanItem(
                    itemName: name,
                    hsnSac: hsn.isNotEmpty ? hsn : null,
                    quantity: qty,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignaturesStep(
      DeliveryChallanWizardState state, DeliveryChallanWizardNotifier notifier) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepHeader(title: '4. TERMS & ACKNOWLEDGEMENT'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _termsCtrl,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Terms & Conditions'),
            onChanged: notifier.updateTermsAndConditions,
          ),
          const SizedBox(height: 24),
          const Text(
            'Received By Acknowledgement',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _recNameCtrl,
            decoration: const InputDecoration(labelText: 'Received By Name'),
            onChanged: (val) => notifier.updateReceivedBy(name: val),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _recCommentCtrl,
            decoration: const InputDecoration(labelText: 'Received By Comment'),
            onChanged: (val) => notifier.updateReceivedBy(comment: val),
          ),
          const SizedBox(height: 24),
          const Text(
            'Delivered By Acknowledgement',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _delNameCtrl,
            decoration: const InputDecoration(labelText: 'Delivered By Name'),
            onChanged: (val) => notifier.updateDeliveredBy(name: val),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _delCommentCtrl,
            decoration: const InputDecoration(labelText: 'Delivered By Comment'),
            onChanged: (val) => notifier.updateDeliveredBy(comment: val),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep(
      DeliveryChallanWizardState state, DeliveryChallanWizardNotifier notifier) {
    final totalQty = state.items.fold<double>(0, (p, e) => p + e.quantity);
    final dateStr = DateFormat('dd/MM/yyyy').format(state.challanDate);
    final dispatchDate = state.transportationDetails.dispatchDate;
    final dispatchDateStr = dispatchDate != null
        ? DateFormat('dd/MM/yyyy').format(dispatchDate)
        : 'N/A';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepHeader(title: '5. PREVIEW & VERIFY'),
          const SizedBox(height: 16),

          // Challan Details Summary
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CHALLAN DETAILS',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey)),
                  const Divider(),
                  Text(
                      'Challan Number: ${state.challanNumber?.isNotEmpty == true ? state.challanNumber : "Auto-assigned"}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Challan Date: $dateStr'),
                  Text('Place of Supply: ${state.placeOfSupply}'),
                ],
              ),
            ),
          ),

          // Customer Card
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DELIVERY CHALLAN FOR',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey)),
                  const Divider(),
                  Text(state.customerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  if (state.address.isNotEmpty) Text(state.address),
                  if (state.contactNumber.isNotEmpty)
                    Text('Contact: ${state.contactNumber}'),
                  if (state.gstinNumber.isNotEmpty)
                    Text('GSTIN: ${state.gstinNumber}'),
                  Text('State: ${state.state}'),
                ],
              ),
            ),
          ),

          // Transport Card
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TRANSPORTATION DETAILS',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey)),
                  const Divider(),
                  Text(
                      'Vehicle Number: ${state.transportationDetails.vehicleNumber?.isNotEmpty == true ? state.transportationDetails.vehicleNumber : "N/A"}'),
                  Text('Dispatch Date: $dispatchDateStr'),
                  Text(
                      'Destination: ${state.transportationDetails.destinationLocation?.isNotEmpty == true ? state.transportationDetails.destinationLocation : "N/A"}'),
                  Text(
                      'Transport: ${state.transportationDetails.transportName?.isNotEmpty == true ? state.transportationDetails.transportName : "N/A"}'),
                  Text(
                      'LR Number: ${state.transportationDetails.lrNumber?.isNotEmpty == true ? state.transportationDetails.lrNumber : "N/A"}'),
                ],
              ),
            ),
          ),

          // Items Card
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ITEMS (${state.items.length})',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text('Total Qty: $totalQty',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                    ],
                  ),
                  const Divider(),
                  if (state.items.isEmpty)
                    const Text('No items added.',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                  ...state.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(item.itemName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500))),
                            Text('Qty: ${item.quantity}'),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
