import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wriport/core/app_constants.dart';
import 'package:wriport/domain/models/feedback.dart';
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

    final feedback = attemptState.latestFeedback;
    final prevFeedback = attemptState.previousFeedback;
    

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
              previousScore: prevFeedback?.overallScore,
            );

            final hasPrevious = prevFeedback != null;

            final details = Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (hasPrevious)
                          Text(
                            'Current vs previous attempt',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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

                          final matchingPrevCriterion = prevFeedback.criteria.firstWhere(
                            (prev) => prev.criterion.label.trim().toLowerCase() == feedback.criteria[i].criterion.label.trim().toLowerCase(),
                          );

                          return matchingPrevCriterion.score != -1 ? matchingPrevCriterion.score : null;
                        }(),
                      ),
                      if (i < feedback.criteria.length - 1) 
                        const SizedBox(height: 24), // Spacing between criteria
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
              onPressed: () {
                final challengeId = attemptState.attempts.lastOrNull?.challengeId;
                if (challengeId != null) {
                  context.go(AppRouter.writing(challengeId));
                } else if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRouter.home);
                }
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again'),
            );

            final restartButton = FilledButton.icon(
              onPressed: () {
                final id = attemptState.attempts.lastOrNull?.challengeId;
                final challenge = id == null ? null : ref.read(Providers.challengeProvider(id));
                context.go(challenge == null
                    ? AppRouter.home
                    : AppRouter.challengeList(challenge.category));
              },
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text("Back to challenges")
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
                      AttemptsPill(displayAttemptNumber: attemptState.attempts.length),
                      const SizedBox(height: 24),
                      if (saveBanner != null) saveBanner,
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
                        child: Column(children: [
                          if (attemptState.canAttempt) tryagainButton,
                          const SizedBox(height: 12,),
                          restartButton,
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => _AttemptHistoryDialog(
                                  attemptState: attemptState,
                                ),
                              );
                            },
                            icon: const Icon(Icons.history, size: 18),
                            label: const Text('View history'),
                          ),
                          SizedBox(height: 10,),
                          Text(
                            attemptState.attempts.length >= AppConstants.maxAttempts 
                            ? 'max attempts reached' 
                            : '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  ]),
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
                  previousScore: previousScore, // Passed here to calculate the difference
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
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      score.toString(),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                            diff > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 14,
                            color: diff > 0 ? Colors.greenAccent : Colors.redAccent,
                          ),
                          Text(
                            '${diff.abs()}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: diff > 0 ? Colors.greenAccent : Colors.redAccent,
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

class _AttemptHistoryDialog extends StatefulWidget {
  final AttemptState attemptState;

  const _AttemptHistoryDialog({required this.attemptState});

  @override
  State<_AttemptHistoryDialog> createState() => _AttemptHistoryDialogState();
}

class _AttemptHistoryDialogState extends State<_AttemptHistoryDialog> {
  // Tracks which attempt index is currently expanded. Null means all closed.
  int? _expandedIndex; 

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final feedbacks = widget.attemptState.feedbacks.reversed.toList(); // Newest first

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: scheme.surface,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attempt history',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.attemptState.attempts.length} of ${AppConstants.maxAttempts} attempts completed',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Scrollable List of Attempts
              Expanded(
                child: ListView.separated(
                  itemCount: feedbacks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final feedback = feedbacks[index];
                    final attemptNumber = widget.attemptState.attempts.length - index;
                    final isExpanded = _expandedIndex == index;

                    return _HistoryCard(
                      feedback: feedback,
                      attemptNumber: attemptNumber,
                      isLatest: index == 0,
                      isExpanded: isExpanded,
                      onTap: () {
                        setState(() {
                          // Toggle logic: if already open, close it; otherwise open it and close others
                          _expandedIndex = isExpanded ? null : index;
                        });
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Select an attempt to view detailed feedback.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final FeedBack feedback;
  final int attemptNumber;
  final bool isLatest;
  final bool isExpanded;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.feedback,
    required this.attemptNumber,
    required this.isLatest,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = scoreColor(scheme, feedback.overallScore);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.5),
            width: isExpanded ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row (Score, Title, Dropdown Icon)
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        value: feedback.overallScore / 100,
                        strokeWidth: 4,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.2),
                      ),
                    ),
                    Text(
                      feedback.overallScore.toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attempt $attemptNumber',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        isLatest ? 'Current attempt' : 'Previous attempt',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isLatest ? scheme.primary : scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Criteria Grid (Always visible)
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate exactly half the available width, minus the 8px spacing gap
                final itemWidth = (constraints.maxWidth - 8) / 2;
                
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: feedback.criteria.map<Widget>((c) {
                    return Container(
                      width: itemWidth, // Use the dynamically calculated width
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: scoreColor(scheme, c.score).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              c.criterion.label,
                              overflow: TextOverflow.ellipsis, // Prevents text from breaking layout on very small devices
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: scoreColor(scheme, c.score),
                                  ),
                            ),
                          ),
                          Text(
                            '${c.score}/100',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor(scheme, c.score),
                                ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // Expanded Details (Strengths & Improvements)
            if (isExpanded) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Strengths
              if (feedback.strengths.isNotEmpty)
                _FeedbackListCard(
                  title: 'What to keep',
                  items: feedback.strengths,
                  icon: Icons.thumb_up_outlined,
                  color: scheme.primary,
                  background: scheme.primaryContainer.withValues(alpha: 0.3),
                  foreground: scheme.primary,
                ),
                
              const SizedBox(height: 12),
              
              // Improvements
              if (feedback.improvements.isNotEmpty)
                _FeedbackListCard(
                  title: 'What to improve',
                  items: feedback.improvements,
                  icon: Icons.auto_fix_high,
                  color: scheme.tertiary,
                  background: scheme.tertiaryContainer.withValues(alpha: 0.3),
                  foreground: scheme.tertiary,
                ),
            ],
          ],
        ),
      ),
    );
  }
}