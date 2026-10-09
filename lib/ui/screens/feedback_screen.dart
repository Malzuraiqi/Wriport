import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wriport/providers.dart';
import 'package:wriport/ui/widgets/score_card.dart';

class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final attemptState = ref.watch(Providers.attemptControllerProvider);

    // Empty-state guard: the original crashed with StateError when the
    // screen was reached without any feedback in state.
    if (attemptState.feedbacks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Feedback')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: scheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text('No feedback yet',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    final feedback = attemptState.feedbacks.last;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final horizontalPadding = constraints.maxWidth >= 720 ? 32.0 : 16.0;

            final scoreHeader = _ScoreHeader(
              score: feedback.overallScore,
              attemptNumber: attemptState.attempts.length,
            );

            final details = Column(
              children: [
                for (final criteria in feedback.criteria)
                  ScoreCard(
                    title: criteria.name,
                    score: criteria.score,
                    comment: criteria.comment,
                  ),
              ],
            );

            final lists = Column(
              children: [
                _FeedbackListCard(
                  title: 'Strengths',
                  items: feedback.strengths,
                  icon: Icons.check_circle_outline,
                  color: scheme.primary,
                  background: scheme.primaryContainer,
                  foreground: scheme.onPrimaryContainer,
                ),
                const SizedBox(height: 12),
                _FeedbackListCard(
                  title: 'Improvements',
                  items: feedback.improvements,
                  icon: Icons.tips_and_updates_outlined,
                  color: scheme.tertiary,
                  background: scheme.tertiaryContainer,
                  foreground: scheme.onTertiaryContainer,
                ),
              ],
            );

            final actions = FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again'),
            );

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      scoreHeader,
                      const SizedBox(height: 24),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: details),
                            const SizedBox(width: 24),
                            Expanded(child: lists),
                          ],
                        )
                      else ...[
                        details,
                        const SizedBox(height: 20),
                        lists,
                      ],
                      const SizedBox(height: 24),
                      Align(
                        alignment: isWide
                            ? Alignment.centerRight
                            : Alignment.center,
                        child: actions,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.score, required this.attemptNumber});

  final int score;
  final int attemptNumber;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = scoreColor(scheme, score);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: score / 100),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      color: color,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                    Center(
                      child: Text(
                        score.toString(),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Score',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Attempt #$attemptNumber',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    score >= 80
                        ? 'Great work! Your writing hits the mark.'
                        : score >= 60
                            ? 'Solid effort — a few things to polish.'
                            : 'Keep practicing — review the notes below.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackListCard extends StatelessWidget {
  const _FeedbackListCard({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
    required this.background,
    required this.foreground,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 6, color: foreground),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: foreground,
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}