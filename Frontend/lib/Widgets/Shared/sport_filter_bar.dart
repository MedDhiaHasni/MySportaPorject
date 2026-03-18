import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Models/app_enums.dart';

class SportFilterBar extends StatelessWidget {
  final SportType? selected; // The currently selected sport type
  final ValueChanged<SportType?>
  onChanged; // Callback when a sport type is selected/deselected
  const SportFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _all = [
    SportType.football,
    SportType.padel,
    SportType.tennis,
    SportType.basketball,
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        _Pill(
          // pill is a small rounded button
          label: 'All',
          icon: Icons.sports_rounded,
          selected:
              selected ==
              null, // "All" is selected when no specific sport is selected
          onTap: () => onChanged(
            null,
          ), // Deselect any specific sport when "All" is tapped
        ),
        ..._all.map(
          // Generate a pill for each sport type
          (s) => _Pill(
            // s is the current sport type in the loop
            label: s.label,
            icon: s.icon,
            selected: selected == s,
            onTap: () => onChanged(selected == s ? null : s),
          ),
        ),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? kPrimary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: selected ? Colors.white : Colors.grey[500],
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey[600],
            ),
          ),
        ],
      ),
    ),
  );
}
