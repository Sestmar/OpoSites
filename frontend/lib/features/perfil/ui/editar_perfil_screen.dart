import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/perfil_provider.dart';

class EditarPerfilScreen extends ConsumerStatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  ConsumerState<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends ConsumerState<EditarPerfilScreen> {
  late TextEditingController _nombreController;
  late TextEditingController _ciudadController;
  late TextEditingController _fechaController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _ciudadController = TextEditingController();
    _fechaController = TextEditingController();

    // Cargar datos iniciales en el siguiente frame
    Future.microtask(() {
      final perfilAsync = ref.read(perfilProvider);
      perfilAsync.whenData((usuario) {
        _nombreController.text = usuario.nombre;
        _ciudadController.text = usuario.ciudad ?? '';
        if (usuario.fechaExamenObjetivo != null) {
          try {
            _selectedDate = DateTime.parse(usuario.fechaExamenObjetivo!);
            _fechaController.text =
                DateFormat('dd/MM/yyyy').format(_selectedDate!);
          } catch (_) {
            // Ignorar errores de fecha inválida
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ciudadController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _fechaController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    // Validar nombre
    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es obligatorio')),
      );
      return;
    }

    // Mostrar indicador de carga
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Guardando cambios...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      await ref.read(perfilNotifierProvider.notifier).updateMe(
            nombre: _nombreController.text.trim(),
            ciudad: _ciudadController.text.trim().isEmpty
                ? null
                : _ciudadController.text.trim(),
            fechaExamenObjetivo: _selectedDate?.toIso8601String().split('T')[0],
          );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            duration: Duration(seconds: 2),
          ),
        );
        // Volver a la pantalla anterior
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilProvider);
    final isUpdating = ref.watch(
      perfilNotifierProvider.select((s) => s.isLoading),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
      ),
      body: perfilAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Error al cargar los datos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(perfilProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Nombre ────────────────────────────────────────────────────
              Text(
                'Nombre',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nombreController,
                decoration: InputDecoration(
                  hintText: 'Tu nombre completo',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  enabled: !isUpdating,
                ),
                maxLines: 1,
              ),

              const SizedBox(height: 20),

              // ── Ciudad ────────────────────────────────────────────────────
              Text(
                'Ciudad (opcional)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ciudadController,
                decoration: InputDecoration(
                  hintText: 'Tu ciudad',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  enabled: !isUpdating,
                ),
                maxLines: 1,
              ),

              const SizedBox(height: 20),

              // ── Fecha de examen ────────────────────────────────────────────
              Text(
                'Fecha de examen objetivo',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fechaController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: 'Seleccionar fecha',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: isUpdating ? null : _pickDate,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Botones ────────────────────────────────────────────────────
              FilledButton(
                onPressed: isUpdating ? null : _saveProfile,
                child: isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar cambios'),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: isUpdating ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

