import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StepNavigation extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String? continueLabel;
  final String? backLabel;
  final Color? nextButtonColor;

  const StepNavigation({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.onBack,
    this.onNext,
    this.continueLabel,
    this.backLabel,
    this.nextButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == totalSteps - 1;
    final isFirstStep = currentStep == 0;

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
          if (!isFirstStep)
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(backLabel ?? 'Back'),
              ),
            ),
          if (!isFirstStep) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: nextButtonColor ?? (isLastStep ? AppColors.success : AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(continueLabel ?? (isLastStep ? 'Submit' : 'Next')),
            ),
          ),
        ],
      ),
    );
  }
}
