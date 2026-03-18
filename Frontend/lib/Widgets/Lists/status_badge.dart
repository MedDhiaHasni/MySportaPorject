import 'package:flutter/material.dart';

class StatusBadge extends StatefulWidget {
  final String label;
  final Color color;
  const StatusBadge({super.key, required this.label, required this.color});
  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge> {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: widget.color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      widget.label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: widget.color,
      ),
    ),
  );
}
