import 'package:flutter/material.dart';

class InfoSectionCard extends StatelessWidget {
  const InfoSectionCard({
    super.key,
    required this.title,
    required this.icon,
    this.content,
    this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.contentOpacity = 1.0,
  }) : assert(content != null || child != null, 'Must provide either content string or a custom child widget');

  final String title;
  final IconData icon;
  final String? content;
  final Widget? child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double contentOpacity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    // Default to secondary container colors if none are provided
    final bg = backgroundColor ?? scheme.secondaryContainer;
    final fg = foregroundColor ?? scheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Render either the custom widget or the standard text
          if (child != null)
            child!
          else if (content != null)
            Text(
              content!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    // Apply the requested opacity to the text color
                    color: fg.withValues(alpha: contentOpacity), 
                  ),
            ),
        ],
      ),
    );
  }
}