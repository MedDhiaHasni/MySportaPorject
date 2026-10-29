import 'package:flutter/material.dart';

import '../../Core/Theme/app_tokens.dart';
import '../booking_components.dart';
import '../feedback_components.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsetsDirectional.all(AppSpacing.md),
    this.onTap,
    this.margin = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? AppElevation.card
            : const [],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: card,
      ),
    );
  }
}

class VenueCard extends StatelessWidget {
  const VenueCard({
    required this.name,
    required this.sport,
    required this.rating,
    required this.distance,
    required this.price,
    required this.earliestSlot,
    required this.onTap,
    this.photoUrl,
    this.photoProvider,
    super.key,
  });

  final String name;
  final String? photoUrl;
  final ImageProvider? photoProvider;
  final String sport;
  final String rating;
  final String distance;
  final String price;
  final String earliestSlot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label:
          '$name, $sport, rating $rating, $distance, $price, earliest time $earliestSlot',
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _VenueImage(
                      photoUrl: photoUrl,
                      photoProvider: photoProvider,
                      placeholderColor: scheme.surfaceContainerHighest,
                      iconColor: scheme.secondary,
                    ),
                    PositionedDirectional(
                      top: AppSpacing.sm,
                      start: AppSpacing.sm,
                      child: SportChip(label: sport),
                    ),
                    PositionedDirectional(
                      top: AppSpacing.sm,
                      end: AppSpacing.sm,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: MatchdayColors.warning,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Text(rating, style: theme.textTheme.labelLarge),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.near_me_outlined,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            distance,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          price,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: scheme.secondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Earliest: $earliestSlot',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueImage extends StatelessWidget {
  const _VenueImage({
    required this.photoUrl,
    required this.photoProvider,
    required this.placeholderColor,
    required this.iconColor,
  });

  final String? photoUrl;
  final ImageProvider? photoProvider;
  final Color placeholderColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    Widget placeholder(BuildContext context, Object error, StackTrace? trace) =>
        ColoredBox(
          color: placeholderColor,
          child: Icon(Icons.stadium_outlined, size: 44, color: iconColor),
        );

    if (photoProvider != null) {
      return Image(
        image: photoProvider!,
        fit: BoxFit.cover,
        errorBuilder: placeholder,
      );
    }

    if (photoUrl == null || photoUrl!.isEmpty) {
      return placeholder(context, StateError('No venue photo'), null);
    }

    return Image.network(
      photoUrl!,
      fit: BoxFit.cover,
      errorBuilder: placeholder,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const LoadingSkeleton(height: 180);
      },
    );
  }
}

class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.supportingText,
    this.highlightColor,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? supportingText;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlightColor ?? theme.colorScheme.secondary;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: theme.textTheme.headlineSmall),
          Text(label, style: theme.textTheme.bodyMedium),
          if (supportingText != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(supportingText!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}
