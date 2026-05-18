import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../plan/data/models/plan_configuracion.dart';
import '../../../plan/providers/plan_provider.dart';

// ── Pantalla de onboarding extra ───────────────────────────────────────────────
//
// Aparece una sola vez, justo después de que el usuario selecciona su oposición.
// Recoge fecha de examen (paso 1) y horas de estudio por semana (paso 2).
// Ambos pasos son opcionales — el usuario puede saltar cada uno.
// Al terminar guarda los datos informados via PATCH /plan/configuracion.

class OnboardingExtraScreen extends ConsumerStatefulWidget {
  const OnboardingExtraScreen({super.key});

  @override
  ConsumerState<OnboardingExtraScreen> createState() =>
      _OnboardingExtraScreenState();
}

class _OnboardingExtraScreenState
    extends ConsumerState<OnboardingExtraScreen> {
  int _step = 0;

  // _calendarDate siempre tiene valor — es lo que muestra el calendario inline.
  DateTime _calendarDate = DateTime.now().add(const Duration(days: 90));
  // _fechaExamen solo se setea cuando el usuario confirma con "Continuar".
  DateTime? _fechaExamen;

  int _horasSemana = 10;
  bool _saving = false;

  // ── Finalizar ──────────────────────────────────────────────────────────────

  Future<void> _finalizar({bool saltarHoras = false}) async {
    setState(() => _saving = true);

    final fecha = _fechaExamen;
    final horas = saltarHoras ? null : _horasSemana;

    if (fecha != null || horas != null) {
      final fechaStr = fecha == null
          ? null
          : '${fecha.year.toString().padLeft(4, '0')}-'
              '${fecha.month.toString().padLeft(2, '0')}-'
              '${fecha.day.toString().padLeft(2, '0')}';

      await ref
          .read(planConfiguracionNotifierProvider.notifier)
          .actualizar(UpdatePlanConfiguracionRequest(
            horasSemana: horas,
            fechaExamenObjetivo: fechaStr,
          ));
    }

    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.18),
              AppColors.darkBg,
            ],
            stops: const [0.0, 0.48],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // ── Indicador de paso ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepDot(active: _step == 0, done: _step > 0),
                    const SizedBox(width: 8),
                    _StepDot(active: _step == 1, done: false),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Contenido del paso activo ──────────────────────────────
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.06, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _step == 0
                        ? _Step1Fecha(
                            key: const ValueKey(0),
                            calendarDate: _calendarDate,
                            onDateChanged: (d) =>
                                setState(() => _calendarDate = d),
                            onContinue: () => setState(() {
                              _fechaExamen = _calendarDate;
                              _step = 1;
                            }),
                            onSkip: () => setState(() => _step = 1),
                          )
                        : _Step2Horas(
                            key: const ValueKey(1),
                            horas: _horasSemana,
                            onHorasChanged: (h) =>
                                setState(() => _horasSemana = h),
                            onSkip: () => _finalizar(saltarHoras: true),
                            onContinue: _saving ? null : _finalizar,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Paso 1: fecha de examen ────────────────────────────────────────────────────

class _Step1Fecha extends StatelessWidget {
  const _Step1Fecha({
    super.key,
    required this.calendarDate,
    required this.onDateChanged,
    required this.onContinue,
    required this.onSkip,
  });

  final DateTime calendarDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  String _countdown() {
    final days = calendarDate.difference(DateTime.now()).inDays;
    if (days < 0) return 'Fecha en el pasado — elegí otra';
    if (days == 0) return 'Es hoy';
    if (days == 1) return '1 día hasta el examen';
    return '$days días hasta el examen';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Countdown chip ─────────────────────────────────────────────
        Align(
          alignment: Alignment.center,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.hourglass_bottom_rounded,
                  size: 14,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 6),
                Text(
                  _countdown(),
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Título ─────────────────────────────────────────────────────
        const Text(
          'Configurá tu\nfecha de examen',
          style: TextStyle(
            color: AppColors.darkText,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ajustamos la intensidad del plan\nsegún el tiempo que te queda.',
          style: TextStyle(
            color: AppColors.darkTextMuted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // ── Calendario compacto en español ─────────────────────────────
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 312),
            child: _SpanishCalendarPicker(
              selectedDate: calendarDate,
              firstDate: DateTime.now(),
              lastDate: DateTime(DateTime.now().year + 5),
              onDateChanged: onDateChanged,
            ),
          ),
        ),

        const Spacer(),

        // ── Acciones ───────────────────────────────────────────────────
        FilledButton(
          onPressed: onContinue,
          child: const Text('Continuar'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onSkip,
          child: const Text(
            'Saltar por ahora',
            style: TextStyle(color: AppColors.darkTextMuted),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Paso 2: horas de estudio ───────────────────────────────────────────────────

class _Step2Horas extends StatelessWidget {
  const _Step2Horas({
    super.key,
    required this.horas,
    required this.onHorasChanged,
    required this.onSkip,
    required this.onContinue,
  });

  final int horas;
  final ValueChanged<int> onHorasChanged;
  final VoidCallback onSkip;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Título ─────────────────────────────────────────────────────
        const Text(
          '¿Cuántas horas\npor semana?',
          style: TextStyle(
            color: AppColors.darkText,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'El plan distribuye las tareas según\nlas horas que tenés disponibles.',
          style: TextStyle(
            color: AppColors.darkTextMuted,
            fontSize: 14,
            height: 1.4,
          ),
        ),

        const Spacer(),

        // ── Rueda de volumen ───────────────────────────────────────────
        Center(
          child: _DialKnob(
            value: horas,
            min: 1,
            max: 40,
            onChanged: onHorasChanged,
          ),
        ),

        const Spacer(),

        // ── Acciones ───────────────────────────────────────────────────
        FilledButton(
          onPressed: onContinue,
          child: onContinue == null
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Empezar'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onSkip,
          child: const Text(
            'Saltar por ahora',
            style: TextStyle(color: AppColors.darkTextMuted),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Calendario personalizado en español ───────────────────────────────────────

class _SpanishCalendarPicker extends StatefulWidget {
  const _SpanishCalendarPicker({
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
  });

  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  State<_SpanishCalendarPicker> createState() =>
      _SpanishCalendarPickerState();
}

class _SpanishCalendarPickerState extends State<_SpanishCalendarPicker> {
  late DateTime _displayMonth;

  static const _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  // Semana empieza en lunes (convención española)
  static const _dayNames = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _displayMonth =
        DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  void _prevMonth() {
    final prev =
        DateTime(_displayMonth.year, _displayMonth.month - 1);
    final firstMonth =
        DateTime(widget.firstDate.year, widget.firstDate.month);
    if (!prev.isBefore(firstMonth)) {
      setState(() => _displayMonth = prev);
    }
  }

  void _nextMonth() {
    final next =
        DateTime(_displayMonth.year, _displayMonth.month + 1);
    final lastMonth =
        DateTime(widget.lastDate.year, widget.lastDate.month);
    if (!next.isAfter(lastMonth)) {
      setState(() => _displayMonth = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = _displayMonth.year;
    final month = _displayMonth.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    // Offset so the grid starts on Monday (weekday 1 = Monday → offset 0)
    final startOffset = firstDay.weekday - 1;
    final totalCells = startOffset + lastDay.day;
    final rows = (totalCells / 7).ceil();

    final canPrev = !DateTime(year, month - 1)
        .isBefore(DateTime(widget.firstDate.year, widget.firstDate.month));
    final canNext = !DateTime(year, month + 1)
        .isAfter(DateTime(widget.lastDate.year, widget.lastDate.month));

    final today = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.darkBorderStrong,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Cabecera: mes/año + navegación ──────────────────────────
          Row(
            children: [
              _NavButton(
                icon: Icons.chevron_left_rounded,
                enabled: canPrev,
                onTap: _prevMonth,
              ),
              Expanded(
                child: Text(
                  '${_monthNames[month - 1]} $year',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              _NavButton(
                icon: Icons.chevron_right_rounded,
                enabled: canNext,
                onTap: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Cabecera de días ────────────────────────────────────────
          Row(
            children: _dayNames
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            color: AppColors.darkTextMuted.withOpacity(0.7),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),

          // ── Grid de días ────────────────────────────────────────────
          ...List.generate(rows, (row) {
            return Row(
              children: List.generate(7, (col) {
                final index = row * 7 + col;
                final day = index - startOffset + 1;

                if (day < 1 || day > lastDay.day) {
                  return const Expanded(child: SizedBox(height: 34));
                }

                final date = DateTime(year, month, day);
                final isPast = date
                    .isBefore(DateTime(today.year, today.month, today.day));
                final isSelected = date.year == widget.selectedDate.year &&
                    date.month == widget.selectedDate.month &&
                    date.day == widget.selectedDate.day;
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;

                return Expanded(
                  child: GestureDetector(
                    onTap: isPast ? null : () => widget.onDateChanged(date),
                    child: Container(
                      height: 34,
                      margin: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.primaryDark
                            : isToday
                                ? AppColors.primary.withOpacity(0.14)
                                : null,
                        border: isToday && !isSelected
                            ? Border.all(
                                color: AppColors.primary.withOpacity(0.45),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.black
                                : isPast
                                    ? AppColors.darkTextFaint
                                    : AppColors.darkText,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? AppColors.primary.withOpacity(0.10)
              : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? AppColors.primaryDark
              : AppColors.darkTextFaint.withOpacity(0.4),
        ),
      ),
    );
  }
}

// ── Rueda de volumen ───────────────────────────────────────────────────────────

// El knob ocupa un espacio fijo de _kDialSize × _kDialSize.
// El arco empieza en la posición "8 en punto" y barre 240° en sentido horario
// hasta la posición "4 en punto" — igual que un mando de volumen analógico.

const _kDialSize = 228.0;
// startAngle en Flutter (0 = 3 h, sentido horario):
//   8 en punto = 150° = 5π/6
const _kDialStart = 5 * math.pi / 6;
// Barrido total del arco: 240° = 4π/3
const _kDialSweep = 4 * math.pi / 3;

class _DialKnob extends StatelessWidget {
  const _DialKnob({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  /// Convierte una posición local (relativa al centro del widget) en valor.
  int? _valueFromOffset(Offset localPos) {
    final center = const Offset(_kDialSize / 2, _kDialSize / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;

    // Ignorar toques muy cerca del centro (zona muerta interior)
    if (dx * dx + dy * dy < 900) return null;

    double angle = math.atan2(dy, dx);
    // Normalizar a [0, 2π)
    if (angle < 0) angle += 2 * math.pi;

    // Ángulo relativo al inicio del arco
    double rel = angle - _kDialStart;
    if (rel < 0) rel += 2 * math.pi;

    // Si cae en la zona muerta (los 120° de abajo), ignorar
    if (rel > _kDialSweep + 0.15) return null;

    final f = (rel / _kDialSweep).clamp(0.0, 1.0);
    return (min + f * (max - min)).round();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (d) {
        final v = _valueFromOffset(d.localPosition);
        if (v != null) onChanged(v);
      },
      onTapUp: (d) {
        final v = _valueFromOffset(d.localPosition);
        if (v != null) onChanged(v);
      },
      child: SizedBox(
        width: _kDialSize,
        height: _kDialSize,
        child: CustomPaint(
          painter: _DialPainter(value: value, min: min, max: max),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.value,
    required this.min,
    required this.max,
  });

  final int value;
  final int min;
  final int max;

  static const _trackWidth = 13.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // El radio del centro de la pista
    final trackR = size.shortestSide / 2 - _trackWidth / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: trackR);

    final fraction = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final activeSweep = fraction * _kDialSweep;

    // ── Aro exterior decorativo (muy sutil) ─────────────────────────────
    canvas.drawCircle(
      center,
      trackR + _trackWidth / 2 + 6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = AppColors.primary.withOpacity(0.10),
    );

    // ── Pista de fondo ───────────────────────────────────────────────────
    canvas.drawArc(
      rect,
      _kDialStart,
      _kDialSweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _trackWidth
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF12221E),
    );

    if (fraction > 0.005) {
      // ── Halo exterior del arco activo ────────────────────────────────
      canvas.drawArc(
        rect,
        _kDialStart,
        activeSweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _trackWidth + 8
          ..strokeCap = StrokeCap.round
          ..color = AppColors.primary.withOpacity(0.14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // ── Arco activo principal ────────────────────────────────────────
      final gradient = SweepGradient(
        startAngle: _kDialStart,
        endAngle: _kDialStart + _kDialSweep,
        colors: const [
          Color(0xFF1DE3C0),
          Color(0xFF0DB89A),
        ],
        tileMode: TileMode.clamp,
      );
      canvas.drawArc(
        rect,
        _kDialStart,
        activeSweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _trackWidth
          ..strokeCap = StrokeCap.round
          ..shader = gradient.createShader(rect),
      );

      // ── Punto indicador en la punta del arco ─────────────────────────
      final tipAngle = _kDialStart + activeSweep;
      final tipX = center.dx + trackR * math.cos(tipAngle);
      final tipY = center.dy + trackR * math.sin(tipAngle);

      // Halo del punto
      canvas.drawCircle(
        Offset(tipX, tipY),
        9,
        Paint()
          ..color = AppColors.primaryDark.withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // Punto blanco
      canvas.drawCircle(
        Offset(tipX, tipY),
        5,
        Paint()..color = Colors.white,
      );
    }

    // ── Etiquetas "1" y "40" en los extremos del arco ────────────────────
    final labelR = trackR + _trackWidth / 2 + 14;
    _paintLabel(canvas, '1',
        Offset(center.dx + labelR * math.cos(_kDialStart),
            center.dy + labelR * math.sin(_kDialStart)));
    _paintLabel(canvas, '40',
        Offset(center.dx + labelR * math.cos(_kDialStart + _kDialSweep),
            center.dy + labelR * math.sin(_kDialStart + _kDialSweep)));

    // ── Texto central: valor ─────────────────────────────────────────────
    final valTp = TextPainter(
      text: TextSpan(
        text: '$value',
        style: TextStyle(
          color: fraction > 0.005
              ? AppColors.primaryDark
              : AppColors.darkTextMuted,
          fontSize: 58,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    valTp.paint(
      canvas,
      center + Offset(-valTp.width / 2, -valTp.height / 2 - 8),
    );

    // ── Texto central: unidad ────────────────────────────────────────────
    final unitTp = TextPainter(
      text: const TextSpan(
        text: 'horas / semana',
        style: TextStyle(
          color: AppColors.darkTextMuted,
          fontSize: 12,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    unitTp.paint(
      canvas,
      center +
          Offset(-unitTp.width / 2, valTp.height / 2 - 8),
    );
  }

  void _paintLabel(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.darkTextFaint,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.value != value;
}

// ── Indicador de paso ──────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  const _StepDot({required this.active, required this.done});

  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: (active || done)
            ? AppColors.primaryDark
            : AppColors.darkBorderStrong,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
