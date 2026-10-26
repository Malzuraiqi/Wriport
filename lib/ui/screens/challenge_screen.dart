// challenge screen:
// the challenges list from the challenge repository for the given category,
// each shown as a card with tone + word-range chips and a start button,
// laid out as a grid on wide screens and a single column on narrow ones.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wriport/providers.dart';
import 'package:wriport/router.dart';
import 'package:wriport/domain/models/challenge.dart';

class ChallengeScreen extends ConsumerWidget {
  final Category category;

  const ChallengeScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(Providers.challengesProvider(category));

    return Scaffold(
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWide = width >= 720;
            const maxContentWidth = 1100.0;
            final basePadding = isWide ? 32.0 : 16.0;
            final sidePadding = width > maxContentWidth + basePadding * 2
                ? (width - maxContentWidth) / 2
                : basePadding;

            return CustomScrollView(
              slivers: [
                SliverAppBar.medium(
                  title: Text('${category.label} Challenges'),
                  actions: [
                    IconButton(
                      tooltip: 'History',
                      onPressed: () => context.go(AppRouter.history),
                      icon: const Icon(Icons.history_outlined),
                    ),
                    IconButton(
                      tooltip: 'Home',
                      onPressed: () => context.go(AppRouter.home),
                      icon: const Icon(Icons.home_outlined),
                    ),
                    IconButton(
                      tooltip: 'Sign out',
                      onPressed: () async {
                        await ref
                            .read(Providers.authRepositoryProvider)
                            .signOut();
                      },
                      icon: const Icon(Icons.logout_outlined),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(sidePadding, 8, sidePadding, 0),
                  sliver: SliverToBoxAdapter(
                    child: _ChallengeListHeader(count: challenges.length),
                  ),
                ),
                if (challenges.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyChallenges(),
                  )
                else
                  SliverPadding(
                    padding:
                        EdgeInsets.fromLTRB(sidePadding, 16, sidePadding, 32),
                    sliver: isWide
                        ? SliverGrid.builder(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 460,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              mainAxisExtent: 290,
                            ),
                            itemCount: challenges.length,
                            itemBuilder: (context, index) => _ChallengeCard(
                              challenge: challenges[index],
                              isGridMode: true,
                            ),
                          )
                        : SliverList.separated(
                            itemCount: challenges.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _ChallengeCard(challenge: challenges[index]),
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

class _ChallengeListHeader extends StatelessWidget {
  const _ChallengeListHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.edit_note_rounded,
            color: scheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a challenge',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$count ${count == 1 ? 'challenge' : 'challenges'} available',
                style: theme.textTheme.bodyMedium?.copyWith(
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

class _EmptyChallenges extends StatelessWidget {
  const _EmptyChallenges();

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
            Text('No challenges yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Check back soon for new writing prompts.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends ConsumerWidget {
  const _ChallengeCard({required this.challenge, this.isGridMode = false});

  final Challenge challenge;
  final bool isGridMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Widget instructionsWidget = Text(
      challenge.instructions,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
        height: 1.5,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 3,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChallengeMeta(
              tone: challenge.tone,
              minWords: challenge.minWords,
              maxWords: challenge.maxWords,
            ),
            const SizedBox(height: 14),
            Text(
              challenge.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (isGridMode)
              Expanded(child: instructionsWidget)
            else
              instructionsWidget,
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {
                  ref.read(Providers.attemptControllerProvider.notifier).reset();
                  // Pass only the id; the writing route looks it up.
                  context.go(AppRouter.writing(challenge.id));
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Start Challenge'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeMeta extends StatelessWidget {
  const _ChallengeMeta({
    required this.tone,
    required this.minWords,
    required this.maxWords,
  });

  final String tone;
  final int minWords;
  final int maxWords;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          avatar: Icon(Icons.record_voice_over_outlined,
              size: 16, color: scheme.onSurfaceVariant),
          label: Text(tone),
        ),
        Chip(
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          avatar: Icon(Icons.format_list_numbered,
              size: 16, color: scheme.onSurfaceVariant),
          label: Text('$minWords–$maxWords words'),
        ),
      ],
    );
  }
}