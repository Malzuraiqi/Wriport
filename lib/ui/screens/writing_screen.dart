import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wriport/domain/models/attempt.dart';
import 'package:wriport/domain/models/challenge.dart';
import 'package:wriport/providers.dart';
import 'package:wriport/router.dart';
import 'package:wriport/state/attempt_state.dart';
import 'package:wriport/ui/widgets/attempts_pill.dart';
import 'package:wriport/ui/widgets/info_section_card.dart';
import 'package:wriport/ui/widgets/word_counter.dart';

class WritingScreen extends ConsumerStatefulWidget {
  const WritingScreen({super.key, required this.challengeId});

  final int challengeId;

  @override
  ConsumerState<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends ConsumerState<WritingScreen> {
  late final TextEditingController _textController;
  int _wordCount = 0;

  static int _countWords(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  @override
  void initState() {
    super.initState();
    final attemptState = ref.read(Providers.attemptControllerProvider);
    final lastAttempt = attemptState.attempts.lastOrNull;
    final isSameChallenge =
        lastAttempt != null &&
        lastAttempt.challengeId == widget.challengeId &&
        attemptState.canAttempt;

    // Only reset if previously working on a different challenge
    if (attemptState.attempts.isNotEmpty && !isSameChallenge) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(Providers.attemptControllerProvider.notifier).reset();
        }
      });
    }

    // Preserve previous attempt text if refining the same challenge
    final initialText = isSameChallenge ? lastAttempt.text : '';
    _textController = TextEditingController(text: initialText);
    _wordCount = countWords(initialText);
    _textController.addListener(_updateWordCount);
  }

  void _updateWordCount() {
    setState(() => _wordCount = _countWords(_textController.text));
  }

  @override
  void dispose() {
    _textController.removeListener(_updateWordCount);
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit(Challenge challenge) async {
    final countBefore =
        ref.read(Providers.attemptControllerProvider).feedbacks.length;
    final evaluated = Completer<void>();
    final sub = ref.listenManual(Providers.attemptControllerProvider, (_, next) {
      if (next.feedbacks.length > countBefore ||
          next.status == AttemptStatus.error) {
        if (!evaluated.isCompleted) evaluated.complete();
      }
    });
    unawaited(ref
        .read(Providers.attemptControllerProvider.notifier)
        .submit(challenge, _textController.text)
        .whenComplete(() {
      if (!evaluated.isCompleted) evaluated.complete();
    }));
    await evaluated.future;
    sub.close();

    if (!mounted) return;

    final status = ref.read(Providers.attemptControllerProvider).status;
    final attemptState = ref.read(Providers.attemptControllerProvider);
    if (status == AttemptStatus.idle) {
      context.go(AppRouter.feedback);
    } else if (status == AttemptStatus.error) {
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: scheme.onError),
                const SizedBox(width: 12),
                Expanded(child: Text(attemptState.errorMessage ?? 'Unknown Error')),
              ],
            ),
            backgroundColor: scheme.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = ref.watch(Providers.challengeProvider(widget.challengeId));

    if (challenge == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Challenge not found')),
        body: const _ChallengeNotFound(),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final attemptState = ref.watch(Providers.attemptControllerProvider);
    final isLoading = attemptState.status == AttemptStatus.loading;
    final canSubmit = (!isLoading && _wordCount >= challenge.minWords) && attemptState.canAttempt;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        if (_textController.text.trim().isEmpty) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRouter.home);
          }
          return;
        }

        final bool shouldLeave = await _showExitConfirmation(context) ?? false;
        if (shouldLeave && context.mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRouter.home);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            challenge.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              tooltip: 'Home',
              onPressed: () async {
                if (_textController.text.trim().isNotEmpty) {
                  final leave = await _showExitConfirmation(context) ?? false;
                  if (leave && context.mounted) {
                    context.go(AppRouter.home);
                  }
                } else {
                  context.go(AppRouter.home);
                }
              },
              icon: const Icon(Icons.home_outlined),
            ),
            IconButton(
              tooltip: 'Sign out',
              onPressed: () async {
                if (_textController.text.trim().isNotEmpty) {
                  final leave = await _showExitConfirmation(context) ?? false;
                  if (leave && context.mounted) {
                    await ref.read(Providers.authRepositoryProvider).signOut();
                  }
                } else {
                  await ref.read(Providers.authRepositoryProvider).signOut();
                }
              },
              icon: const Icon(Icons.logout_outlined),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 720 ? 32.0 : 16.0;

              return CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
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
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: AttemptsPill(
                                  displayAttemptNumber:
                                      attemptState.attempts.length + 1,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Instructions panel
                              InfoSectionCard(
                                title: 'Instructions',
                                icon: Icons.assignment_outlined,
                                content: challenge.instructions,
                              ),
                              if (attemptState.feedbacks.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                InfoSectionCard(
                                  title: 'Suggested Improvements',
                                  icon: Icons.tips_and_updates_outlined,
                                  backgroundColor: scheme.tertiaryContainer,
                                  foregroundColor: scheme.onTertiaryContainer,
                                  contentOpacity: 0.8,
                                  child: _ImprovementsList(
                                    items: attemptState.latestFeedback.improvements,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              _ConstraintChips(
                                tone: challenge.tone,
                                minWords: challenge.minWords,
                                maxWords: challenge.maxWords,
                              ),
                              const SizedBox(height: 24),
                              _EditorSection(
                                controller: _textController,
                                wordCount: _wordCount,
                                minWords: challenge.minWords,
                                maxWords: challenge.maxWords,
                              ),
                              const SizedBox(height: 20),
                              _SubmitSection(
                                isLoading: isLoading,
                                onPressed: (isLoading || !canSubmit)
                                    ? null
                                    : () => _submit(challenge),
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
      ),
    );
  }

  Future<bool?> _showExitConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const _ExitConfirmationDialog(),
    );
  }
}

class _ChallengeNotFound extends StatelessWidget {
  const _ChallengeNotFound();

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
            Icon(Icons.search_off_rounded,
                size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'This challenge does not exist',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImprovementsList extends StatelessWidget {
  const _ImprovementsList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $item'),
            ),
          )
          .toList(),
    );
  }
}

class _ConstraintChips extends StatelessWidget {
  const _ConstraintChips({
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
          avatar: Icon(Icons.record_voice_over_outlined,
              size: 16, color: scheme.onSurfaceVariant),
          label: Text('Tone: $tone'),
        ),
        Chip(
          visualDensity: VisualDensity.compact,
          avatar: Icon(Icons.format_list_numbered,
              size: 16, color: scheme.onSurfaceVariant),
          label: Text('$minWords–$maxWords words'),
        ),
      ],
    );
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({
    required this.controller,
    required this.wordCount,
    required this.minWords,
    required this.maxWords,
  });

  final TextEditingController controller;
  final int wordCount;
  final int minWords;
  final int maxWords;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your response',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        WordCounter(
          wordCount: wordCount,
          minWords: minWords,
          maxWords: maxWords,
        ),
        const SizedBox(height: 8),
        TextField(
          keyboardType: TextInputType.multiline,
          minLines: 8,
          maxLines: null,
          controller: controller,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          decoration: const InputDecoration(
            hintText: 'Start writing here...',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}

class _SubmitSection extends StatelessWidget {
  const _SubmitSection({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isLoading) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: onPressed,
          icon: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onSurface.withValues(alpha: 0.38),
                  ),
                )
              : const Icon(Icons.send_outlined, size: 18),
          label: Text(isLoading ? 'Evaluating...' : 'Submit'),
        ),
      ],
    );
  }
}

class _ExitConfirmationDialog extends StatelessWidget {
  const _ExitConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
                  color: scheme.errorContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: scheme.error),
              ),
              const SizedBox(height: 20),
              Text(
                'Leave this question?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your current answer hasn\'t been submitted. If you leave now, this answer will be lost.',
                style: theme.textTheme.bodyMedium?.copyWith(
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
                    'Keep writing',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(
                    'Exit without saving',
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