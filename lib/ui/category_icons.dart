import 'package:flutter/material.dart';
import 'package:wriport/domain/models/challenge.dart';

/// UI mapping from [Category] to its icon.
///
/// Deliberately lives in the UI layer (as an extension) so the domain
/// stays pure Dart: `challenge.dart` must never import Flutter. Adding a
/// category means adding a case here — the compiler enforces it because
/// the switch expression is exhaustive.
extension CategoryIcons on Category {
  IconData get icon => switch (this) {
        Category.email => Icons.mail_outline,
        Category.blogPost => Icons.article_outlined,
        Category.prompt => Icons.smart_toy_outlined,
        Category.report => Icons.analytics_outlined,
        Category.socialMediaPost => Icons.campaign_outlined,
        Category.essay => Icons.history_edu,
        Category.productDescription => Icons.shopping_bag_outlined,
        Category.technicalDocumentation => Icons.integration_instructions_outlined,
      };
}