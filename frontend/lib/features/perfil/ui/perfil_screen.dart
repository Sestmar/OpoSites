import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/router/app_router.dart';
import '../../auth/data/models/usuario_me.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/perfil_provider.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: perfilAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Error al cargar el perfil', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(perfilNotifierProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (usuario) => _PerfilContent(usuario: usuario),
      ),
    );
  }
}

// ── Contenido principal ────────────────────────────────────────────────────────

class _PerfilContent extends ConsumerWidget {
  const _PerfilContent({required this.usuario});

  final UsuarioMe usuario;

  String _buildFotoUrl(String path) {
    if (path.startsWith('http')) return path;
    return '${ApiEndpoints.baseUrl.replaceFirst('/api/v1', '')}$path';
  }

  String _formatFecha(String? isoDate) {
    if (isoDate == null) return 'No establecida';
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final foto = await picker.pickImage(source: ImageSource.gallery);
    if (foto == null) return;
    await ref.read(perfilNotifierProvider.notifier).uploadFoto(foto);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUploadingFoto = ref.watch(
      perfilNotifierProvider.select((s) => s.isLoading),
    );

    final fotoUrl =
        usuario.fotoPerfilUrl != null ? _buildFotoUrl(usuario.fotoPerfilUrl!) : null;

    final initials = usuario.nombre.isNotEmpty
        ? usuario.nombre.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase()
        : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Avatar ──────────────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage:
                          fotoUrl != null ? NetworkImage(fotoUrl) : null,
                      child: isUploadingFoto
                          ? const CircularProgressIndicator()
                          : fotoUrl == null
                              ? Text(
                                  initials,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                )
                              : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Cambiar foto'),
                  onPressed: isUploadingFoto
                      ? null
                      : () => _pickAndUpload(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Card de información ──────────────────────────────────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.person_outline,
                  label: 'Nombre',
                  value: usuario.nombre,
                ),
                const Divider(height: 1, indent: 56),
                _InfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: usuario.email,
                ),
                const Divider(height: 1, indent: 56),
                _InfoTile(
                  icon: Icons.location_on_outlined,
                  label: 'Ciudad',
                  value: usuario.ciudad ?? 'Sin ciudad',
                  valueColor: usuario.ciudad == null ? Colors.grey : null,
                ),
                const Divider(height: 1, indent: 56),
                _InfoTile(
                  icon: Icons.shield_outlined,
                  label: 'Oposición',
                  value: usuario.nombreRama ?? 'Sin oposición',
                  valueColor: usuario.nombreRama == null ? Colors.grey : null,
                ),
                const Divider(height: 1, indent: 56),
                _InfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Fecha examen',
                  value: _formatFecha(usuario.fechaExamenObjetivo),
                  valueColor:
                      usuario.fechaExamenObjetivo == null ? Colors.grey : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Acciones ─────────────────────────────────────────────────────────
          FilledButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar perfil'),
            onPressed: () => context.push(AppRoutes.editarPerfil),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            icon: const Icon(Icons.swap_horiz_outlined),
            label: const Text('Cambiar oposición'),
            onPressed: () async {
              await context.push(AppRoutes.cambiarOposicionPerfil);
              ref.invalidate(perfilNotifierProvider);
            },
          ),

          const SizedBox(height: 32),

          // ── Cerrar sesión ─────────────────────────────────────────────────
          OutlinedButton.icon(
            icon: const Icon(Icons.logout_outlined),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
            onPressed: () => _showLogoutDialog(context, ref),
          ),

          const SizedBox(height: 12),

          // ── Eliminar cuenta ────────────────────────────────────────────────
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar cuenta'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
            onPressed: () => _showDeleteAccountDialog(context, ref),
          ),

        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Se cerrará tu sesión en esta aplicación. Podrás volver a entrar con tu email y contraseña.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('¿Eliminar cuenta?'),
        content: const Text(
          'Esta acción es irreversible. Se eliminarán todos tus datos, progreso y configuración. '
          '¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await ref.read(perfilNotifierProvider.notifier).deleteAccount();
        if (context.mounted) {
          ref.read(authProvider.notifier).logout();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar cuenta: $e')),
          );
        }
      }
    }
  }
}

// ── Widget auxiliar: fila de información ──────────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
