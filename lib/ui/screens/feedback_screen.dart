import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wriport/core/app_constants.dart';
import 'package:wriport/providers.dart';
import 'package:wriport/router.dart';
import 'package:wriport/state/attempt_state.dart';
import 'package:wriport/ui/widgets/attempts_pill.dart';
import 'package:wriport/ui/widgets/feedback_list_card.dart';
import 'package:wriport/ui/widgets/score_card.dart';

class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final attemptState = ref.watch(Providers.attemptControllerProvider);

    // No empty-state fallback here: the /feedback route redirects to /home
    // when there is no feedback in state, so this screen only ever builds
    // with feedback present.
    final feedback = attemptState.latestFeedback;
    final prevFeedback = attemptState.previousFeedback;

    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final horizontalPadding = constraints.maxWidth >= 720 ? 32.0 : 16.0;

            final scoreHeader = _ScoreHeader(
              score: feedback.overallScore,
              attemptNumber: attemptState.attempts.length,
              previousScore: prevFeedback?.overallScore,
            );

            final hasPrevious = prevFeedback != null;

            final details = Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant
                      .withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          hasPrevious ? 'Rubric comparison' : 'Rubric criteria',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (hasPrevious)
                          Text(
                            'Current vs previous attempt',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    for (int i = 0; i < feedback.criteria.length; i++) ...[
                      ScoreCard(
                        title: feedback.criteria[i].criterion.label,
                        score: feedback.criteria[i].score,
                        comment: feedback.criteria[i].comment,
                        previousScore: () {
                          if (!hasPrevious) return null;
                          for (final prev in prevFeedback.criteria) {
                            if (prev.criterion.id ==
                                feedback.criteria[i].criterion.id) {
                              return prev.score;
                            }
                          }
                          return null;
                        }(),
                      ),
                      if (i < feedback.criteria.length - 1)
                        const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            );

            final lists = Column(
              children: [
                FeedbackListCard(
                  title: 'Strengths',
                  items: feedback.strengths,
                  icon: Icons.check_circle_outline,
                  color: scheme.primary,
                  background: scheme.primaryContainer,
                  foreground: scheme.onPrimaryContainer,
                ),
                const SizedBox(height: 12),
                FeedbackListCard(
                  title: 'Improvements',
                  items: feedback.improvements,
                  icon: Icons.tips_and_updates_outlined,
                  color: scheme.tertiary,
                  background: scheme.tertiaryContainer,
                  foreground: scheme.onTertiaryContainer,
                ),
              ],
            );

            final tryagainButton = FilledButton.icon(
              // Pops back to the writing screen, which is still alive
              // underneath and keeps the typed text.
              onPressed: () => context.pop(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again'),
            );

            final restartButton = FilledButton.icon(
              // Same result the old popUntil('/challenges') name-trick gave,
              // but explicit: go to this challenge's category list,
              // replacing the stack.
              onPressed: () {
                final challenge = ref.read(
                  Providers.challengeProvider(
                    attemptState.attempts.last.challengeId,
                  ),
                );
                context.go(
                  challenge != null
                      ? AppRouter.challengeList(challenge.category)
                      : AppRouter.home,
                );
              },
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to challenges'),
            );

            // Save-failure banner with retry
            Widget? saveBanner;
            if (attemptState.saveStatus == SaveStatus.failed) {
              saveBanner = Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off, color: scheme.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Could not save this attempt. Your feedback is still shown above.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onErrorContainer,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: () {
                        final challenge = ref.read(
                          Providers.challengeProvider(
                            attemptState.attempts.last.challengeId,
                          ),
                        );
                        if (challenge != null) {
                          ref
                              .read(Providers.attemptControllerProvider.notifier)
                              .retrySave(challenge);
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (attemptState.saveStatus == SaveStatus.saving) {
              saveBanner = Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Saving to history…',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              );
            }

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
                      if (saveBanner != null) saveBanner,
                      AttemptsPill(
                        displayAttemptNumber: attemptState.attempts.length,
                      ),
                      const SizedBox(height: 24),
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
                        child: Column(
                          children: [
                            if (attemptState.canAttempt) tryagainButton,
                            const SizedBox(height: 12),
                            restartButton,
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => context.push(AppRouter.history),
                              icon: const Icon(Icons.history, size: 18),
                              label: const Text('View history'),
                            ),
                            SizedBox(height: 10),
                            Text(
                              attemptState.attempts.length >=
                                      AppConstants.maxAttempts
                                  ? 'max attempts reached'
                                  : '',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
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
  const _ScoreHeader({
    required this.score,
    required this.attemptNumber,
    this.previousScore,
  });

  final int score;
  final int attemptNumber;
  final int? previousScore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.primary, // Blue background to match the screenshot
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Score Dials Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Current Attempt
                _ScoreDial(
                  label: 'Current attempt',
                  score: score,
                  isCurrent: true,
                  color: scheme.onPrimary,
                  previousScore:
                      previousScore, // Passed here to calculate the difference
                ),
                // Previous Attempt (if provided)
                if (previousScore != null)
                  _ScoreDial(
                    label: 'Previous attempt',
                    score: previousScore!,
                    isCurrent: false,
                    color: scheme.onPrimary.withValues(alpha: 0.5),
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // Feedback Text
            Text(
              score >= 80
                  ? 'Clear, accountable, and easy to act on.'
                  : score >= 60
                  ? 'Solid effort — a few things to polish.'
                  : 'Keep practicing — review the notes below.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimary.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreDial extends StatelessWidget {
  const _ScoreDial({
    required this.label,
    required this.score,
    required this.isCurrent,
    required this.color,
    this.previousScore,
  });

  final String label;
  final int score;
  final bool isCurrent;
  final Color color;
  final int? previousScore;

  @override
  Widget build(BuildContext context) {
    // Calculate the difference only if this is the current dial and previousScore exists
    final int? diff = (isCurrent && previousScore != null)
        ? score - previousScore!
        : null;

    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 104,
          height: 104,
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
                  backgroundColor: color.withValues(alpha: 0.2),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isCurrent ? 'Current' : 'Previous',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: color, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      score.toString(),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                    ),
                    // Difference Indicator (Only shows up for the Current Dial if diff exists and != 0)
                    if (diff != null && diff != 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            diff > 0
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 14,
                            color: diff > 0
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                          Text(
                            '${diff.abs()}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: diff > 0
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
