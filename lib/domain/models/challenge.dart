// this class (Challenge) describes what a challenge contains.
class Challenge {
  // id, category, title, instructions, tone, minWords, maxWords
  Challenge({
    required this.id,
    required this.category,
    required this.title,
    required this.instructions,
    required this.tone,
    required this.minWords,
    required this.maxWords,
  });

  // Define properties for each field
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
  email('Email'),
  blogPost('Blog Post');

  final String label;

  Category(this.label);
}