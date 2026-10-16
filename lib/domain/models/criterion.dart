class Criterion {
  const Criterion({
    required this.id, 
    required this.label, 
    required this.description
  });

  final String id;
  final String label;
  final String description;
}

class Criteria {
  Criteria._();

  // The core set
  static const grammar = Criterion(
    id: 'grammar', 
    label: 'Grammar', 
    description: 'How strictly the text follows syntactic rules so that errors do not distract the reader or distort the message.'
  );

  static const tone = Criterion(
    id: 'tone', 
    label: 'Tone', 
    description: 'How well the writing matches the required professional, casual, or brand voice.'
  );

  static const clarity = Criterion(
    id: 'clarity', 
    label: 'Clarity', 
    description: 'How quickly and easily the reader understands the exact message without needing to reread it.'
  );

  // Category-specific ones
  static const conciseness = Criterion(
    id: 'conciseness',
    label: 'Conciseness',
    description: 'How efficiently the text delivers information by removing filler words without losing core meaning.',
  );

  static const structure = Criterion(
    id: 'structure',
    label: 'Structure',
    description: 'How logically the ideas flow and how effectively the formatting guides the reader through the text.',
  );

  static const completeness = Criterion(
    id: 'completeness',
    label: 'Completeness',
    description: 'Whether the text includes all necessary facts and context required for the reader to take action or fully understand the topic.',
  );

  // Groupings
  static const core = [grammar, tone, clarity];
}