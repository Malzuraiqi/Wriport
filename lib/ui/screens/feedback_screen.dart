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
    final attemptState = ref.watch(Providers.attemptControllerProvider);

    // No empty-state fallback here: the /feedback route redirects to /home
    // when there is no feedback in state, so this screen only ever builds
    // with feedback present.
    // Empty-state guard: the original crashed with StateError when the
    // screen was reached without any feedback in state.
    if (attemptState.feedbacks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Feedback')),
        body: _EmptyFeedbackState(onGoBack: () => Navigator.pop(context)),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final feedback = attemptState.latestFeedback;
    final prevFeedback = attemptState.previousFeedback;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final horizontalPadding = constraints.maxWidth >= 720 ? 32.0 : 16.0;

            final rubric = _RubricCard(
              feedback: feedback,
              previousFeedback: prevFeedback,
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
                const SizedBox(height: 16),
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

            return CustomScrollView(
              slivers: [
                const SliverAppBar(
                  pinned: true,
                  title: Text('Feedback'),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    32,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: AttemptsPill(
                                displayAttemptNumber: attemptState.attempts.length,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _SaveBanner(
                              saveStatus: attemptState.saveStatus,
                              onRetry: () {
                                final challenge = ref.read(
                                  Providers.challengeProvider(
                                    attemptState.attempts.last.challengeId,
                                  ),
                                );
                                if (challenge != null) {
                                  ref
                                      .read(Providers.attemptControllerProvider
                                          .notifier)
                                      .retrySave(challenge);
                                }
                              },
                            ),
                            _ScoreHeader(
                              score: feedback.overallScore,
                              attemptNumber: attemptState.attempts.length,
                              previousScore: prevFeedback?.overallScore,
                            ),
                            const SizedBox(height: 24),
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: rubric),
                                  const SizedBox(width: 24),
                                  Expanded(child: lists),
                                ],
                              )
                            else ...[
                              rubric,
                              const SizedBox(height: 16),
                              lists,
                            ],
                            const SizedBox(height: 32),
                            _FeedbackActions(
                              isWide: isWide,
                              canTryAgain: attemptState.canAttempt,
                              maxAttemptsReached: attemptState.attempts.length >=
                                  AppConstants.maxAttempts,
                              onTryAgain: () {
                                final challengeId =
                                    attemptState.attempts.lastOrNull?.challengeId;
                                if (challengeId != null) {
                                  context.go(AppRouter.writing(challengeId));
                                } else if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go(AppRouter.home);
                                }
                              },
                              onBackToChallenges: () {
                                final id =
                                    attemptState.attempts.lastOrNull?.challengeId;
                                final challenge = id == null
                                    ? null
                                    : ref.read(Providers.challengeProvider(id));
                                context.go(challenge == null
                                    ? AppRouter.home
                                    : AppRouter.challengeList(challenge.category));
                              },
                              onViewHistory: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => _AttemptHistoryDialog(
                                    attemptState: attemptState,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyFeedbackState extends StatelessWidget {
  const _EmptyFeedbackState({required this.onGoBack});

  final VoidCallback onGoBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('No feedback yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onGoBack,
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveBanner extends StatelessWidget {
  const _SaveBanner({required this.saveStatus, required this.onRetry});

  final SaveStatus saveStatus;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (saveStatus == SaveStatus.failed) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Could not save this attempt. Your feedback is still shown above.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (saveStatus == SaveStatus.saving) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
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
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      color: scheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: _ScoreDial(
                    label: 'Current attempt',
                    score: score,
                    isCurrent: true,
                    color: scheme.onPrimary,
                    previousScore: previousScore,
                  ),
                ),
                if (previousScore != null)
                  Flexible(
                    child: _ScoreDial(
                      label: 'Previous attempt',
                      score: previousScore!,
                      isCurrent: false,
                      color: scheme.onPrimary.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              score >= 80
                  ? 'Clear, accountable, and easy to act on.'
                  : score >= 60
                      ? 'Solid effort — a few things to polish.'
                      : 'Keep practicing — review the notes below.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onPrimary.withValues(alpha: 0.95),
                height: 1.4,
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
    final theme = Theme.of(context);

    // Calculate the difference only if this is the current dial and previousScore exists
    final int? diff = (isCurrent && previousScore != null)
        ? score - previousScore!
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 112,
          height: 112,
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
                  strokeCap: StrokeCap.round,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.2),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      score.toString(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'out of 100',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Difference indicator (only for the current dial when diff exists and != 0)
        if (diff != null && diff != 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  diff > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 2),
                Text(
                  '${diff.abs()}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RubricCard extends StatelessWidget {
  const _RubricCard({required this.feedback, required this.previousFeedback});

  final FeedBack feedback;
  final FeedBack? previousFeedback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final prevFeedback = previousFeedback;
    final hasPrevious = prevFeedback != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasPrevious ? 'Rubric comparison' : 'Rubric criteria',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hasPrevious) ...[
              const SizedBox(height: 4),
              Text(
                'Current vs previous attempt',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 24),
            for (int i = 0; i < feedback.criteria.length; i++) ...[
              ScoreCard(
                title: feedback.criteria[i].criterion.label,
                score: feedback.criteria[i].score,
                comment: feedback.criteria[i].comment,
                previousScore: () {
                  if (!hasPrevious) return null;

                  final matchingPrevCriterion = prevFeedback.criteria.firstWhere(
                    (prev) =>
                        prev.criterion.label.trim().toLowerCase() ==
                        feedback.criteria[i].criterion.label.trim().toLowerCase(),
                  );

                  return matchingPrevCriterion.score != -1
                      ? matchingPrevCriterion.score
                      : null;
                }(),
              ),
              if (i < feedback.criteria.length - 1)
                const SizedBox(height: 24), // Spacing between criteria
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackActions extends StatelessWidget {
  const _FeedbackActions({
    required this.isWide,
    required this.canTryAgain,
    required this.maxAttemptsReached,
    required this.onTryAgain,
    required this.onBackToChallenges,
    required this.onViewHistory,
  });

  final bool isWide;
  final bool canTryAgain;
  final bool maxAttemptsReached;
  final VoidCallback onTryAgain;
  final VoidCallback onBackToChallenges;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final tryAgainButton = FilledButton.icon(
      onPressed: onTryAgain,
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('Try again'),
    );

    final backButton = FilledButton.tonalIcon(
      onPressed: onBackToChallenges,
      icon: const Icon(Icons.arrow_back_rounded, size: 18),
      label: const Text('Back to challenges'),
    );

    final historyButton = TextButton.icon(
      onPressed: onViewHistory,
      icon: const Icon(Icons.history, size: 18),
      label: const Text('View history'),
    );

    final Widget buttons = isWide
        ? Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              historyButton,
              backButton,
              if (canTryAgain) tryAgainButton,
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (canTryAgain) ...[
                tryAgainButton,
                const SizedBox(height: 12),
              ],
              backButton,
              const SizedBox(height: 8),
              historyButton,
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buttons,
        if (maxAttemptsReached) ...[
          const SizedBox(height: 12),
          Text(
            'Max attempts reached',
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            textAlign: isWide ? TextAlign.end : TextAlign.center,
          ),
        ],
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
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
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
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
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
                    padding: const EdgeInsets.only(top: 7),
                    child: Icon(Icons.circle, size: 6, color: foreground),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                        height: 1.4,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final feedbacks = widget.attemptState.feedbacks.reversed.toList(); // Newest first

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attempt history',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.attemptState.attempts.length} of ${AppConstants.maxAttempts} attempts completed',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Scrollable List of Attempts
              Expanded(
                child: ListView.separated(
                  itemCount: feedbacks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
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

              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Select an attempt to view detailed feedback.',
                  style: theme.textTheme.bodySmall?.copyWith(
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = scoreColor(scheme, feedback.overallScore);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded
                ? scheme.primary
                : scheme.outlineVariant.withValues(alpha: 0.5),
            width: isExpanded ? 2 : 1,
          ),
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
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
                          strokeCap: StrokeCap.round,
                          color: color,
                          backgroundColor: color.withValues(alpha: 0.2),
                        ),
                      ),
                      Text(
                        feedback.overallScore.toString(),
                        style: theme.textTheme.titleMedium?.copyWith(
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isLatest ? 'Current attempt' : 'Previous attempt',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isLatest
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Criteria Grid (Always visible)
              LayoutBuilder(
                builder: (context, constraints) {
                  // Exactly half the available width, minus the 8px spacing gap
                  final itemWidth = (constraints.maxWidth - 8) / 2;

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: feedback.criteria.map<Widget>((c) {
                      final criterionColor = scoreColor(scheme, c.score);
                      return Container(
                        width: itemWidth,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: criterionColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                c.criterion.label,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: criterionColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${c.score}/100',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: criterionColor,
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
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

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
      ),
    );
  }
}