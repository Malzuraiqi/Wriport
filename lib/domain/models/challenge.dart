import 'package:wriport/domain/models/criterion.dart';

class Challenge {
  Challenge({
    required this.id,
    required this.category,
    required this.title,
    required this.instructions,
    required this.tone,
    required this.minWords,
    required this.maxWords,
  });

  final int id;
  final Category category;
  final String title;
  final String instructions;
  final String tone;
  final int minWords;
  final int maxWords;
}

enum Category {
  // Define categories for challenges
  email(
    label: 'Email',
    description: 'Direct digital messages sent for professional or personal updates',
    criteria: [...Criteria.core, Criteria.conciseness],
  ),
  blogPost(
    label: 'Blog Post',
    description: 'Engaging, informal online articles sharing insights, guides, or opinions.',
    criteria: [...Criteria.core, Criteria.structure],
  ),
  prompt(
    label: 'Prompt',
    description: 'Structured instructions guiding AI models to generate specific outputs.',
    criteria: [...Criteria.core, Criteria.completeness, Criteria.conciseness],
  ),
  report(
    label: 'Report',
    description: 'Formal, data-driven documents analyzing specific facts or findings.',
    criteria: [...Criteria.core, Criteria.structure, Criteria.completeness],
  ),
  socialMediaPost(
    label: 'Social Media Post',
    description: 'Brief, highly engaging copy optimized to drive audience interaction.',
    criteria: [...Criteria.core, Criteria.conciseness, Criteria.structure],
  ),
  essay(
    label: 'Essay',
    description: 'Structured academic prose arguing a specific thesis or perspective.',
    criteria: [...Criteria.core, Criteria.structure],
  ),
  productDescription(
    label: 'Product Description',
    description: 'Compelling copy highlights features to convert readers into buyers.',
    criteria: [...Criteria.core, Criteria.conciseness, Criteria.completeness],
  ),
  technicalDocumentation(
    label: 'Technical Documentation',
    description: 'Clear instructions explaining how to use software or systems.',
    criteria: [...Criteria.core, Criteria.structure, Criteria.completeness],
  );


  final String label;
  final String description;
  final List<Criterion> criteria;

  const Category({
    required this.label,
    required this.description,
    required this.criteria,
  });
}