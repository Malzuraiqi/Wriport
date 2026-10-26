// Session detail screen (route: /history/:sessionId):
// Displays all attempts from a past session in read-only mode.
// Each attempt is expandable to show criteria, strengths, and improvements.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wriport/domain/models/session.dart';
import 'package:wriport/domain/models/session_attempt.dart';
import 'package:wriport/providers.dart';
import 'package:wriport/router.dart';
import 'package:wriport/ui/widgets/feedback_list_card.dart';
import 'package:wriport/ui/widgets/score_card.dart';

/// AutoDispose FutureProvider family that loads session attempts from Firestore.
final _sessionAttemptsProvider =
    FutureProvider.autoDispose.family<List<SessionAttempt>, String>((ref, sessionId) {
  return ref.watch(Providers.historyRepositoryProvider).getAttempts(sessionId);
});

/// AutoDispose FutureProvider family that loads a single session from Firestore.
final _sessionProvider =
    FutureProvider.autoDispose.family<Session?, String>((ref, sessionId) {
  return ref.watch(Providers.historyRepositoryProvider).getSession(sessionId);
});

class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(_sessionProvider(widget.sessionId));
    final attemptsAsync = ref.watch(_sessionAttemptsProvider(widget.sessionId));

    final session = sessionAsync.value;
    final title = session?.challengeTitle ?? 'Session';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(title),
            actions: [
              IconButton(
                tooltip: 'Home',
                onPressed: () => context.go(AppRouter.home),
                icon: const Icon(Icons.home_outlined),
              ),
              IconButton(
                tooltip: 'Sign out',
                onPressed: () async {
                  await ref.read(Providers.authRepositoryProvider).signOut();
                },
                icon: const Icon(Icons.logout_outlined),
              ),
              const SizedBox(width: 8),
            ],
          ),
          attemptsAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: _MessageState(
                icon: Icons.error_outline,
                isError: true,
                title: 'Could not load attempts',
                message: e.toString(),
              ),
            ),
            data: (attempts) {
              if (attempts.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.inbox_outlined,
                    title: 'No attempts in this session',
                  ),
                );
              }

              return _AttemptsSliver(
                attempts: attempts,
                expandedIndex: _expandedIndex,
                onToggle: (index) {
                  setState(() {
                    _expandedIndex = _expandedIndex == index ? null : index;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private UI building blocks
// ---------------------------------------------------------------------------

/// Centered, width-constrained list of attempts with a summary header and hint.
class _AttemptsSliver extends StatelessWidget {
  const _AttemptsSliver({
    required this.attempts,
    required this.expandedIndex,
    required this.onToggle,
  });

  final List<SessionAttempt> attempts;
  final int? expandedIndex;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width > 752 ? (width - 720) / 2 : 16.0;

    return SliverSafeArea(
      top: false,
      sliver: SliverPadding(
        padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 32),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _SessionSummary(count: attempts.length),
              ),
            ),
            SliverList.separated(
              itemCount: attempts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final isExpanded = expandedIndex == index;
                return _ReadOnlyAttemptCard(
                  sessionAttempt: attempts[index],
                  attemptNumber: index + 1,
                  isExpanded: isExpanded,
                  onTap: () => onToggle(index),
                );
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(
                  child: Text(
                    'Select an attempt to view detailed feedback.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header row: attempt count + read-only badge.
class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            '$count attempt${count == 1 ? '' : 's'}',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Read-only',
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyAttemptCard extends StatelessWidget {
  final SessionAttempt sessionAttempt;
  final int attemptNumber;
  final bool isExpanded;
  final VoidCallback onTap;

  const _ReadOnlyAttemptCard({
    required this.sessionAttempt,
    required this.attemptNumber,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final feedback = sessionAttempt.feedback;
    final attempt = sessionAttempt.attempt;
    final color = scoreColor(scheme, feedback.overallScore);

    final criteria = feedback.criteria.map<_CriterionData>((c) {
      final cColor = scoreColor(scheme, c.score);
      return _CriterionData(
        label: c.criterion.label,
        scoreText: '${c.score}/100',
        color: cColor,
      );
    }).toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isExpanded ? scheme.primary : scheme.outlineVariant,
          width: isExpanded ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: score ring, title, chevron
                Row(
                  children: [
                    _ScoreRing(
                      value: feedback.overallScore / 100,
                      text: feedback.overallScore.toString(),
                      color: color,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attempt $attemptNumber',
                            style: textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${attempt.wordCount} words',
                            style: textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Criteria grid (always visible)
                _CriteriaGrid(items: criteria),

                // Expanded details
                if (isExpanded) ...[
                  const SizedBox(height: 20),
                  Divider(color: scheme.outlineVariant, height: 1),

                  if (attempt.text.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _ResponseBox(text: attempt.text),
                  ],

                  if (feedback.strengths.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    FeedbackListCard(
                      title: 'What to keep',
                      items: feedback.strengths,
                      icon: Icons.thumb_up_outlined,
                      color: scheme.primary,
                      background:
                          scheme.primaryContainer.withValues(alpha: 0.3),
                      foreground: scheme.primary,
                    ),
                  ],

                  if (feedback.improvements.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    FeedbackListCard(
                      title: 'What to improve',
                      items: feedback.improvements,
                      icon: Icons.auto_fix_high,
                      color: scheme.tertiary,
                      background:
                          scheme.tertiaryContainer.withValues(alpha: 0.3),
                      foreground: scheme.tertiary,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular overall-score indicator.
class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.value,
    required this.text,
    required this.color,
  });

  final double value;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: 5,
            strokeCap: StrokeCap.round,
            color: color,
            backgroundColor: color.withValues(alpha: 0.18),
          ),
        ),
        Text(
          text,
          style: textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Lightweight view-model for a criterion chip (keeps the grid type-agnostic).
class _CriterionData {
  const _CriterionData({
    required this.label,
    required this.scoreText,
    required this.color,
  });

  final String label;
  final String scoreText;
  final Color color;
}

/// Responsive 2/3-column grid of criterion score chips.
class _CriteriaGrid extends StatelessWidget {
  const _CriteriaGrid({required this.items});

  final List<_CriterionData> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final columns = constraints.maxWidth >= 480 ? 3 : 2;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _CriterionChip(data: item),
              ),
          ],
        );
      },
    );
  }
}

class _CriterionChip extends StatelessWidget {
  const _CriterionChip({required this.data});

  final _CriterionData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              data.label,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(color: data.color),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            data.scoreText,
            style: textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: data.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// The user's original written response, shown read-only.
class _ResponseBox extends StatelessWidget {
  const _ResponseBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your response',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ),
      ],
    );
  }
}

/// Centered icon + title (+ optional message) used for error and empty states.
class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    this.message,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final iconColor = isError ? scheme.error : scheme.onSurfaceVariant;

    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 36, color: iconColor),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}