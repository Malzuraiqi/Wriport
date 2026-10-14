// writing screen:
// challenge details (instructions + constraint chips),
// a writing field with a live word counter and progress towards the target,
// and a submit button that navigates to the feedback screen.
//
// BUG FIX vs. the original: isIdle/isError used to be computed BEFORE the
// await submit(...) call, so the navigation / error-snackbar logic could
// never see the updated status. We now read the state AFTER the await.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wriport/domain/models/challenge.dart';
import 'package:wriport/providers.dart';
import 'package:wriport/state/attempt_state.dart';
import 'package:wriport/ui/widgets/attempts_pill.dart';
import 'package:wriport/ui/widgets/info_section_card.dart';
import 'package:wriport/ui/widgets/word_counter.dart';
import 'feedback_screen.dart';

class WritingScreen extends ConsumerStatefulWidget {
  const WritingScreen({super.key, required this.challenge});

  final Challenge challenge;

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
    _textController = TextEditingController();
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
    await ref
        .read(Providers.attemptControllerProvider.notifier)
        .submit(challenge, _textController.text, _wordCount);

    if (!context.mounted) return;

    final status = ref.read(Providers.attemptControllerProvider).status;
    final attemptState = ref.read(Providers.attemptControllerProvider);
    if (status == AttemptStatus.idle) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FeedbackScreen()),
      );
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
    final challenge = widget.challenge;
    final scheme = Theme.of(context).colorScheme;
    final attemptState = ref.watch(Providers.attemptControllerProvider);
    final isLoading = attemptState.status == AttemptStatus.loading;
    final canSubmit = (!isLoading && _wordCount >= challenge.minWords) && attemptState.canAttempt;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return; // if already popped

        if (_textController.text.trim().isEmpty) {
          Navigator.of(context).pop();
          return;
        }

        final bool shouldLeave = await _showExitConfirmation(context) ?? false;
        if (shouldLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(challenge.title),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth >= 720 ? 32 : 16,
                  vertical: 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AttemptsPill(displayAttemptNumber: attemptState.attempts.length + 1,),
                        const SizedBox(height: 24,),
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
                            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                            foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
                            contentOpacity: 0.8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: attemptState.latestFeedback.improvements.map((item) => Text('• $item')).toList(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Constraint chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              avatar: Icon(Icons.record_voice_over_outlined,
                                  size: 16, color: scheme.onSurfaceVariant),
                              label: Text('Tone: ${challenge.tone}'),
                            ),
                            Chip(
                              avatar: Icon(Icons.format_list_numbered,
                                  size: 16, color: scheme.onSurfaceVariant),
                              label: Text(
                                  '${challenge.minWords}–${challenge.maxWords} words'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        WordCounter(
                          wordCount: _wordCount,
                          minWords: challenge.minWords,
                          maxWords: challenge.maxWords,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          keyboardType: TextInputType.multiline,
                          minLines: 8,
                          maxLines: null,
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'Start writing here...',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (isLoading) ...[
                          const LinearProgressIndicator(),
                          const SizedBox(height: 12),
                        ],
                        FilledButton.icon(
                          onPressed: (isLoading || !canSubmit) ? null : () => _submit(challenge),
                          icon: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_outlined, size: 18),
                          label: Text(isLoading ? 'Evaluating...' : 'Submit'),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // The Figma-styled custom dialog
  Future<bool?> _showExitConfirmation(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: scheme.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24), 
        // NEW: ConstrainedBox limits how wide the pop-up can get
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                // Light red circular warning icon
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Your current answer hasn\'t been submitted. If you leave now, this answer will be lost.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 32),
                
                // Top Button: Stay (Solid filled)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Keep writing', 
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Bottom Button: Leave (Light background with icon)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primaryContainer.withValues(alpha: 0.4),
                      foregroundColor: scheme.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
      ),
    );
  }
}