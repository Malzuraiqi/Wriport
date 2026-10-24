import 'package:wriport/domain/models/challenge.dart';


class ChallengeRepository {
  // getChallenge(Category) -> List<Challenge>, hardcoded for now
  List<Challenge> getChallenges(Category category) {
    switch (category) {
      case Category.email:
        return [
          Challenge(
            id: 1,
            category: Category.email,
            title: 'Project Status Update',
            instructions: 'Write an email to your boss about a project update.',
            tone: 'Professional',
            minWords: 50,
            maxWords: 200,
          ),
          Challenge(
            id: 2,
            category: Category.email,
            title: 'Casual Party Invitation',
            instructions: 'Write an email to a friend inviting them to a party.',
            tone: 'Friendly',
            minWords: 30,
            maxWords: 150,
          ),
          Challenge(
            id: 17,
            category: Category.email,
            title: 'Customer Complaint Response',
            instructions: 'Write an email responding to a customer who is upset that their order arrived two weeks late.',
            tone: 'Empathetic',
            minWords: 80,
            maxWords: 250,
          ),
          Challenge(
            id: 18,
            category: Category.email,
            title: 'Meeting Request',
            instructions: 'Write an email to a colleague requesting a 30-minute meeting to discuss next quarter\'s budget.',
            tone: 'Professional',
            minWords: 40,
            maxWords: 120,
          ),
        ];
        
      case Category.blogPost:
        return [
          Challenge(
            id: 3,
            category: Category.blogPost,
            title: 'My Favorite Hobby',
            instructions: 'Write a blog post about your favorite hobby.',
            tone: 'Informative',
            minWords: 300,
            maxWords: 1000,
          ),
          Challenge(
            id: 4,
            category: Category.blogPost,
            title: 'The Benefits of Meditation',
            instructions: 'Write a blog post about the benefits of meditation.',
            tone: 'Inspirational',
            minWords: 400,
            maxWords: 1200,
          ),
          Challenge(
            id: 19,
            category: Category.blogPost,
            title: 'A Beginner\'s Guide to Meal Prep',
            instructions: 'Write a blog post guiding complete beginners through planning and preparing a week of meals in one session.',
            tone: 'Informative',
            minWords: 400,
            maxWords: 1000,
          ),
          Challenge(
            id: 20,
            category: Category.blogPost,
            title: 'The Rise of Electric Vehicles',
            instructions: 'Write a blog post exploring why electric vehicle adoption is accelerating and what it means for everyday drivers.',
            tone: 'Analytical',
            minWords: 350,
            maxWords: 900,
          ),
        ];
        
      case Category.prompt:
        return [
          Challenge(
            id: 5,
            category: Category.prompt,
            title: 'AI Image Generation Prompt',
            instructions: 'Write a detailed prompt instructing an AI to generate an image of a futuristic cyberpunk city.',
            tone: 'Descriptive',
            minWords: 20,
            maxWords: 100,
          ),
          Challenge(
            id: 6,
            category: Category.prompt,
            title: 'Customer Service Bot Instructions',
            instructions: 'Write a system prompt instructing an AI chatbot on how to handle angry customer refund requests.',
            tone: 'Direct',
            minWords: 50,
            maxWords: 200,
          ),
          Challenge(
            id: 21,
            category: Category.prompt,
            title: 'Travel Itinerary Planner Prompt',
            instructions: 'Write a prompt that turns an AI into a travel planner asking clarifying questions before building a day-by-day itinerary.',
            tone: 'Detailed',
            minWords: 30,
            maxWords: 120,
          ),
          Challenge(
            id: 22,
            category: Category.prompt,
            title: 'SQL Query Assistant Prompt',
            instructions: 'Write a system prompt instructing an AI to translate plain-English questions into SQL queries and briefly explain each one.',
            tone: 'Technical',
            minWords: 40,
            maxWords: 150,
          ),
        ];
        
      case Category.report:
        return [
          Challenge(
            id: 7,
            category: Category.report,
            title: 'Quarterly Sales Summary',
            instructions: 'Write an executive summary for a Q3 sales report showing a 15% revenue increase.',
            tone: 'Professional',
            minWords: 100,
            maxWords: 300,
          ),
          Challenge(
            id: 8,
            category: Category.report,
            title: 'Competitor Analysis',
            instructions: 'Write a brief report analyzing the recent launch of a competitor\'s new software product.',
            tone: 'Analytical',
            minWords: 150,
            maxWords: 400,
          ),
          Challenge(
            id: 23,
            category: Category.report,
            title: 'Website Traffic Analysis',
            instructions: 'Write a report explaining a 40% drop in website traffic last month, covering likely causes and recommended actions.',
            tone: 'Analytical',
            minWords: 150,
            maxWords: 400,
          ),
          Challenge(
            id: 24,
            category: Category.report,
            title: 'Server Outage Postmortem',
            instructions: 'Write a postmortem report for a two-hour outage caused by an expired TLS certificate, including impact, root cause, and prevention steps.',
            tone: 'Formal',
            minWords: 120,
            maxWords: 350,
          ),
        ];
        
      case Category.socialMediaPost:
        return [
          Challenge(
            id: 9,
            category: Category.socialMediaPost,
            title: 'Product Launch Announcement',
            instructions: 'Write an Instagram caption announcing the launch of our new eco-friendly water bottle.',
            tone: 'Enthusiastic',
            minWords: 15,
            maxWords: 75,
          ),
          Challenge(
            id: 10,
            category: Category.socialMediaPost,
            title: 'Industry Conference Takeaway',
            instructions: 'Write a LinkedIn post sharing your top learning from a recent tech conference.',
            tone: 'Professional',
            minWords: 40,
            maxWords: 150,
          ),
          Challenge(
            id: 25,
            category: Category.socialMediaPost,
            title: 'Motivational Monday Post',
            instructions: 'Write a short X (Twitter) post encouraging followers to start the week with one small productive habit.',
            tone: 'Uplifting',
            minWords: 10,
            maxWords: 60,
          ),
          Challenge(
            id: 26,
            category: Category.socialMediaPost,
            title: 'Charity Campaign Post',
            instructions: 'Write an Instagram caption launching a month-long fundraising campaign for a local animal shelter.',
            tone: 'Heartfelt',
            minWords: 20,
            maxWords: 80,
          ),
        ];
        
      case Category.essay:
        return [
          Challenge(
            id: 11,
            category: Category.essay,
            title: 'The Impact of Remote Work',
            instructions: 'Write a short essay arguing for or against the long-term benefits of remote work.',
            tone: 'Academic',
            minWords: 300,
            maxWords: 800,
          ),
          Challenge(
            id: 12,
            category: Category.essay,
            title: 'Local Climate Solutions',
            instructions: 'Write a persuasive essay detailing practical steps local governments can take to combat climate change.',
            tone: 'Persuasive',
            minWords: 400,
            maxWords: 1000,
          ),
          Challenge(
            id: 27,
            category: Category.essay,
            title: 'Social Media and Teenagers',
            instructions: 'Write an academic essay examining the effects of social media use on the mental health of teenagers.',
            tone: 'Academic',
            minWords: 350,
            maxWords: 800,
          ),
          Challenge(
            id: 28,
            category: Category.essay,
            title: 'Is Homework Still Necessary?',
            instructions: 'Write a persuasive essay arguing whether homework should be reduced or eliminated in primary schools.',
            tone: 'Persuasive',
            minWords: 300,
            maxWords: 700,
          ),
        ];
        
      case Category.productDescription:
        return [
          Challenge(
            id: 13,
            category: Category.productDescription,
            title: 'Noise-Canceling Headphones',
            instructions: 'Write a compelling product description for high-end wireless noise-canceling headphones.',
            tone: 'Persuasive',
            minWords: 50,
            maxWords: 150,
          ),
          Challenge(
            id: 14,
            category: Category.productDescription,
            title: 'Ergonomic Office Chair',
            instructions: 'Write an engaging product description highlighting the back-support features of a new office chair.',
            tone: 'Informative',
            minWords: 50,
            maxWords: 200,
          ),
          Challenge(
            id: 29,
            category: Category.productDescription,
            title: 'Insulated Smart Water Bottle',
            instructions: 'Write a persuasive product description for a smart water bottle that tracks hydration and keeps drinks cold for 24 hours.',
            tone: 'Persuasive',
            minWords: 40,
            maxWords: 120,
          ),
          Challenge(
            id: 30,
            category: Category.productDescription,
            title: 'Mechanical Keyboard for Developers',
            instructions: 'Write a product description for a compact mechanical keyboard aimed at software developers, highlighting build quality and programmability.',
            tone: 'Informative',
            minWords: 60,
            maxWords: 160,
          ),
        ];
        
      case Category.technicalDocumentation:
        return [
          Challenge(
            id: 15,
            category: Category.technicalDocumentation,
            title: 'API Authentication Guide',
            instructions: 'Write a step-by-step guide explaining how developers can authenticate with our new REST API.',
            tone: 'Technical',
            minWords: 100,
            maxWords: 400,
          ),
          Challenge(
            id: 16,
            category: Category.technicalDocumentation,
            title: 'Software Installation Manual',
            instructions: 'Write clear instructions on how to install and configure the database software on a local machine.',
            tone: 'Clear',
            minWords: 80,
            maxWords: 300,
          ),
          Challenge(
            id: 31,
            category: Category.technicalDocumentation,
            title: 'Password Reset Procedure',
            instructions: 'Write an end-user guide explaining how to reset a forgotten account password, including what to do if the reset email never arrives.',
            tone: 'Clear',
            minWords: 60,
            maxWords: 200,
          ),
          Challenge(
            id: 32,
            category: Category.technicalDocumentation,
            title: 'Troubleshooting: App Won\'t Sync',
            instructions: 'Write a troubleshooting guide helping users fix a mobile app that refuses to sync data across devices.',
            tone: 'Technical',
            minWords: 80,
            maxWords: 250,
          ),
        ];
    }
  }
}