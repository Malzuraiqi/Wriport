import 'package:flutter/material.dart';

/// Live word counter shown above the writing field.
///
/// Gives immediate, semantic feedback while the user types:
/// - below minimum  -> error color + "N more words to reach the minimum"
/// - within range   -> primary color
/// - above maximum  -> warning (tertiary) color + "N words over the limit"
class WordCounter extends StatelessWidget {
  const WordCounter({
    super.key,
    required this.wordCount,
    required this.minWords,
    required this.maxWords,
  });

  final int wordCount;
  final int minWords;
  final int maxWords;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color barColor;
    final String? hint;
    if (wordCount < minWords) {
      barColor = scheme.error;
      hint = '${minWords - wordCount} more words to reach the minimum';
    } else if (wordCount > maxWords) {
      barColor = scheme.tertiary;
      hint = '${wordCount - maxWords} words over the limit';
    } else {
      barColor = scheme.primary;
      hint = null;
    }

    final double progress = (wordCount / (maxWords == 0 ? 1 : maxWords)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$wordCount words',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              'Target: $minWords–$maxWords',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            color: barColor,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(
            hint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: wordCount < minWords ? scheme.error : scheme.tertiary,
                ),
          ),
        ],
      ],
    );
  }
}