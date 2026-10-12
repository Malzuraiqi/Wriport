import 'package:flutter/material.dart';
import 'package:wriport/core/app_constants.dart';
import 'package:wriport/state/attempt_state.dart';

class AttemptsPill extends StatelessWidget{
  const AttemptsPill({super.key, 
    required this.attemptState,
  });

  final AttemptState attemptState;


  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface, // Adjust if your background isn't white
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(999), // Perfect pill shape
        ),
        child: Text(
          'Attempt ${attemptState.attempts.length} of ${AppConstants.maxAttempts}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary, // Matches the blue text in the figma
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
        ),
      )
    );
  }
}
