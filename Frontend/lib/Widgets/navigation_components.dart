import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../Core/Theme/app_tokens.dart';

class PlayerNavDestination {
  const PlayerNavDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class FloatingBottomNav extends StatelessWidget {
  const FloatingBottomNav({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final List<PlayerNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: bottom > 0 ? AppSpacing.xs : AppSpacing.md,
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsetsDirectional.all(AppSpacing.xxs),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: theme.brightness == Brightness.dark
              ? AppElevation.nightGlow
              : [
                  BoxShadow(
                    color: NightMatchColors.onAction.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          children: [
            for (var index = 0; index < destinations.length; index++)
              Expanded(
                child: _NavItem(
                  destination: destinations[index],
                  selected: selectedIndex == index,
                  onTap: () => onDestinationSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final PlayerNavDestination destination;
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
      label: destination.label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Material(
          color: selected ? NightMatchColors.actionLime : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.xxs,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(destination.icon, color: foreground),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
