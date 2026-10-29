import 'package:flutter/material.dart';

import '../Core/Theme/app_tokens.dart';

enum TimeSlotState { available, selected, unavailable }

enum ReservationStatus { pending, confirmed, cancelled, refunded }

class SportChip extends StatelessWidget {
  const SportChip({
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    super.key,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected ? scheme.onSecondaryContainer : scheme.secondary;
    final background = selected
        ? scheme.secondaryContainer
        : scheme.surface.withValues(alpha: 0.96);
    final chip = Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: selected ? scheme.secondary : scheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: foreground),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(child: chip),
        ),
      ),
    );
  }
}

class ReservationStatusBadge extends StatelessWidget {
  const ReservationStatusBadge({
    required this.status,
    this.label,
    super.key,
  });

  final ReservationStatus status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (background, foreground, icon, defaultLabel) = switch (status) {
      ReservationStatus.pending => (
        isDark
            ? MatchdayColors.pendingBackgroundDark
            : MatchdayColors.pendingBackground,
        isDark
            ? MatchdayColors.pendingForegroundDark
            : MatchdayColors.pendingForeground,
        Icons.schedule_rounded,
        'Pending',
      ),
      ReservationStatus.confirmed => (
        isDark
            ? MatchdayColors.confirmedBackgroundDark
            : MatchdayColors.confirmedBackground,
        isDark
            ? MatchdayColors.confirmedForegroundDark
            : MatchdayColors.confirmedForeground,
        Icons.check_circle_outline_rounded,
        'Confirmed',
      ),
      ReservationStatus.cancelled => (
        isDark
            ? MatchdayColors.cancelledBackgroundDark
            : MatchdayColors.cancelledBackground,
        isDark
            ? MatchdayColors.cancelledForegroundDark
            : MatchdayColors.cancelledForeground,
        Icons.cancel_outlined,
        'Cancelled',
      ),
      ReservationStatus.refunded => (
        isDark
            ? MatchdayColors.refundedBackgroundDark
            : MatchdayColors.refundedBackground,
        isDark
            ? MatchdayColors.refundedForegroundDark
            : MatchdayColors.refundedForeground,
        Icons.currency_exchange_rounded,
        'Refunded',
      ),
    };
    final text = label ?? defaultLabel;

    return Semantics(
      label: text,
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: AppSpacing.xs),
            Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimeSlotButton extends StatelessWidget {
  const TimeSlotButton({
    required this.label,
    required this.state,
    required this.onPressed,
    super.key,
  });

  final String label;
  final TimeSlotState state;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = state == TimeSlotState.selected;
    final unavailable = state == TimeSlotState.unavailable;
    final enabled = !unavailable && onPressed != null;
    final foreground = selected
        ? Colors.white
        : unavailable
        ? scheme.onSurfaceVariant
        : scheme.onSurface;
    final background = selected
        ? MatchdayColors.brand
        : unavailable
        ? scheme.surfaceContainerHighest
        : scheme.surface;
    final border = selected ? MatchdayColors.brand : scheme.outline;
    final stateText = selected
        ? 'selected'
        : unavailable
        ? 'unavailable'
        : 'available';

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: '$label, $stateText',
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, 48),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.sm,
          ),
          backgroundColor: background,
          foregroundColor: foreground,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 18),
              const SizedBox(width: AppSpacing.xxs),
            ],
            if (unavailable) ...[
              const Icon(Icons.block_rounded, size: 16),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Text(label, maxLines: 1),
          ],
        ),
      ),
    );
  }
}

class DateRailItem extends StatelessWidget {
  const DateRailItem({
    required this.date,
    required this.selected,
    required this.onTap,
    this.isToday = false,
    super.key,
  });

  final DateTime date;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final weekday =
        MaterialLocalizations.of(context).narrowWeekdays[date.weekday % 7];
    final foreground = selected
        ? (isDark ? scheme.onSecondaryContainer : Colors.white)
        : scheme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      label:
          '${MaterialLocalizations.of(context).formatFullDate(date)}${isToday ? ', today' : ''}',
      child: SizedBox(
        width: 64,
        height: 72,
        child: Material(
          color: selected
              ? (isDark ? scheme.secondaryContainer : MatchdayColors.brand)
              : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: selected
                      ? (isDark ? scheme.secondary : MatchdayColors.brand)
                      : scheme.outlineVariant,
                ),
              ),
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppSpacing.xs,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isToday ? 'Today' : weekday,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: selected ? Colors.white : scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isToday && !selected)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
