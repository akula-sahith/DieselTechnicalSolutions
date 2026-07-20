import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/estimate_model.dart';
import '../models/tax_invoice_model.dart';
import '../providers/tax_invoice_wizard_provider.dart';
import '../providers/tax_invoices_provider.dart';
import '../widgets/stepper/stepper_progress_bar.dart';
import '../widgets/stepper/step_navigation.dart';
import '../widgets/stepper/step_container.dart';
import '../widgets/stepper/step_header.dart';

class CreateTaxInvoiceScreen extends ConsumerStatefulWidget {
  final EstimateModel? initialEstimate;
  const CreateTaxInvoiceScreen({super.key, this.initialEstimate});

  @override
  ConsumerState<CreateTaxInvoiceScreen> createState() => _CreateTaxInvoiceScreenState();
}

class _CreateTaxInvoiceScreenState extends ConsumerState<CreateTaxInvoiceScreen> {
  // Customer Step
  final _customerNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _contactNumberCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _placeOfSupplyCtrl = TextEditingController();

  // Transportation Step
  final _vehicleNumberCtrl = TextEditingController();
  final _transportNameCtrl = TextEditingController();
  final _lrNumberCtrl = TextEditingController();

  // Item Dialog
  final _itemNameCtrl = TextEditingController();
  final _itemQtyCtrl = TextEditingController();
  final _itemPriceCtrl = TextEditingController();
  final _gstPctCtrl = TextEditingController(text: '18');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialEstimate != null) {
        ref.read(taxInvoiceWizardProvider.notifier).loadFromEstimate(widget.initialEstimate!);
      } else {
        ref.read(taxInvoiceWizardProvider.notifier).reset();
      }

      final state = ref.read(taxInvoiceWizardProvider);
      // Pre-populate controllers
      _customerNameCtrl.text = state.customerName;
      _addressCtrl.text = state.address;
      _contactPersonCtrl.text = state.contactPerson;
      _contactNumberCtrl.text = state.contactNumber;
      _gstinCtrl.text = state.gstinNumber;
      _placeOfSupplyCtrl.text = state.placeOfSupply;
      _vehicleNumberCtrl.text = state.transportationDetails.vehicleNumber ?? '';
      _transportNameCtrl.text = state.transportationDetails.transportName ?? '';
      _lrNumberCtrl.text = state.transportationDetails.lrNumber ?? '';
    });
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _addressCtrl.dispose();
    _contactPersonCtrl.dispose();
    _contactNumberCtrl.dispose();
    _gstinCtrl.dispose();
    _placeOfSupplyCtrl.dispose();
    _vehicleNumberCtrl.dispose();
    _transportNameCtrl.dispose();
    _lrNumberCtrl.dispose();
    _itemNameCtrl.dispose();
    _itemQtyCtrl.dispose();
    _itemPriceCtrl.dispose();
    _gstPctCtrl.dispose();
    super.dispose();
  }

  void _handleNext(TaxInvoiceWizardState state, TaxInvoiceWizardNotifier notifier) {
    if (notifier.validateCurrentStep()) {
      notifier.updateStep(state.currentStep + 1);
    } else {
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!), backgroundColor: AppColors.error));
      }
    }
  }

  void _handleBack(TaxInvoiceWizardState state, TaxInvoiceWizardNotifier notifier) {
    if (state.currentStep > 0) notifier.updateStep(state.currentStep - 1);
  }

  void _submit(TaxInvoiceWizardNotifier notifier) async {
    final success = await notifier.submitInvoice();
    if (success && mounted) {
      final submitted = ref.read(taxInvoiceWizardProvider).submittedInvoice;
      if (submitted != null) {
        final docId = submitted.id;
        notifier.reset();
        context.go('/dashboard');
        context.push('/tax-invoice-details/$docId', extra: submitted);
      }
    } else {
      final error = ref.read(taxInvoiceWizardProvider).error;
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $error'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taxInvoiceWizardProvider);
    final notifier = ref.read(taxInvoiceWizardProvider.notifier);
    final isConversion = state.linkedEstimateId != null;
    final steps = isConversion ? ['Transport', 'Preview'] : ['Customer', 'Transport', 'Items', 'Preview'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Tax Invoice')),
      body: Stack(
        children: [
          Column(
            children: [
              StepperProgressBar(steps: steps, currentStep: state.currentStep),
              Expanded(child: StepContainer(child: _buildStepContent(state, notifier))),
              StepNavigation(
                currentStep: state.currentStep,
                totalSteps: steps.length,
                onBack: () => _handleBack(state, notifier),
                onNext: state.currentStep == steps.length - 1 ? () => _submit(notifier) : () => _handleNext(state, notifier),
                continueLabel: state.currentStep == steps.length - 1 ? 'Submit Invoice' : 'Next',
                nextButtonColor: state.currentStep == steps.length - 1 ? AppColors.success : null,
              ),
            ],
          ),
          if (state.isSubmitting)
            Container(
              color: Colors.black54,
              child: const Center(child: Card(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()))),
            ),
        ],
      ),
    );
  }

  Widget _buildStepContent(TaxInvoiceWizardState state, TaxInvoiceWizardNotifier notifier) {
    final isConversion = state.linkedEstimateId != null;
    if (isConversion) {
      switch (state.currentStep) {
        case 0: return _buildTransportStep(state, notifier);
        case 1: return _buildPreviewStep(state, notifier);
        default: return const SizedBox();
      }
    }
    switch (state.currentStep) {
      case 0: return _buildCustomerStep(state, notifier);
      case 1: return _buildTransportStep(state, notifier);
      case 2: return _buildItemsStep(state, notifier);
      case 3: return _buildPreviewStep(state, notifier);
      default: return const SizedBox();
    }
  }

  Widget _buildCustomerStep(TaxInvoiceWizardState state, TaxInvoiceWizardNotifier notifier) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepHeader(title: '1. BILL TO (CUSTOMER)'),
          const SizedBox(height: 16),
          TextFormField(controller: _customerNameCtrl, decoration: const InputDecoration(labelText: 'Customer Name *'), onChanged: notifier.updateCustomerName),
          const SizedBox(height: 16),
          TextFormField(controller: _addressCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Address *'), onChanged: notifier.updateAddress),
          const SizedBox(height: 16),
          TextFormField(controller: _contactNumberCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contact Number *'), onChanged: notifier.updateContactNumber),
          const SizedBox(height: 16),
          TextFormField(controller: _gstinCtrl, decoration: const InputDecoration(labelText: 'GSTIN'), onChanged: notifier.updateGstinNumber),
        ],
      ),
    );
  }

  Widget _buildTransportStep(TaxInvoiceWizardState state, TaxInvoiceWizardNotifier notifier) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepHeader(title: '2. TRANSPORTATION DETAILS'),
          const SizedBox(height: 16),
          TextFormField(controller: _vehicleNumberCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number'), onChanged: notifier.updateVehicleNumber),
          const SizedBox(height: 16),
          TextFormField(controller: _transportNameCtrl, decoration: const InputDecoration(labelText: 'Transport Name'), onChanged: notifier.updateTransportName),
          const SizedBox(height: 16),
          TextFormField(controller: _lrNumberCtrl, decoration: const InputDecoration(labelText: 'LR Number'), onChanged: notifier.updateLrNumber),
        ],
      ),
    );
  }

  Widget _buildItemsStep(TaxInvoiceWizardState state, TaxInvoiceWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepHeader(title: '3. INVOICE ITEMS'),
        const SizedBox(height: 16),
        if (state.items.isEmpty)
          Container(padding: const EdgeInsets.all(32), child: const Center(child: Text('No items added.')))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return ListTile(
                title: Text(item.itemName),
                subtitle: Text('₹${item.pricePerUnit} x ${item.quantity}'),
                trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => notifier.removeItem(index)),
              );
            },
          ),
        OutlinedButton.icon(onPressed: () => _showAddItemDialog(notifier), icon: const Icon(Icons.add), label: const Text('Add Item')),
      ],
    );
  }

  void _showAddItemDialog(TaxInvoiceWizardNotifier notifier) {
    _itemNameCtrl.clear();
    _itemQtyCtrl.text = '1';
    _itemPriceCtrl.clear();
    _gstPctCtrl.text = '18';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _itemNameCtrl, decoration: const InputDecoration(labelText: 'Item Name *')),
              TextFormField(controller: _itemQtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity *')),
              TextFormField(controller: _itemPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price Per Unit (₹) *')),
              TextFormField(controller: _gstPctCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'GST %')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = _itemNameCtrl.text.trim();
              final qty = double.tryParse(_itemQtyCtrl.text) ?? 0;
              final price = double.tryParse(_itemPriceCtrl.text) ?? 0;
              final gst = double.tryParse(_gstPctCtrl.text) ?? 18;
              if (name.isNotEmpty && qty > 0 && price > 0) {
                notifier.addItem(EstimateItem(itemName: name, quantity: qty, pricePerUnit: price, gstPercentage: gst, taxApplicable: gst > 0));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep(TaxInvoiceWizardState state, TaxInvoiceWizardNotifier notifier) {
    final isConversion = state.linkedEstimateId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeader(title: isConversion ? '2. PREVIEW & VERIFY' : '4. PREVIEW'),
        const SizedBox(height: 16),
        
        // Customer Details Card
        Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BILL TO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const Divider(),
                Text(state.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                if (state.address.isNotEmpty) Text(state.address),
                if (state.contactPerson.isNotEmpty) Text('Contact Person: ${state.contactPerson}'),
                if (state.contactNumber.isNotEmpty) Text('Phone: ${state.contactNumber}'),
                if (state.gstinNumber.isNotEmpty) Text('GSTIN: ${state.gstinNumber}'),
                if (state.placeOfSupply.isNotEmpty) Text('Place of Supply: ${state.placeOfSupply}'),
              ],
            ),
          ),
        ),

        // Transportation Details Card
        Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TRANSPORTATION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const Divider(),
                Text('Vehicle Number: ${state.transportationDetails.vehicleNumber?.isNotEmpty == true ? state.transportationDetails.vehicleNumber : "N/A"}'),
                Text('Transport Name: ${state.transportationDetails.transportName?.isNotEmpty == true ? state.transportationDetails.transportName : "N/A"}'),
                Text('LR Number: ${state.transportationDetails.lrNumber?.isNotEmpty == true ? state.transportationDetails.lrNumber : "N/A"}'),
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
                Text('ITEMS (${state.items.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const Divider(),
                if (state.items.isEmpty)
                  const Text('No items added.', style: TextStyle(fontStyle: FontStyle.italic)),
                ...state.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.w500))),
                      Text('${item.quantity} x ₹${item.pricePerUnit} (GST: ${item.gstPercentage}%)'),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),
        const Text(
          'Invoice totals (including GST) will be auto-calculated by the backend upon submission.',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
