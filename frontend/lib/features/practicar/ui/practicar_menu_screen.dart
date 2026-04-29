import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../auth/providers/auth_provider.dart';

/// Pantalla del tab "Practicar".
///
/// Punto de entrada a los dos modos de práctica: Tests libres y Simulacros.
/// Desde aquí el usuario navega a [TestConfigScreen] o [SimulacrosListScreen],
/// ambas dentro de la misma rama del shell (preservan el estado al volver).
class PracticarMenuScreen extends ConsumerWidget {
  const PracticarMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practicar')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          _ModoCard(
            icon: Icons.quiz_outlined,
            color: Colors.blue,
            titulo: 'Tests libres',
            descripcion:
                'Practica preguntas por tema, dificultad o de forma aleatoria. '
                'Al terminar verás tu nota y los fallos.',
            onTap: () => context.push(AppRoutes.practicarTests),
          ),
          const SizedBox(height: 16),
          _ModoCard(
            icon: Icons.assignment_outlined,
            color: Colors.deepOrange,
            titulo: 'Simulacros',
            descripcion:
                'Reproduce las condiciones reales del examen: tiempo límite, '
                'número de preguntas y puntuación oficial.',
            onTap: () => context.push(AppRoutes.practicarSimulacros),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _ModoCard(
            icon: Icons.warning_amber_outlined,
            color: Colors.orange,
            titulo: 'Mis fallos',
            descripcion:
                'Repasa las preguntas que has fallado en tests anteriores '
                'para reforzar tus puntos débiles.',
            onTap: () => context.push(AppRoutes.testFallos),
          ),
        ],
      ),
    );
  }
}

class _ModoCard extends StatelessWidget {
  const _ModoCard({
    required this.icon,
    required this.color,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
