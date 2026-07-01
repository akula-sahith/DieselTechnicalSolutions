import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/agreement_model.dart';
import '../providers/agreement_wizard_provider.dart';
import '../providers/agreements_provider.dart';
import '../widgets/signature_pad.dart';
import '../widgets/stepper/stepper_progress_bar.dart';
import '../widgets/stepper/step_navigation.dart';
import '../widgets/stepper/step_container.dart';
import '../widgets/stepper/step_header.dart';

class CreateAgreementScreen extends ConsumerStatefulWidget {
  final String? draftId;
  const CreateAgreementScreen({super.key, this.draftId});

  @override
  ConsumerState<CreateAgreementScreen> createState() => _CreateAgreementScreenState();
}

class _CreateAgreementScreenState extends ConsumerState<CreateAgreementScreen> {
  // Step 2 Controllers
  final _customerNameCtrl = TextEditingController();
  final _completeAddressCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _mobileNumberCtrl = TextEditingController();

  // Item Add Controllers (Dialog)
  final _itemDescCtrl = TextEditingController();
  final _itemQtyCtrl = TextEditingController();
  final _itemRateCtrl = TextEditingController();

  // GST controller
  final _gstPercentageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Reset state first or load draft synchronously if draftId is provided
      if (widget.draftId != null) {
        try {
          final drafts = ref.read(agreementsProvider).drafts;
          final draft = drafts.firstWhere(
            (element) => element.id == widget.draftId || element.offerNumber == widget.draftId,
          );
          ref.read(agreementWizardProvider.notifier).loadFromAgreement(draft);
        } catch (e) {
          print("Failed to load draft: $e");
        }
      } else {
        ref.read(agreementWizardProvider.notifier).reset();
      }

      // 2. Read state and initialize controller values synchronously
      final state = ref.read(agreementWizardProvider);
      _customerNameCtrl.text = state.customerName;
      _completeAddressCtrl.text = state.completeAddress;
      _contactPersonCtrl.text = state.contactPerson;
      _mobileNumberCtrl.text = state.mobileNumber;
      _gstPercentageCtrl.text = state.gstPercentage.toString();
    });
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _completeAddressCtrl.dispose();
    _contactPersonCtrl.dispose();
    _mobileNumberCtrl.dispose();
    _itemDescCtrl.dispose();
    _itemQtyCtrl.dispose();
    _itemRateCtrl.dispose();
    _gstPercentageCtrl.dispose();
    super.dispose();
  }

  void _handleNext(AgreementWizardState state, AgreementWizardNotifier notifier) {
    if (notifier.validateCurrentStep(context)) {
      notifier.updateStep(state.currentStep + 1);
    } else {
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _handleBack(AgreementWizardState state, AgreementWizardNotifier notifier) {
    if (state.currentStep > 0) {
      notifier.updateStep(state.currentStep - 1);
    }
  }

  void _submit(AgreementWizardNotifier notifier, String type) async {
    final success = await notifier.submitAgreement(type);
    if (success && mounted) {
      final submitted = ref.read(agreementWizardProvider).submittedAgreement;
      if (submitted != null) {
        final docId = submitted.id;
        // Clear wizard state on success
        notifier.reset();
        context.go('/agreement-success/$docId');
      }
    } else {
      final error = ref.read(agreementWizardProvider).error;
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $error'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agreementWizardProvider);
    final notifier = ref.read(agreementWizardProvider.notifier);

    final steps = state.documentType == 'Quotation'
        ? ['Doc Info', 'Customer', 'Items', 'GST', 'Preview']
        : ['Doc Info', 'Customer', 'Items', 'GST', 'Signature', 'Preview'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Agreement / Quotation'),
        actions: [
          TextButton(
            onPressed: () async {
              await notifier.saveAsDraft();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Proposal saved as local draft!'), backgroundColor: AppColors.success),
                );
                context.pop();
              }
            },
            child: const Text('Save Draft', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Stepper progress indicator
              StepperProgressBar(steps: steps, currentStep: state.currentStep),

              Expanded(
                child: StepContainer(
                  child: _buildStepContent(state, notifier),
                ),
              ),

              // Step navigation buttons
              StepNavigation(
                currentStep: state.currentStep,
                totalSteps: steps.length,
                onBack: () => _handleBack(state, notifier),
                onNext: state.currentStep == steps.length - 1 
                    ? () => _submit(notifier, state.documentType)
                    : () => _handleNext(state, notifier),
                continueLabel: state.currentStep == steps.length - 1 ? 'Submit ${state.documentType}' : 'Next',
                nextButtonColor: state.currentStep == steps.length - 1
                    ? (state.documentType == 'Agreement' ? AppColors.success : AppColors.secondary)
                    : null,
              ),
            ],
          ),

          // Loading overlay
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
                        Text(
                          'Submitting Agreement...',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Saving details & signature...',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
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

  Widget _buildStepContent(AgreementWizardState state, AgreementWizardNotifier notifier) {
    final isQuotation = state.documentType == 'Quotation';
    switch (state.currentStep) {
      case 0:
        return _buildDocInfoStep(state, notifier);
      case 1:
        return _buildCustomerStep(state, notifier);
      case 2:
        return _buildItemsStep(state, notifier);
      case 3:
        return _buildGstStep(state, notifier);
      case 4:
        return isQuotation ? _buildPreviewStep(state, notifier) : _buildSignatureStep(state, notifier);
      case 5:
        return isQuotation ? const SizedBox() : _buildPreviewStep(state, notifier);
      default:
        return const SizedBox();
    }
  }

  Widget _buildDocInfoStep(AgreementWizardState state, AgreementWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepHeader(title: '1. DOCUMENT TYPE & INFORMATION'),
        const SizedBox(height: 20),
        
        // Document Type Radio Buttons
        const Text(
          'Document Type *',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Agreement')),
                selected: state.documentType == 'Agreement',
                onSelected: (selected) {
                  if (selected) notifier.updateDocumentType('Agreement');
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: state.documentType == 'Agreement' ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Quotation')),
                selected: state.documentType == 'Quotation',
                onSelected: (selected) {
                  if (selected) notifier.updateDocumentType('Quotation');
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: state.documentType == 'Quotation' ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Offer Number (Read Only)
        TextFormField(
          initialValue: 'GPS/AMC/XX (Auto-generated by server)',
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Offer Number',
            prefixIcon: Icon(Icons.confirmation_number_outlined),
            filled: true,
            fillColor: AppColors.background,
          ),
        ),
        const SizedBox(height: 16),

        // Date Picker
        const Text(
          'Document Date *',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: state.date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              notifier.updateDate(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd-MM-yyyy').format(state.date),
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerStep(AgreementWizardState state, AgreementWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepHeader(title: '2. CUSTOMER DETAILS'),
        const SizedBox(height: 20),
        TextFormField(
          controller: _customerNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Customer Name *',
            prefixIcon: Icon(Icons.business),
          ),
          onChanged: notifier.updateCustomerName,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _completeAddressCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Complete Address *',
            prefixIcon: Icon(Icons.location_on),
          ),
          onChanged: notifier.updateCompleteAddress,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _contactPersonCtrl,
          decoration: const InputDecoration(
            labelText: 'Contact Person *',
            prefixIcon: Icon(Icons.person),
          ),
          onChanged: notifier.updateContactPerson,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _mobileNumberCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Mobile Number *',
            prefixIcon: Icon(Icons.phone),
          ),
          onChanged: notifier.updateMobileNumber,
        ),
      ],
    );
  }

  Widget _buildItemsStep(AgreementWizardState state, AgreementWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(child: StepHeader(title: '3. DESCRIPTION ITEMS')),
          ],
        ),
        const SizedBox(height: 16),

        // Items List
        if (state.descriptionItems.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No items added yet. Click "Add Item" below.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.descriptionItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = state.descriptionItems[index];
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Qty: ${item.quantity} | Rate: ₹${item.rate.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹${item.subTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: () => notifier.removeDescriptionItem(index),
                      ),
                    ],
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

  void _showAddItemDialog(AgreementWizardNotifier notifier) {
    _itemDescCtrl.clear();
    _itemQtyCtrl.clear();
    _itemRateCtrl.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Description Item', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _itemDescCtrl,
                  decoration: const InputDecoration(labelText: 'Description / Item *'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _itemQtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Quantity *'),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _itemRateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Rate / Unit *'),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
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
                final desc = _itemDescCtrl.text.trim();
                final qty = double.tryParse(_itemQtyCtrl.text) ?? 0.0;
                final rate = double.tryParse(_itemRateCtrl.text) ?? 0.0;

                if (desc.isEmpty || qty <= 0 || rate <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid description, quantity and rate.'), backgroundColor: AppColors.error),
                  );
                  return;
                }

                notifier.addDescriptionItem(
                  DescriptionItem(
                    description: desc,
                    quantity: qty,
                    rate: rate,
                    subTotal: qty * rate,
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGstStep(AgreementWizardState state, AgreementWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepHeader(title: '4. GST SETTINGS'),
        const SizedBox(height: 20),

        // GST Switch
        SwitchListTile(
          title: const Text('Apply GST', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Toggle to apply GST percentage to the grand total'),
          value: state.gstRequired,
          activeColor: AppColors.accent,
          onChanged: notifier.updateGstRequired,
        ),
        const SizedBox(height: 16),

        // GST Percentage input
        if (state.gstRequired) ...[
          TextFormField(
            controller: _gstPercentageCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'GST Percentage (%) *',
              prefixIcon: Icon(Icons.percent),
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val) ?? 0.0;
              notifier.updateGstPercentage(parsed);
            },
          ),
          const SizedBox(height: 24),
        ],

        // Live Financial Summary
        const Text('Financial Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Total Before GST', '₹${state.totalBeforeGST.toStringAsFixed(2)}'),
              const Divider(height: 20),
              _buildSummaryRow(
                'GST (${state.gstRequired ? state.gstPercentage.toStringAsFixed(1) : 0.0}%)',
                '₹${state.gstAmount.toStringAsFixed(2)}',
              ),
              const Divider(height: 20, thickness: 1.5),
              _buildSummaryRow(
                'Grand Total',
                '₹${state.grandTotal.toStringAsFixed(2)}',
                isGrandTotal: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isGrandTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isGrandTotal ? 16 : 14,
            fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.normal,
            color: isGrandTotal ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isGrandTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isGrandTotal ? AppColors.accent : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureStep(AgreementWizardState state, AgreementWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepHeader(title: '5. CUSTOMER SIGN-OFF'),
        const SizedBox(height: 20),
        const Text(
          'Customer Signature *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Provide the signature of the customer representative below. Technician signature is default.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        SignaturePad(
          onSignatureChanged: notifier.updateCustomerSignature,
          placeholderText: 'Customer signs here',
        ),
      ],
    );
  }

  Widget _buildPreviewStep(AgreementWizardState state, AgreementWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StepHeader(title: '6. PREVIEW & SUBMIT'),
        const SizedBox(height: 20),

        // Section: Document details
        _buildPreviewSectionTitle('Document Info'),
        _buildPreviewItem('Type', state.documentType),
        _buildPreviewItem('Date', DateFormat('dd-MM-yyyy').format(state.date)),
        const Divider(),

        // Section: Customer details
        _buildPreviewSectionTitle('Customer Details'),
        _buildPreviewItem('Customer Name', state.customerName),
        _buildPreviewItem('Address', state.completeAddress),
        _buildPreviewItem('Contact Person', state.contactPerson),
        _buildPreviewItem('Mobile Number', state.mobileNumber),
        const Divider(),

        // Section: Items
        _buildPreviewSectionTitle('Description Items'),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.descriptionItems.length,
          itemBuilder: (context, index) {
            final item = state.descriptionItems[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${index + 1}. ${item.description}', style: const TextStyle(fontSize: 13))),
                  Text(
                    '${item.quantity} x ₹${item.rate.toStringAsFixed(2)} = ₹${item.subTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          },
        ),
        const Divider(),

        // Totals
        _buildPreviewItem('Total Before GST', '₹${state.totalBeforeGST.toStringAsFixed(2)}'),
        _buildPreviewItem('GST Amount', '₹${state.gstAmount.toStringAsFixed(2)}'),
        _buildPreviewItem('Grand Total', '₹${state.grandTotal.toStringAsFixed(2)}', isBold: true),
        const SizedBox(height: 24),

      ],
    );
  }

  Widget _buildPreviewSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
