import 'package:flutter/material.dart';
import 'package:wriport/core/app_constants.dart';

class AttemptsPill extends StatelessWidget {
  const AttemptsPill({
    super.key, 
    required this.displayAttemptNumber, // Pass the exact number directly
  });

  final int displayAttemptNumber;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          // Uses the exact number passed down
          'Attempt $displayAttemptNumber of ${AppConstants.maxAttempts}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
        ),
      ),
    );
  }
}
