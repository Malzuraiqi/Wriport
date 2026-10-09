import 'package:wriport/domain/models/challenge.dart';


class ChallengeRepository {
  // getChallenge(Category) -> List<Challenge>, hardcoded for now
  List<Challenge> getChallenges(Category category) {
    // Implementation for fetching challenges based on category
    switch (category) {
      case Category.email:
        return [
          Challenge(
            id: 1,
            category: Category.email,
            title: 'Email Challenge 1',
            instructions: 'Write an email to your boss about a project update.',
            tone: 'Professional',
            minWords: 50,
            maxWords: 200,
          ),
          Challenge(
            id: 2,
            category: Category.email,
            title: 'Email Challenge 2',
            instructions: 'Write an email to a friend inviting them to a party.',
            tone: 'Friendly',
            minWords: 30,
            maxWords: 150,
          ),
        ];
      case Category.blogPost:
        return [
          Challenge(
            id: 3,
            category: Category.blogPost,
            title: 'Blog Post Challenge 1',
            instructions: 'Write a blog post about your favorite hobby.',
            tone: 'Informative',
            minWords: 300,
            maxWords: 1000,
          ),
          Challenge(
            id: 4,
            category: Category.blogPost,
            title: 'Blog Post Challenge 2',
            instructions: 'Write a blog post about the benefits of meditation.',
            tone: 'Inspirational',
            minWords: 400,
            maxWords: 1200,
          ),
        ];
    }
  }
}