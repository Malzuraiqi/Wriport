// History screen (route: /history):
// Lists all past sessions from Firestore, newest first. Tap a session to
// open its attempts in read-only mode. Long-press or swipe to delete.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wriport/domain/models/challenge.dart';
import 'package:wriport/domain/models/session.dart';
import 'package:wriport/providers.dart';
import 'package:wriport/router.dart';
import 'package:wriport/ui/category_icons.dart';
import 'package:wriport/ui/widgets/score_card.dart';

/// AutoDispose FutureProvider that loads all sessions from Firestore.
final _sessionsProvider = FutureProvider.autoDispose<List<Session>>((ref) {
  return ref.watch(Providers.historyRepositoryProvider).getSessions();
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(_sessionsProvider);
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width > 752 ? (width - 720) / 2 : 16.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Session history'),
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
          sessionsAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: _MessageState(
                icon: Icons.error_outline,
                isError: true,
                title: 'Could not load history',
                message: e.toString(),
                action: FilledButton.icon(
                  onPressed: () => ref.invalidate(_sessionsProvider),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ),
            ),
            data: (sessions) {
              if (sessions.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.inbox_outlined,
                    title: 'No sessions yet',
                    message: 'Complete a challenge to see it here.',
                    action: FilledButton(
                      onPressed: () => context.go(AppRouter.home),
                      child: const Text('Start practising'),
                    ),
                  ),
                );
              }

              return SliverSafeArea(
                top: false,
                sliver: SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 32),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _HistorySummary(count: sessions.length),
                        ),
                      ),
                      SliverList.separated(
                        itemCount: sessions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          return _SessionCard(
                            session: session,
                            onTap: () => context.push(
                              AppRouter.sessionDetail(session.id),
                            ),
                            onDelete: () => _confirmDelete(
                              context,
                              ref,
                              session,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Session session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _DeleteConfirmDialog(sessionTitle: session.challengeTitle),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(Providers.historyRepositoryProvider)
            .deleteSession(session.id);
        if (ref.read(Providers.attemptControllerProvider).sessionId == session.id) {
          ref.read(Providers.attemptControllerProvider.notifier).reset();
        }
        // Refresh the sessions list
        ref.invalidate(_sessionsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(content: Text('"${session.challengeTitle}" deleted')),
            );
        }
      } catch (e) {
        if (context.mounted) {
          final errorScheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: errorScheme.onError),
                    const SizedBox(width: 12),
                    const Expanded(
                        child: Text('Could not delete session. Try again.')),
                  ],
                ),
                backgroundColor: errorScheme.error,
              ),
            );
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Private UI building blocks
// ---------------------------------------------------------------------------

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            '$count session${count == 1 ? '' : 's'}',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ),
        Icon(Icons.touch_app_outlined,
            size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          'Long-press to delete',
          style: textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Look up the Category enum for the icon
    final category = Category.values
        .where((c) => c.name == session.categoryName)
        .firstOrNull;

    final hasScore = session.bestScore != null;
    final scoreColour =
        hasScore ? scoreColor(scheme, session.bestScore!) : scheme.outline;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Row(
            children: [
              // Category icon
              CircleAvatar(
                radius: 24,
                backgroundColor: scheme.primaryContainer,
                child: Icon(
                  category?.icon ?? Icons.assignment_outlined,
                  color: scheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Title and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.challengeTitle,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(session.startedAt),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Best score badge
              if (hasScore) ...[
                _ScoreBadge(text: '${session.bestScore}', color: scoreColour),
                const SizedBox(width: 4),
              ],

              // Delete icon button
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: scheme.onSurfaceVariant),
                tooltip: 'Delete session',
                onPressed: onDelete,
              ),

              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({required this.sessionTitle});

  final String sessionTitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: scheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline, color: scheme.error),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete session?',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will permanently delete "$sessionTitle" and all its attempts. This action cannot be undone.',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Keep session',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text(
                    'Delete permanently',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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

/// Centered icon + title + optional message/action for error and empty states.
class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
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
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (action != null) ...[
                  const SizedBox(height: 24),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}