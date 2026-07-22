import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/estimate_model.dart';
import '../providers/estimate_wizard_provider.dart';
import '../providers/estimates_provider.dart';
import '../widgets/stepper/stepper_progress_bar.dart';
import '../widgets/stepper/step_navigation.dart';
import '../widgets/stepper/step_container.dart';
import '../widgets/stepper/step_header.dart';

class CreateEstimateScreen extends ConsumerStatefulWidget {
  const CreateEstimateScreen({super.key});

  @override
  ConsumerState<CreateEstimateScreen> createState() => _CreateEstimateScreenState();
}

class _CreateEstimateScreenState extends ConsumerState<CreateEstimateScreen> {
  // Customer Step
  final _customerNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _contactNumberCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  
  // Document Info Step
  final _placeOfSupplyCtrl = TextEditingController();

  // Item Dialog
  final _itemNameCtrl = TextEditingController();
  final _hsnSacCtrl = TextEditingController();
  final _itemQtyCtrl = TextEditingController();
  final _itemPriceCtrl = TextEditingController();
  final _gstPctCtrl = TextEditingController(text: '18');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(estimateWizardProvider.notifier).reset();
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
    _itemNameCtrl.dispose();
    _hsnSacCtrl.dispose();
    _itemQtyCtrl.dispose();
    _itemPriceCtrl.dispose();
    _gstPctCtrl.dispose();
    super.dispose();
  }

  void _handleNext(EstimateWizardState state, EstimateWizardNotifier notifier) {
    if (notifier.validateCurrentStep()) {
      notifier.updateStep(state.currentStep + 1);
    } else {
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _handleBack(EstimateWizardState state, EstimateWizardNotifier notifier) {
    if (state.currentStep > 0) {
      notifier.updateStep(state.currentStep - 1);
    }
  }

  void _submit(EstimateWizardNotifier notifier) async {
    final success = await notifier.submitEstimate();
    if (success && mounted) {
      final submitted = ref.read(estimateWizardProvider).submittedEstimate;
      if (submitted != null) {
        final docId = submitted.id;
        notifier.reset();
        // Redirecting to success screen (reusing agreement success or going to details directly)
        // For now let's go straight to details
        context.go('/dashboard');
        context.push('/estimate-details/$docId');
      }
    } else {
      final error = ref.read(estimateWizardProvider).error;
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $error'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(estimateWizardProvider);
    final notifier = ref.read(estimateWizardProvider.notifier);

    final steps = ['Customer', 'Items', 'Preview'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Estimate'),
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
                continueLabel: state.currentStep == steps.length - 1 ? 'Submit Estimate' : 'Next',
                nextButtonColor: state.currentStep == steps.length - 1 ? AppColors.success : null,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Generating Estimate...', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepContent(EstimateWizardState state, EstimateWizardNotifier notifier) {
    switch (state.currentStep) {
      case 0:
        return _buildCustomerStep(state, notifier);
      case 1:
        return _buildItemsStep(state, notifier);
      case 2:
        return _buildPreviewStep(state, notifier);
      default:
        return const SizedBox();
    }
  }

  Widget _buildCustomerStep(EstimateWizardState state, EstimateWizardNotifier notifier) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepHeader(title: '1. CUSTOMER DETAILS'),
          const SizedBox(height: 20),
          TextFormField(
            controller: _customerNameCtrl,
            decoration: const InputDecoration(labelText: 'Customer Name *', prefixIcon: Icon(Icons.business)),
            onChanged: notifier.updateCustomerName,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Complete Address *', prefixIcon: Icon(Icons.location_on)),
            onChanged: notifier.updateAddress,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contactNumberCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Mobile Number *', prefixIcon: Icon(Icons.phone)),
            onChanged: notifier.updateContactNumber,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contactPersonCtrl,
            decoration: const InputDecoration(labelText: 'Contact Person', prefixIcon: Icon(Icons.person)),
            onChanged: notifier.updateContactPerson,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _gstinCtrl,
            decoration: const InputDecoration(labelText: 'GSTIN Number', prefixIcon: Icon(Icons.receipt_long)),
            onChanged: notifier.updateGstinNumber,
          ),
          const SizedBox(height: 32),
          const StepHeader(title: 'DOCUMENT INFO'),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: state.estimateDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) notifier.updateEstimateDate(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(DateFormat('dd-MM-yyyy').format(state.estimateDate), style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _placeOfSupplyCtrl,
            decoration: const InputDecoration(labelText: 'Place of Supply', prefixIcon: Icon(Icons.map)),
            onChanged: notifier.updatePlaceOfSupply,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: state.termsAndConditions,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Terms & Conditions', prefixIcon: Icon(Icons.gavel)),
            onChanged: notifier.updateTermsAndConditions,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsStep(EstimateWizardState state, EstimateWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepHeader(title: '2. ESTIMATE ITEMS'),
        const SizedBox(height: 16),
        if (state.items.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: const Center(child: Text('No items added.', style: TextStyle(color: AppColors.textSecondary))),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.border)),
                child: ListTile(
                  title: Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Qty: ${item.quantity} | Rate: ₹${item.pricePerUnit} | GST: ${item.gstPercentage}%'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () => notifier.removeItem(index),
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _showAddItemDialog(notifier),
          icon: const Icon(Icons.add),
          label: const Text('Add Item'),
        ),
      ],
    );
  }

  void _showAddItemDialog(EstimateWizardNotifier notifier) {
    _itemNameCtrl.clear();
    _hsnSacCtrl.clear();
    _itemQtyCtrl.text = '1';
    _itemPriceCtrl.clear();
    _gstPctCtrl.text = '18';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _itemNameCtrl, decoration: const InputDecoration(labelText: 'Item Name *')),
              const SizedBox(height: 12),
              TextFormField(controller: _hsnSacCtrl, decoration: const InputDecoration(labelText: 'HSN/SAC')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _itemQtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity *'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _itemPriceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price Per Unit (₹) *'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gstPctCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'GST Percentage (%)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = _itemNameCtrl.text.trim();
              final qty = double.tryParse(_itemQtyCtrl.text) ?? 0.0;
              final price = double.tryParse(_itemPriceCtrl.text) ?? 0.0;
              final gst = double.tryParse(_gstPctCtrl.text) ?? 18.0;

              if (name.isEmpty || qty <= 0 || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid input'), backgroundColor: AppColors.error));
                return;
              }

              notifier.addItem(EstimateItem(
                itemName: name,
                hsnSac: _hsnSacCtrl.text.isNotEmpty ? _hsnSacCtrl.text : null,
                quantity: qty,
                pricePerUnit: price,
                gstPercentage: gst,
                taxApplicable: gst > 0,
              ));
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep(EstimateWizardState state, EstimateWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepHeader(title: '3. PREVIEW'),
        const SizedBox(height: 20),
        _buildPreviewItem('Customer', state.customerName, isBold: true),
        _buildPreviewItem('Mobile', state.contactNumber),
        _buildPreviewItem('Address', state.address),
        const Divider(),
        _buildPreviewItem('Total Items', state.items.length.toString(), isBold: true),
        const SizedBox(height: 16),
        const Text('Note: Financial totals and payment QR will be calculated by the server upon submission.', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildPreviewItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }
}
