import 'dart:math';
import 'package:flutter/material.dart';

/// Anillo de progreso circular animado.
///
/// Anima de 0 → [value] al montar con easing easeOutCubic durante 900ms.
/// Muestra el porcentaje como label centrado.
class ProgressRing extends StatefulWidget {
  /// Valor de 0 a 100.
  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Color trackColor;

  /// Estilo del label central. Si es null usa un tamaño proporcional a [size].
  final TextStyle? labelStyle;

  const ProgressRing({
    super.key,
    required this.value,
    this.size = 48,
    this.stroke = 4,
    required this.color,
    required this.trackColor,
    this.labelStyle,
  });

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final eased = Curves.easeOutCubic.transform(_ctrl.value);
        final shown = widget.value * eased;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(widget.size),
                painter: _RingPainter(
                  shown / 100,
                  widget.color,
                  widget.trackColor,
                  widget.stroke,
                ),
              ),
              Text(
                '${shown.round()}%',
                style: widget.labelStyle ??
                    TextStyle(
                      fontSize: widget.size * 0.26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                      color: widget.color,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0.0 – 1.0
  final Color color;
  final Color track;
  final double stroke;

  const _RingPainter(this.progress, this.color, this.track, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    // Progress arc — arranca en las 12 en punto (-π/2)
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        progress * 2 * pi,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
