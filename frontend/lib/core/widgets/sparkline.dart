import 'dart:math';

import 'package:flutter/material.dart';

/// Gráfica sparkline mini con área rellena — CustomPainter.
///
/// Diseñada para los stat tiles de la Home.
/// [points] deben ser al menos 2 valores. Si hay menos de 2, no se pinta nada.
class Sparkline extends StatelessWidget {
  final List<double> points;
  final Color color;
  final double strokeWidth;

  const Sparkline({
    super.key,
    required this.points,
    required this.color,
    this.strokeWidth = 1.6,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();
    return CustomPaint(
      painter: _SparklinePainter(points, color, strokeWidth),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;
  final double strokeWidth;

  const _SparklinePainter(this.points, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || size.isEmpty) return;

    final mn = points.reduce(min);
    final mx = points.reduce(max);
    final range = mx - mn;

    // Evitar división por cero si todos los valores son iguales
    final effectiveRange = range == 0 ? 1.0 : range;

    Offset pt(int i) => Offset(
          i / (points.length - 1) * size.width,
          size.height -
              ((points[i] - mn) / effectiveRange) * (size.height - 6) -
              3,
        );

    // Path de la línea
    final linePath = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(pt(i).dx, pt(i).dy);
    }

    // Path del área rellena
    final areaPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    // Gradiente del área
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.28), color.withOpacity(0)],
        ).createShader(Offset.zero & size),
    );

    // Línea
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.points != points || old.color != color;
}
