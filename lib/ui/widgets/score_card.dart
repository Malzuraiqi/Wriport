import 'package:flutter/material.dart';

/// Semantic color for a 0–100 score, derived from the theme's ColorScheme so
/// it stays harmonious in both light and dark mode.
Color scoreColor(ColorScheme scheme, int score) {
  if (score >= 80) return scheme.primary;
  if (score >= 60) return scheme.secondary;
  return scheme.error;
}

/// A single criterion row: name, animated progress bar(s), score(s) and comment.
class ScoreCard extends StatelessWidget {
  const ScoreCard({
    super.key,
    required this.title,
    required this.score,
    required this.comment,
    this.previousScore,
  });

  final String title;
  final int score;
  final String comment;
  final int? previousScore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPrevious = previousScore != null;
    final color = scoreColor(scheme, score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Title and Comment
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right: Score Pills
            Row(
              children: [
                // Current Score Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$score / 100',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                // Previous Score Pill (Only if there is a previous attempt)
                if (hasPrevious) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$previousScore / 100',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Progress Bars
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Background Track
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // Conditional UI based on having a previous attempt
                if (hasPrevious) ...[
                  // Top Half: Previous Score Bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    height: 6,
                    width: constraints.maxWidth * (previousScore! / 100),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // Bottom Half: Current Score Bar
                  Positioned(
                    top: 6,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      height: 6,
                      width: constraints.maxWidth * (score / 100),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ] else
                  // Single Full-Height Bar if no previous attempt exists
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    height: 12,
                    width: constraints.maxWidth * (score / 100),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}