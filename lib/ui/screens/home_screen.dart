// home page is going to contain
// a greeting to the user based on the time of day,
// a list of skills (challenges) to choose from the challenges model enum categories,
// and a theme mode toggle in the app bar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wriport/router.dart';
import 'package:wriport/domain/models/challenge.dart';
import 'package:wriport/providers.dart';
import 'package:wriport/ui/category_icons.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(Providers.themeModeProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 720;
    final hPad = width > 932 ? (width - 900) / 2 : 16.0;

    final user = ref.watch(Providers.currentUserProvider);
    final name = user?.displayName?.trim();
    final displayName = (name != null && name.isNotEmpty)
        ? name
        : user?.email.split('@').first ?? 'Writer';

    final categories = Category.values;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('Wriport'),
            actions: [
              IconButton(
                tooltip: 'History',
                onPressed: () => context.push(AppRouter.history),
                icon: const Icon(Icons.history_outlined),
              ),
              IconButton(
                tooltip: themeMode == ThemeMode.dark
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                onPressed: () {
                  ref.read(Providers.themeModeProvider.notifier).changeTheme(
                        themeMode == ThemeMode.dark
                            ? ThemeMode.light
                            : ThemeMode.dark,
                      );
                },
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    themeMode == ThemeMode.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    key: ValueKey<ThemeMode>(themeMode),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Sign out',
                onPressed: () async {
                  await ref.read(Providers.authRepositoryProvider).signOut();
                },
                icon: const Icon(Icons.logout_outlined),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 32),
              sliver: SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: _GreetingHero(
                      title: '$_greeting, $displayName!',
                      subtitle: 'What would you like to practice today?',
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  if (isWide)
                    SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 320,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent: 240,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return _CategoryCard(
                          category: category,
                          compact: false,
                          onTap: () =>
                              context.go(AppRouter.challengeList(category)),
                        );
                      },
                    )
                  else
                    SliverList.separated(
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return _CategoryCard(
                          category: category,
                          compact: true,
                          onTap: () =>
                              context.go(AppRouter.challengeList(category)),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private UI building blocks
// ---------------------------------------------------------------------------

class _GreetingHero extends StatelessWidget {
  const _GreetingHero({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: textTheme.bodyLarge?.copyWith(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onTap,
    required this.compact,
  });

  final Category category;
  final VoidCallback onTap;

  /// Compact = horizontal layout for phones; otherwise tall card for grids.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final avatar = CircleAvatar(
      radius: 24,
      backgroundColor: scheme.primaryContainer,
      child: Icon(category.icon, color: scheme.onPrimaryContainer),
    );

    final title = Text(
      category.label,
      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    final description = Text(
      category.description,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: compact
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    avatar,
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          title,
                          const SizedBox(height: 4),
                          description,
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20, color: scheme.primary),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    avatar,
                    const SizedBox(height: 16),
                    title,
                    const SizedBox(height: 6),
                    Expanded(child: description),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Browse challenges',
                          style: textTheme.labelLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward,
                            size: 16, color: scheme.primary),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}