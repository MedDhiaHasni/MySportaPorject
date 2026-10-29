import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../Core/Theme/app_tokens.dart';
import 'Buttons/app_buttons.dart';

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
    final foreground = selected
        ? NightMatchColors.onAction
        : theme.colorScheme.onSurface;
    final chip = Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: selected
            ? NightMatchColors.actionLime
            : theme.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: selected
              ? NightMatchColors.actionLime
              : theme.colorScheme.outlineVariant,
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

class SportCategoryCircle extends StatelessWidget {
  const SportCategoryCircle({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? NightMatchColors.onAction
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: MediaQuery.of(context).disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: selected
                      ? NightMatchColors.actionLime
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  boxShadow: selected && theme.brightness == Brightness.dark
                      ? AppElevation.nightGlow
                      : const [],
                ),
                child: Icon(icon, color: foreground),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
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
            ? NightMatchColors.pendingBackgroundDark
            : NightMatchColors.pendingBackground,
        isDark
            ? NightMatchColors.pendingForegroundDark
            : NightMatchColors.pendingForeground,
        Icons.schedule_rounded,
        'Pending',
      ),
      ReservationStatus.confirmed => (
        isDark
            ? NightMatchColors.confirmedBackgroundDark
            : NightMatchColors.confirmedBackground,
        isDark
            ? NightMatchColors.confirmedForegroundDark
            : NightMatchColors.confirmedForeground,
        Icons.check_circle_outline_rounded,
        'Confirmed',
      ),
      ReservationStatus.cancelled => (
        isDark
            ? NightMatchColors.cancelledBackgroundDark
            : NightMatchColors.cancelledBackground,
        isDark
            ? NightMatchColors.cancelledForegroundDark
            : NightMatchColors.cancelledForeground,
        Icons.cancel_outlined,
        'Cancelled',
      ),
      ReservationStatus.refunded => (
        isDark
            ? NightMatchColors.refundedBackgroundDark
            : NightMatchColors.refundedBackground,
        isDark
            ? NightMatchColors.refundedForegroundDark
            : NightMatchColors.refundedForeground,
        Icons.currency_exchange_rounded,
        'Refunded',
      ),
    };
    final text = label ?? defaultLabel;
    return Semantics(
      label: text,
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
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
        ? NightMatchColors.onAction
        : scheme.onSurface;
    final background = selected
        ? NightMatchColors.actionLime
        : unavailable
        ? scheme.surfaceContainerHighest
        : scheme.surface;
    final statusLabel = selected
        ? 'selected'
        : unavailable
        ? 'unavailable'
        : 'available';
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: '$label, $statusLabel',
      child: OutlinedButton(
        onPressed: enabled
            ? () {
                HapticFeedback.selectionClick();
                onPressed!();
              }
            : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, 52),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.sm,
          ),
          backgroundColor: background,
          foregroundColor: foreground,
          side: BorderSide(
            color: selected ? NightMatchColors.actionLime : scheme.outline,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
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
            Flexible(child: Text(label, maxLines: 1)),
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
    final weekday =
        MaterialLocalizations.of(context).narrowWeekdays[date.weekday % 7];
    final foreground = selected
        ? NightMatchColors.onAction
        : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${MaterialLocalizations.of(context).formatFullDate(date)}${isToday ? ', today' : ''}',
      child: SizedBox(
        width: 64,
        height: 84,
        child: Material(
          color: selected
              ? NightMatchColors.actionLime
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.input),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: BorderRadius.circular(AppRadius.input),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(
                  color: selected
                      ? NightMatchColors.actionLime
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
                      color: selected
                          ? NightMatchColors.onAction
                          : scheme.onSurfaceVariant,
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
                      width: AppSpacing.xxs,
                      height: AppSpacing.xxs,
                      decoration: const BoxDecoration(
                        color: NightMatchColors.actionLime,
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

class StickyBookingBar extends StatelessWidget {
  const StickyBookingBar({
    required this.priceLabel,
    required this.onBook,
    required this.enabled,
    this.isLoading = false,
    this.bookLabel = 'Book now',
    super.key,
  });

  final String priceLabel;
  final VoidCallback onBook;
  final bool enabled;
  final bool isLoading;
  final String bookLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
        boxShadow: theme.brightness == Brightness.dark
            ? AppElevation.nightGlow
            : const [],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(priceLabel, style: theme.textTheme.titleMedium),
                Text(
                  'per hour',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppPrimaryButton(
            label: bookLabel,
            onPressed: enabled ? onBook : null,
            isLoading: isLoading,
            expand: false,
          ),
        ],
      ),
    );
  }
}
