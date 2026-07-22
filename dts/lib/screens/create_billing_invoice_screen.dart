import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../models/billing_invoice_model.dart';
import '../providers/billing_invoice_wizard_provider.dart';
import '../widgets/stepper/stepper_progress_bar.dart';
import '../widgets/stepper/step_navigation.dart';
import '../widgets/stepper/step_container.dart';
import '../widgets/stepper/step_header.dart';

class CreateBillingInvoiceScreen extends ConsumerStatefulWidget {
  const CreateBillingInvoiceScreen({super.key});

  @override
  ConsumerState<CreateBillingInvoiceScreen> createState() => _CreateBillingInvoiceScreenState();
}

class _CreateBillingInvoiceScreenState extends ConsumerState<CreateBillingInvoiceScreen> {
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
  final _hsnSacCtrl = TextEditingController();
  final _itemQtyCtrl = TextEditingController();
  final _itemPriceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(billingInvoiceWizardProvider.notifier).reset();
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
    _hsnSacCtrl.dispose();
    _itemQtyCtrl.dispose();
    _itemPriceCtrl.dispose();
    super.dispose();
  }

  void _handleNext(BillingInvoiceWizardState state, BillingInvoiceWizardNotifier notifier) {
    if (notifier.validateCurrentStep()) {
      notifier.updateStep(state.currentStep + 1);
    } else {
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!), backgroundColor: AppColors.error));
      }
    }
  }

  void _handleBack(BillingInvoiceWizardState state, BillingInvoiceWizardNotifier notifier) {
    if (state.currentStep > 0) notifier.updateStep(state.currentStep - 1);
  }

  void _submit(BillingInvoiceWizardNotifier notifier) async {
    final success = await notifier.submitInvoice();
    if (success && mounted) {
      final submitted = ref.read(billingInvoiceWizardProvider).submittedInvoice;
      if (submitted != null) {
        final docId = submitted.id;
        notifier.reset();
        context.go('/dashboard');
        context.push('/billing-invoice-details/$docId', extra: submitted);
      }
    } else {
      final error = ref.read(billingInvoiceWizardProvider).error;
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $error'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingInvoiceWizardProvider);
    final notifier = ref.read(billingInvoiceWizardProvider.notifier);
    final steps = ['Customer', 'Transport', 'Items', 'Preview'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Billing Invoice')),
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

  Widget _buildStepContent(BillingInvoiceWizardState state, BillingInvoiceWizardNotifier notifier) {
    switch (state.currentStep) {
      case 0: return _buildCustomerStep(state, notifier);
      case 1: return _buildTransportStep(state, notifier);
      case 2: return _buildItemsStep(state, notifier);
      case 3: return _buildPreviewStep(state, notifier);
      default: return const SizedBox();
    }
  }

  Widget _buildCustomerStep(BillingInvoiceWizardState state, BillingInvoiceWizardNotifier notifier) {
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
          TextFormField(controller: _gstinCtrl, decoration: const InputDecoration(labelText: 'GSTIN (Optional)'), onChanged: notifier.updateGstinNumber),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: state.termsAndConditions,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Terms & Conditions'),
            onChanged: notifier.updateTermsAndConditions,
          ),
        ],
      ),
    );
  }

  Widget _buildTransportStep(BillingInvoiceWizardState state, BillingInvoiceWizardNotifier notifier) {
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

  Widget _buildItemsStep(BillingInvoiceWizardState state, BillingInvoiceWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepHeader(title: '3. INVOICE ITEMS (NO GST)'),
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

  void _showAddItemDialog(BillingInvoiceWizardNotifier notifier) {
    _itemNameCtrl.clear();
    _hsnSacCtrl.clear();
    _itemQtyCtrl.text = '1';
    _itemPriceCtrl.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _itemNameCtrl, decoration: const InputDecoration(labelText: 'Item Name *')),
              TextFormField(controller: _hsnSacCtrl, decoration: const InputDecoration(labelText: 'HSN/SAC')),
              TextFormField(controller: _itemQtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity *')),
              TextFormField(controller: _itemPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price Per Unit (₹) *')),
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
              if (name.isNotEmpty && qty > 0 && price > 0) {
                notifier.addItem(BillingItem(itemName: name, hsnSac: _hsnSacCtrl.text.trim().isNotEmpty ? _hsnSacCtrl.text.trim() : null, quantity: qty, pricePerUnit: price));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep(BillingInvoiceWizardState state, BillingInvoiceWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepHeader(title: '4. PREVIEW'),
        const SizedBox(height: 16),
        
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
                if (state.contactNumber.isNotEmpty) Text('Phone: ${state.contactNumber}'),
              ],
            ),
          ),
        ),

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
                      Text('${item.quantity} x ₹${item.pricePerUnit}'),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
