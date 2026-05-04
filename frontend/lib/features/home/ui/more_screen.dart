import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';

/// Pantalla del tab "Más".
///
/// Punto de acceso a todas las funcionalidades secundarias:
/// Noticias, Calendario, Plan de estudio, Chat IA y Perfil.
/// El logout se gestiona desde la pantalla de Perfil.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Más'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Contenidos ────────────────────────────────────────────────────
          _SectionHeader('Contenidos'),
          _MoreTile(
            icon: Icons.newspaper_outlined,
            color: Colors.blue,
            titulo: 'Noticias',
            subtitulo: 'Convocatorias y novedades de tu oposición',
            onTap: () => context.push(AppRoutes.noticias),
          ),
          _MoreTile(
            icon: Icons.calendar_month_outlined,
            color: Colors.green,
            titulo: 'Calendario',
            subtitulo: 'Eventos, simulacros y fechas importantes',
            onTap: () => context.push(AppRoutes.calendario),
          ),

          const Divider(indent: 16, endIndent: 16),

          // ── Plan de estudio ────────────────────────────────────────────────
          _SectionHeader('Plan de estudio'),
          _MoreTile(
            icon: Icons.today_outlined,
            color: Colors.orange,
            titulo: 'Plan de hoy',
            subtitulo: 'Tus tareas de estudio para hoy',
            onTap: () => context.push(AppRoutes.planHoy),
          ),
          _MoreTile(
            icon: Icons.tune_outlined,
            color: Colors.purple,
            titulo: 'Configurar plan',
            subtitulo: 'Horas, preferencia y fecha del examen',
            onTap: () => context.push(AppRoutes.planConfig),
          ),

          const Divider(indent: 16, endIndent: 16),

          const Divider(indent: 16, endIndent: 16),

          // ── IA ────────────────────────────────────────────────────────────
          _SectionHeader('Inteligencia artificial'),
          _MoreTile(
            icon: Icons.smart_toy_outlined,
            color: Colors.blueGrey,
            titulo: 'Chat IA',
            subtitulo: 'Consulta dudas con inteligencia artificial',
            onTap: () => context.push(AppRoutes.chat),
          ),
          _MoreTile(
            icon: Icons.auto_stories_outlined,
            color: Colors.deepPurple,
            titulo: 'Mis documentos',
            subtitulo: 'Sube tu temario y genera flashcards, resúmenes y más',
            onTap: () => context.push(AppRoutes.documentos),
          ),

          const Divider(indent: 16, endIndent: 16),

          // ── Cuenta ────────────────────────────────────────────────────────
          _SectionHeader('Cuenta'),
          _MoreTile(
            icon: Icons.person_outline,
            color: Colors.indigo,
            titulo: 'Mi perfil',
            subtitulo: 'Foto, datos personales y cerrar sesión',
            onTap: () => context.push(AppRoutes.perfil),
          ),
        ],
      ),
    );
  }
}

// ── Widgets de apoyo ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.color,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final Color color;
  final String titulo;
  final String subtitulo;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        titulo,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: onTap == null ? Colors.grey.shade400 : null,
        ),
      ),
      subtitle: Text(
        subtitulo,
        style: TextStyle(
          fontSize: 12,
          color: onTap == null ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
