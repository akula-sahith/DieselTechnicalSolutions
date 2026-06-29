import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../providers/report_wizard_provider.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  const CreateReportScreen({super.key});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _imagePicker = ImagePicker();
  
  // Controllers for text fields to keep sync
  final _jobRefCtrl = TextEditingController();
  final _customerNameCtrl = TextEditingController();
  final _siteLocationCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _contactNumberCtrl = TextEditingController();
  
  final _genMakeModelCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _engSerialCtrl = TextEditingController();
  final _altSerialCtrl = TextEditingController();
  final _hourMeterCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _batteryVoltCtrl = TextEditingController();

  final _observationsCtrl = TextEditingController();
  final _nextHoursCtrl = TextEditingController();

  final _techNameCtrl = TextEditingController();
  final _customerRepNameCtrl = TextEditingController();



  @override
  void initState() {
    super.initState();

    // Set initial text values after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(reportWizardProvider);
      _jobRefCtrl.text = state.jobRef;
      _customerNameCtrl.text = state.customerName;
      _siteLocationCtrl.text = state.siteLocation;
      _contactPersonCtrl.text = state.contactPerson;
      _contactNumberCtrl.text = state.contactNumber;

      _genMakeModelCtrl.text = state.generatorMakeModel;
      _capacityCtrl.text = state.capacity;
      _engSerialCtrl.text = state.engineSerialNo;
      _altSerialCtrl.text = state.alternatorSerialNo;
      _hourMeterCtrl.text = state.hourMeter;
      _hoursCtrl.text = state.hours?.toString() ?? '';
      _batteryVoltCtrl.text = state.batteryStatusVolt;

      _observationsCtrl.text = state.observations;
      _nextHoursCtrl.text = state.nextServiceDueHours?.toString() ?? '';

      _techNameCtrl.text = state.technicianName;
      _customerRepNameCtrl.text = state.customerRepresentativeName;
    });
  }

  @override
  void dispose() {
    _jobRefCtrl.dispose();
    _customerNameCtrl.dispose();
    _siteLocationCtrl.dispose();
    _contactPersonCtrl.dispose();
    _contactNumberCtrl.dispose();
    _genMakeModelCtrl.dispose();
    _capacityCtrl.dispose();
    _engSerialCtrl.dispose();
    _altSerialCtrl.dispose();
    _hourMeterCtrl.dispose();
    _hoursCtrl.dispose();
    _batteryVoltCtrl.dispose();
    _observationsCtrl.dispose();
    _nextHoursCtrl.dispose();
    _techNameCtrl.dispose();
    _customerRepNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _captureCustomerPhoto() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1024,
      );
      if (photo != null) {
        ref.read(reportWizardProvider.notifier).updateCustomerPhoto(File(photo.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture photo: $e'), backgroundColor: AppColors.error),
      );
    }
  }



  void _handleNext(ReportWizardState state, ReportWizardNotifier notifier) {
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

  void _handleBack(ReportWizardState state, ReportWizardNotifier notifier) {
    if (state.currentStep > 0) {
      notifier.updateStep(state.currentStep - 1);
    }
  }

  void _submit(ReportWizardNotifier notifier) async {
    if (!notifier.validateCurrentStep(context)) {
      final error = ref.read(reportWizardProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    final success = await notifier.submitReport();
    if (success && mounted) {
      final submitted = ref.read(reportWizardProvider).submittedReport;
      if (submitted != null) {
        context.go('/report-success/${submitted.id}');
      }
    } else {
      final error = ref.read(reportWizardProvider).error;
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $error'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportWizardProvider);
    final notifier = ref.read(reportWizardProvider.notifier);

    final steps = ['Customer', 'Equipment', 'Checklist', 'Parts', 'Remarks', 'Authorization'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Service Report'),
        actions: [
          TextButton(
            onPressed: () async {
              await notifier.saveAsDraft();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report saved as local draft!'), backgroundColor: AppColors.success),
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
              // Custom Header Stepper Progress bar
              _buildStepProgressIndicator(steps, state.currentStep),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: _buildStepContent(state, notifier),
                    ),
                  ),
                ),
              ),

              // Bottom Navigation Actions
              _buildBottomActionButtons(state, notifier),
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
                          'Submitting Report...',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Saving report attachments...',
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

  Widget _buildStepProgressIndicator(List<String> steps, int currentStep) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(steps.length, (index) {
          final isCompleted = index < currentStep;
          final isActive = index == currentStep;
          return Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.success
                      : isActive
                          ? AppColors.accent
                          : Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: isActive ? Border.all(color: Colors.white, width: 2) : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive || isCompleted ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[index],
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white60,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(ReportWizardState state, ReportWizardNotifier notifier) {
    switch (state.currentStep) {
      case 0:
        return _buildCustomerStep(state, notifier);
      case 1:
        return _buildEquipmentStep(state, notifier);
      case 2:
        return _buildChecklistStep(state, notifier);
      case 3:
        return _buildPartsStep(state, notifier);
      case 4:
        return _buildRemarksStep(state, notifier);
      case 5:
        return _buildAuthorizationStep(state, notifier);
      default:
        return const SizedBox();
    }
  }

  Widget _buildCustomerStep(ReportWizardState state, ReportWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('1. SERVICE & CUSTOMER DETAILS'),
        const SizedBox(height: 20),
        TextFormField(
          controller: _jobRefCtrl,
          decoration: const InputDecoration(
            labelText: 'Job / Ticket Ref *',
            prefixIcon: Icon(Icons.receipt_long),
          ),
          onChanged: notifier.updateJobRef,
        ),
        const SizedBox(height: 16),
        _buildDateTimePicker(state, notifier),
        const SizedBox(height: 16),
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
          controller: _siteLocationCtrl,
          decoration: const InputDecoration(
            labelText: 'Site ID / Location',
            prefixIcon: Icon(Icons.location_on),
          ),
          onChanged: notifier.updateSiteLocation,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _contactPersonCtrl,
          decoration: const InputDecoration(
            labelText: 'Contact Person',
            prefixIcon: Icon(Icons.person),
          ),
          onChanged: notifier.updateContactPerson,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _contactNumberCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Contact Number',
            prefixIcon: Icon(Icons.phone),
          ),
          onChanged: notifier.updateContactNumber,
        ),
      ],
    );
  }

  Widget _buildDateTimePicker(ReportWizardState state, ReportWizardNotifier notifier) {
    final formattedDate = DateFormat('dd MMMM yyyy, hh:mm a').format(state.dateTime);
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: state.dateTime,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null && mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(state.dateTime),
          );
          if (time != null) {
            final finalDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
            notifier.updateDateTime(finalDateTime);
          }
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date & Time *',
          prefixIcon: Icon(Icons.calendar_month),
        ),
        child: Text(
          formattedDate,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildEquipmentStep(ReportWizardState state, ReportWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('2. EQUIPMENT & GENERATOR DETAILS'),
        const SizedBox(height: 20),
        TextFormField(
          controller: _genMakeModelCtrl,
          decoration: const InputDecoration(
            labelText: 'Generator Make / Model',
            prefixIcon: Icon(Icons.precision_manufacturing),
          ),
          onChanged: notifier.updateGeneratorMakeModel,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _capacityCtrl,
          decoration: const InputDecoration(
            labelText: 'Capacity (kVA / kW)',
            prefixIcon: Icon(Icons.bolt),
          ),
          onChanged: notifier.updateCapacity,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _engSerialCtrl,
          decoration: const InputDecoration(
            labelText: 'Engine Serial No',
            prefixIcon: Icon(Icons.tag),
          ),
          onChanged: notifier.updateEngineSerialNo,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _altSerialCtrl,
          decoration: const InputDecoration(
            labelText: 'Alternator Serial No',
            prefixIcon: Icon(Icons.tag),
          ),
          onChanged: notifier.updateAlternatorSerialNo,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _hourMeterCtrl,
          decoration: const InputDecoration(
            labelText: 'Hour Meter',
            prefixIcon: Icon(Icons.speed),
          ),
          onChanged: notifier.updateHourMeter,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _hoursCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Hours',
            prefixIcon: Icon(Icons.hourglass_empty),
          ),
          onChanged: (val) {
            notifier.updateHours(int.tryParse(val));
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _batteryVoltCtrl,
          decoration: const InputDecoration(
            labelText: 'Battery Status Volt',
            prefixIcon: Icon(Icons.battery_charging_full),
          ),
          onChanged: notifier.updateBatteryStatusVolt,
        ),
      ],
    );
  }

  Widget _buildChecklistStep(ReportWizardState state, ReportWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('3. SERVICE CHECKLIST & STATUS'),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.serviceChecklist.length,
          itemBuilder: (context, index) {
            final item = state.serviceChecklist[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.parameter,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChecklistStatusButton(
                        text: 'OK',
                        selectedColor: AppColors.success,
                        isSelected: item.status == 'ok',
                        onTap: () => notifier.updateChecklistItem(item.parameter, 'ok'),
                      ),
                      const SizedBox(width: 10),
                      _buildChecklistStatusButton(
                        text: 'Req',
                        selectedColor: AppColors.primary,
                        isSelected: item.status == 'req',
                        onTap: () => notifier.updateChecklistItem(item.parameter, 'req'),
                      ),
                      const SizedBox(width: 10),
                      _buildChecklistStatusButton(
                        text: 'N/A',
                        selectedColor: AppColors.textLight,
                        isSelected: item.status == 'n/a',
                        onTap: () => notifier.updateChecklistItem(item.parameter, 'n/a'),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.border),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChecklistStatusButton({
    required String text,
    required Color selectedColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? selectedColor : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPartsStep(ReportWizardState state, ReportWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildSectionHeader('4. PARTS REPLACED'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _showAddPartDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Part', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (state.partsUsed.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, style: BorderStyle.none),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No parts replaced or consumables used.',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
          )
        else
          Column(
            children: [
              // Table Headers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: const [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Part Description / Item',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Qty / Ltr',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(width: 48), // matching delete button width
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              
              // Parts List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.partsUsed.length,
                itemBuilder: (context, index) {
                  final part = state.partsUsed[index];
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                part.partDescription,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                part.qty,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                              onPressed: () => notifier.removePart(index),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                    ],
                  );
                },
              ),
            ],
          ),
      ],
    );
  }

  void _showAddPartDialog() {
    final partDescCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Part Replaced'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: partDescCtrl,
                decoration: const InputDecoration(
                  labelText: 'Part Description / Item *',
                  hintText: 'e.g. Engine Oil (15W40)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Quantity / Liters *',
                  hintText: 'e.g. 5 Ltr or 1',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (partDescCtrl.text.trim().isNotEmpty && qtyCtrl.text.trim().isNotEmpty) {
                  ref.read(reportWizardProvider.notifier).addPart(
                        partDescCtrl.text.trim(),
                        qtyCtrl.text.trim(),
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRemarksStep(ReportWizardState state, ReportWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('5. REMARKS & ACTION PLAN'),
        const SizedBox(height: 20),
        TextFormField(
          controller: _observationsCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Observations / Remarks',
            hintText: 'Enter field observations, repairs, status check remarks...',
            alignLabelWithHint: true,
          ),
          onChanged: notifier.updateObservations,
        ),
        const SizedBox(height: 16),
        _buildNextDueDateField(state, notifier),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nextHoursCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Next Service Due Hours',
            prefixIcon: Icon(Icons.hourglass_bottom),
          ),
          onChanged: (val) {
            notifier.updateNextServiceDueHours(int.tryParse(val));
          },
        ),
      ],
    );
  }

  Widget _buildNextDueDateField(ReportWizardState state, ReportWizardNotifier notifier) {
    final formatted = state.nextServiceDueDate != null
        ? DateFormat('dd MMMM yyyy').format(state.nextServiceDueDate!)
        : 'Select Date';
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: state.nextServiceDueDate ?? DateTime.now().add(const Duration(days: 180)),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) {
          notifier.updateNextServiceDueDate(date);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Next Service Due Date',
          prefixIcon: Icon(Icons.event),
        ),
        child: Text(
          formatted,
          style: TextStyle(fontSize: 16, color: state.nextServiceDueDate != null ? AppColors.textPrimary : AppColors.textLight),
        ),
      ),
    );
  }

  Widget _buildAuthorizationStep(ReportWizardState state, ReportWizardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('6. AUTHORIZATION & SIGN-OFF'),
        const SizedBox(height: 20),
        
        // Technician Name
        TextFormField(
          controller: _techNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Technician Name *',
            prefixIcon: Icon(Icons.person),
          ),
          onChanged: notifier.updateTechnicianName,
        ),
        const SizedBox(height: 16),

        // Signature Title
        const Text(
          'Technician Signature',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
        ),
        const SizedBox(height: 8),

        // Default Signature Image from Cloudinary
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              kDefaultTechnicianSignatureUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  height: 120,
                  child: Center(
                    child: Text('Failed to load signature', style: TextStyle(color: AppColors.textLight)),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Customer Rep Name
        TextFormField(
          controller: _customerRepNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Customer Representative Name *',
            prefixIcon: Icon(Icons.badge),
          ),
          onChanged: notifier.updateCustomerRepresentativeName,
        ),
        const SizedBox(height: 20),

        // Customer Photo
        const Text(
          'Customer Photo *',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
        ),
        const SizedBox(height: 8),
        
        // Photo Capture Box
        Container(
          height: 180,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
          ),
          child: state.customerPhotoFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(state.customerPhotoFile!, fit: BoxFit.cover),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: _captureCustomerPhoto,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 48, color: AppColors.textLight.withOpacity(0.8)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _captureCustomerPhoto,
                        child: const Text('Capture Photo'),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBottomActionButtons(ReportWizardState state, ReportWizardNotifier notifier) {
    final isLastStep = state.currentStep == 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (state.currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleBack(state, notifier),
                child: const Text('Back'),
              ),
            ),
          if (state.currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLastStep ? () => _submit(notifier) : () => _handleNext(state, notifier),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastStep ? AppColors.success : AppColors.primary,
              ),
              child: Text(isLastStep ? 'Submit Report' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
