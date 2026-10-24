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
    final scheme = Theme.of(context).colorScheme;
    final sessionAsync = ref.watch(_sessionProvider(widget.sessionId));
    final attemptsAsync = ref.watch(_sessionAttemptsProvider(widget.sessionId));

    final session = sessionAsync.value;
    final title = session?.challengeTitle ?? 'Session';

    return Scaffold(
      appBar: AppBar(
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
          const SizedBox(width: 4),
        ],
      ),
      body: attemptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: scheme.error),
              const SizedBox(height: 12),
              Text(
                'Could not load attempts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (attempts) {
          if (attempts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 48, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('No attempts in this session',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        '${attempts.length} attempt${attempts.length == 1 ? '' : 's'} — read-only',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemCount: attempts.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final sa = attempts[index];
                            final isExpanded = _expandedIndex == index;

                            return _ReadOnlyAttemptCard(
                              sessionAttempt: sa,
                              attemptNumber: index + 1,
                              isExpanded: isExpanded,
                              onTap: () {
                                setState(() {
                                  _expandedIndex =
                                      isExpanded ? null : index;
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
    final feedback = sessionAttempt.feedback;
    final attempt = sessionAttempt.attempt;
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
            color: isExpanded
                ? scheme.primary
                : scheme.outlineVariant.withValues(alpha: 0.5),
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
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
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
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${attempt.wordCount} words',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
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
                final itemWidth = (constraints.maxWidth - 8) / 2;

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: feedback.criteria.map<Widget>((c) {
                    return Container(
                      width: itemWidth,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            scoreColor(scheme, c.score).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              c.criterion.label,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: scoreColor(scheme, c.score),
                                  ),
                            ),
                          ),
                          Text(
                            '${c.score}/100',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
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

            // Expanded Details
            if (isExpanded) ...[
              const SizedBox(height: 24),
              const Divider(),

              // Written text (read-only)
              if (attempt.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Your response',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    attempt.text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Strengths
              if (feedback.strengths.isNotEmpty)
                FeedbackListCard(
                  title: 'What to keep',
                  items: feedback.strengths,
                  icon: Icons.thumb_up_outlined,
                  color: scheme.primary,
                  background:
                      scheme.primaryContainer.withValues(alpha: 0.3),
                  foreground: scheme.primary,
                ),

              const SizedBox(height: 12),

              // Improvements
              if (feedback.improvements.isNotEmpty)
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
        ),
      ),
    );
  }
}
