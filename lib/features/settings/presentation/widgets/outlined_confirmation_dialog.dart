import 'package:flutter/material.dart';

import 'package:anti/features/home/presentation/widgets/outlined_action_button.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';

class OutlinedConfirmationDialog extends StatelessWidget {
  const OutlinedConfirmationDialog({
    super.key,
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  final String title;
  final String description;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: OutlinedSurface(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            if (secondaryLabel != null && onSecondaryPressed != null)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedActionButton(
                      label: secondaryLabel!,
                      onPressed: onSecondaryPressed,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedActionButton(
                      label: primaryLabel,
                      onPressed: onPrimaryPressed,
                      textColor: Colors.white,
                      borderColor: Colors.black,
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedActionButton(
                  label: primaryLabel,
                  onPressed: onPrimaryPressed,
                  textColor: Colors.white,
                  borderColor: Colors.black,
                  backgroundColor: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
