import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../progreso/providers/progreso_provider.dart';

/// Pantalla de inicio — dashboard principal de la app.
///
/// Muestra un resumen rápido del estado del usuario y accesos directos
/// a los flujos más usados. No fuerza carga de providers: si los datos
/// ya están en memoria (de una visita previa a Progreso), se muestran;
/// si no, los accesos rápidos funcionan igual sin datos de racha/plan.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Racha: solo se muestra si el provider ya tiene datos (keepAlive).
    // No se llama a .load() desde Home — el usuario va a Progreso para eso.
    final rachaState = ref.watch(rachaNotifierProvider);
    final racha = rachaState.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('opoSites'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Encabezado ─────────────────────────────────────────────────────
          Text(
            '¡A estudiar!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Accede a tus herramientas de estudio.',
            style: TextStyle(color: Colors.grey.shade600),
          ),

          // ── Racha (si disponible) ──────────────────────────────────────────
          if (racha != null) ...[
            const SizedBox(height: 16),
            _RachaCard(
              rachaActual: racha.rachaActual,
              mejorRacha: racha.mejorRacha,
            ),
          ],

          const SizedBox(height: 24),

          // ── Accesos rápidos ────────────────────────────────────────────────
          Text(
            'Acceso rápido',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _QuickAccessCard(
                icon: Icons.quiz_outlined,
                color: Colors.blue,
                label: 'Test rápido',
                onTap: () => context.push(AppRoutes.practicarTests),
              ),
              _QuickAccessCard(
                icon: Icons.assignment_outlined,
                color: Colors.deepOrange,
                label: 'Simulacros',
                onTap: () => context.push(AppRoutes.practicarSimulacros),
              ),
              _QuickAccessCard(
                icon: Icons.today_outlined,
                color: Colors.orange,
                label: 'Plan de hoy',
                onTap: () => context.push(AppRoutes.planHoy),
              ),
              _QuickAccessCard(
                icon: Icons.newspaper_outlined,
                color: Colors.deepPurple,
                label: 'Noticias',
                onTap: () => context.push(AppRoutes.noticias),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Secundario ─────────────────────────────────────────────────────
          Text(
            'También disponible',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),

          _SecondaryTile(
            icon: Icons.calendar_month_outlined,
            color: Colors.green,
            label: 'Calendario',
            onTap: () => context.push(AppRoutes.calendario),
          ),
          _SecondaryTile(
            icon: Icons.bar_chart_outlined,
            color: Colors.teal,
            label: 'Mi progreso',
            onTap: () => context.go(AppRoutes.progreso),
          ),
          _SecondaryTile(
            icon: Icons.warning_amber_outlined,
            color: Colors.amber,
            label: 'Mis fallos',
            onTap: () => context.push(AppRoutes.testFallos),
          ),
          _SecondaryTile(
            icon: Icons.smart_toy_outlined,
            color: Colors.blueGrey,
            label: 'Chat IA',
            onTap: () => context.push(AppRoutes.chat),
          ),
        ],
      ),
    );
  }
}

// ── Widget de racha ────────────────────────────────────────────────────────────

class _RachaCard extends StatelessWidget {
  const _RachaCard({
    required this.rachaActual,
    required this.mejorRacha,
  });

  final int rachaActual;
  final int mejorRacha;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$rachaActual días de racha',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Mejor racha: $mejorRacha días',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grid de acceso rápido ──────────────────────────────────────────────────────

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Lista secundaria ───────────────────────────────────────────────────────────

class _SecondaryTile extends StatelessWidget {
  const _SecondaryTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
