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
        .submit(challenge, _textController.text);

    if (!context.mounted) return;

    final status = ref.read(Providers.attemptControllerProvider).status;
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
                const Expanded(child: Text('Error submitting response, please try again')),
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
    final canSubmit = !isLoading && _wordCount >= challenge.minWords;

    return Scaffold(
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
                      // Instructions panel
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.assignment_outlined,
                                    size: 18, color: scheme.onSecondaryContainer),
                                const SizedBox(width: 8),
                                Text(
                                  'Instructions',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: scheme.onSecondaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              challenge.instructions,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSecondaryContainer,
                                  ),
                            ),
                          ],
                        ),
                      ),
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
                        onPressed: canSubmit ? () => _submit(challenge) : null,
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
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
    );
  }
}