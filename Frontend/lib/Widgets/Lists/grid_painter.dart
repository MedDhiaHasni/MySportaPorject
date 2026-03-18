import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final Color color;
  const GridPainter({this.color = Colors.white});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withOpacity(0.055)
      ..strokeWidth =
          1; // A paint object that defines the color and stroke width for drawing the grid lines, using a very light opacity for a subtle effect
    for (double x = 0; x < size.width; x += 32)
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        p,
      ); // Draw vertical lines every 32 pixels across the width of the canvas
    for (double y = 0; y < size.height; y += 32)
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        p,
      ); // Draw horizontal lines every 32 pixels across the height of the canvas
  }

  @override
  bool shouldRepaint(_) => false; // Indicates that the painter does not need to repaint when the widget is updated, since the grid is static and does not depend on any changing properties
}
