import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/evolucion_semanal.dart';
import '../data/models/progreso_tema.dart';
import '../data/models/racha.dart';
import '../providers/progreso_provider.dart';

// ── Pantalla principal ─────────────────────────────────────────────────────────

class ProgresoScreen extends ConsumerStatefulWidget {
  const ProgresoScreen({super.key});

  @override
  ConsumerState<ProgresoScreen> createState() => _ProgresoScreenState();
}

class _ProgresoScreenState extends ConsumerState<ProgresoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(progresoResumenNotifierProvider.notifier).load();
      ref.read(progresoTemasProvider.notifier).load();
      ref.read(progresoEvolucionProvider.notifier).load();
      ref.read(rachaNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Progreso')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ResumenSection(),
            SizedBox(height: 24),
            _RachaSection(),
            SizedBox(height: 24),
            _EvolucionSection(),
            SizedBox(height: 24),
            _TemasSection(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Sección: Resumen global ────────────────────────────────────────────────────

class _ResumenSection extends ConsumerWidget {
  const _ResumenSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progresoResumenNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Resumen global'),
        const SizedBox(height: 8),
        state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorTile(message: e.toString()),
          data: (resumen) {
            if (resumen == null) {
              return const _EmptyTile(
                message: 'Completá tu primer test para ver el resumen.',
              );
            }

            final fallos = resumen.totalRespondidas - resumen.totalCorrectas;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estadísticas principales
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Respondidas',
                          value: '${resumen.totalRespondidas}',
                        ),
                        _StatItem(
                          label: 'Correctas',
                          value: '${resumen.totalCorrectas}',
                        ),
                        _StatItem(
                          label: 'Fallos',
                          value: '$fallos',
                        ),
                        _StatItem(
                          label: 'Aciertos',
                          value:
                              '${resumen.porcentajeAciertosGlobal.toStringAsFixed(1)}%',
                          highlight: true,
                        ),
                      ],
                    ),
                    // Temas débiles
                    if (resumen.temasDebiles.isNotEmpty) ...[
                      const Divider(height: 24),
                      Text(
                        'Temas a reforzar',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      ...resumen.temasDebiles.map(
                        (t) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(t.nombre)),
                              Text(
                                '${t.porcentajeAcierto.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Sección: Racha ─────────────────────────────────────────────────────────────

class _RachaSection extends ConsumerWidget {
  const _RachaSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rachaNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Racha de estudio'),
        const SizedBox(height: 8),
        state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorTile(message: e.toString()),
          data: (racha) {
            if (racha == null) {
              return const _EmptyTile(
                message: 'Completá tu primer test para empezar tu racha.',
              );
            }
            return _RachaCard(racha: racha);
          },
        ),
      ],
    );
  }
}

class _RachaCard extends StatelessWidget {
  const _RachaCard({required this.racha});

  final Racha racha;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: 'Racha actual',
              value: '${racha.rachaActual} días',
              highlight: racha.rachaActual > 0,
            ),
            _StatItem(
              label: 'Mejor racha',
              value: '${racha.mejorRacha} días',
            ),
            _StatItem(
              label: 'Último estudio',
              value: racha.ultimoEstudio ?? '—',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sección: Gráfica de evolución semanal ─────────────────────────────────────

class _EvolucionSection extends ConsumerWidget {
  const _EvolucionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progresoEvolucionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Evolución semanal'),
        const SizedBox(height: 8),
        state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorTile(message: e.toString()),
          data: (evolucion) {
            if (evolucion.isEmpty) {
              return const _EmptyTile(
                message: 'Completá tests para ver tu evolución.',
              );
            }
            return _EvolucionChart(evolucion: evolucion);
          },
        ),
      ],
    );
  }
}

class _EvolucionChart extends StatelessWidget {
  const _EvolucionChart({required this.evolucion});

  final List<EvolucionSemanal> evolucion;

  @override
  Widget build(BuildContext context) {
    final spots = evolucion
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.notaMedia))
        .toList();

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 10,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: primaryColor,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: primaryColor.withOpacity(0.12),
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: 2,
                    getTitlesWidget: (value, _) => Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 2,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                ),
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => Colors.blueGrey.shade800,
                  getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                    final semana = evolucion[spot.x.toInt()].semana;
                    final tests =
                        evolucion[spot.x.toInt()].testsCompletados;
                    return LineTooltipItem(
                      '$semana\n${spot.y.toStringAsFixed(1)} / 10  ($tests tests)',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sección: Detalle por temas ─────────────────────────────────────────────────

class _TemasSection extends ConsumerWidget {
  const _TemasSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progresoTemasProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Por tema'),
        const SizedBox(height: 8),
        state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorTile(message: e.toString()),
          data: (temas) {
            if (temas.isEmpty) {
              return const _EmptyTile(
                message: 'Completá tests para ver estadísticas por tema.',
              );
            }
            return Column(
              children: temas.map((t) => _TemaTile(tema: t)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _TemaTile extends StatelessWidget {
  const _TemaTile({required this.tema});

  final ProgresoTema tema;

  @override
  Widget build(BuildContext context) {
    final porcentaje = tema.porcentajeAcierto / 100;
    final color = _colorForPorcentaje(porcentaje);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tema.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  '${tema.correctas}/${tema.totalRespondidas}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Text(
                  '${tema.porcentajeAcierto.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: porcentaje.clamp(0.0, 1.0),
                minHeight: 6,
                color: color,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForPorcentaje(double p) {
    if (p >= 0.75) return Colors.green;
    if (p >= 0.50) return Colors.orange;
    return Colors.red;
  }
}

// ── Widgets de apoyo ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: highlight
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _EmptyTile extends StatelessWidget {
  const _EmptyTile({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
