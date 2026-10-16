// challenge screen:
// the challenges list from the challenge repository for the given category,
// each shown as a card with tone + word-range chips and a start button,
// laid out as a grid on wide screens and a single column on narrow ones.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wriport/providers.dart';
import 'package:wriport/ui/screens/writing_screen.dart';
import '../../domain/models/challenge.dart';

class ChallengeScreen extends ConsumerWidget {
  final Category category;

  const ChallengeScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(Providers.challengesProvider(category));
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: Text('${category.label} Challenges'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentPadding = EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 16,
              vertical: 16,
            );

            if (isWide) {
              return GridView.builder(
                padding: contentPadding,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 460,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  mainAxisExtent: 210
                ),
                itemCount: challenges.length,
                itemBuilder: (context, index) =>
                    _ChallengeCard(challenge: challenges[index], isGridMode: true,),
              );
            }

            return ListView.separated(
              padding: contentPadding,
              itemCount: challenges.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _ChallengeCard(challenge: challenges[index]),
            );
          },
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
    final scheme = Theme.of(context).colorScheme;

    final Widget instructionsWidget = Text(
      challenge.instructions,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
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
            Text(
              challenge.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),

            if (isGridMode) 
              Expanded(child: instructionsWidget)
            else
              instructionsWidget,
            
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(Icons.record_voice_over_outlined,
                      size: 16, color: scheme.onSurfaceVariant),
                  label: Text(challenge.tone),
                ),
                Chip(
                  avatar: Icon(Icons.format_list_numbered,
                      size: 16, color: scheme.onSurfaceVariant),
                  label: Text('${challenge.minWords}–${challenge.maxWords} words'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {
                  ref.read(Providers.attemptControllerProvider.notifier).reset();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WritingScreen(challenge: challenge),
                    ),
                  );
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