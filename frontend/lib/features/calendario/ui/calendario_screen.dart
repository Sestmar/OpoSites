import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../data/models/calendario_evento.dart';
import '../providers/calendario_provider.dart';

// ── Pantalla principal ─────────────────────────────────────────────────────────

class CalendarioScreen extends ConsumerStatefulWidget {
  const CalendarioScreen({super.key});

  @override
  ConsumerState<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends ConsumerState<CalendarioScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _selectedDay = _normalizarDia(hoy);
    _focusedDay = hoy;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calendarioNotifierProvider.notifier).cargarMes(hoy);
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  DateTime _normalizarDia(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _isoSinZona(DateTime dt) =>
      dt.toIso8601String().substring(0, 19);

  static bool _mismoDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<CalendarioEvento> _eventosParaDia(
    DateTime dia,
    List<CalendarioEvento> todos,
  ) =>
      todos.where((e) {
        final f = DateTime.tryParse(e.fechaInicio);
        return f != null && _mismoDay(f, dia);
      }).toList();

  String _labelDia(DateTime dia) {
    final hoy = DateTime.now();
    if (_mismoDay(dia, hoy)) return 'Hoy';
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    const diasSem = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    final ds = diasSem[(dia.weekday - 1) % 7];
    return '$ds ${dia.day} de ${meses[dia.month - 1]}';
  }

  // ── Acciones ─────────────────────────────────────────────────────────────────

  void _reload() =>
      ref.read(calendarioNotifierProvider.notifier).cargarMes(_focusedDay);

  Future<void> _showCreateDialog() async {
    final result = await showDialog<_EventoFormData>(
      context: context,
      builder: (_) => _EventoFormDialog(fechaInicial: _selectedDay),
    );
    if (result == null || !mounted) return;
    _crearEvento(result);
  }

  Future<void> _showEditDialog(CalendarioEvento evento) async {
    final fechaInicio = DateTime.tryParse(evento.fechaInicio) ?? _selectedDay;
    final fechaFin =
        evento.fechaFin != null ? DateTime.tryParse(evento.fechaFin!) : null;

    final result = await showDialog<_EventoFormData>(
      context: context,
      builder: (_) => _EventoFormDialog(
        fechaInicial: fechaInicio,
        tituloInicial: evento.titulo,
        descripcionInicial: evento.descripcion,
        fechaFinInicial: fechaFin,
      ),
    );
    if (result == null || !mounted) return;
    _actualizarEvento(evento.id, result);
  }

  Future<void> _confirmarEliminar(CalendarioEvento evento) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: Text('¿Eliminás "${evento.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _eliminarEvento(evento.id);
  }

  Future<void> _crearEvento(_EventoFormData data) async {
    final request = CreateEventoRequest(
      titulo: data.titulo,
      descripcion: data.descripcion?.isNotEmpty == true
          ? data.descripcion
          : null,
      fechaInicio: _isoSinZona(data.fechaInicio),
      fechaFin:
          data.fechaFin != null ? _isoSinZona(data.fechaFin!) : null,
      tipo: TipoEvento.manual,
    );
    try {
      await ref
          .read(calendarioNotifierProvider.notifier)
          .crearEvento(request);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear evento: $e')),
        );
      }
    }
  }

  Future<void> _actualizarEvento(int id, _EventoFormData data) async {
    final request = UpdateEventoRequest(
      titulo: data.titulo,
      descripcion: data.descripcion?.isNotEmpty == true
          ? data.descripcion
          : null,
      fechaInicio: _isoSinZona(data.fechaInicio),
      fechaFin:
          data.fechaFin != null ? _isoSinZona(data.fechaFin!) : null,
    );
    try {
      await ref
          .read(calendarioNotifierProvider.notifier)
          .actualizarEvento(id, request);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar evento: $e')),
        );
      }
    }
  }

  Future<void> _eliminarEvento(int id) async {
    try {
      await ref
          .read(calendarioNotifierProvider.notifier)
          .eliminarEvento(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar evento: $e')),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarioNotifierProvider);
    final todosEventos = state.valueOrNull ?? [];
    final cargandoInicial = state.isLoading && todosEventos.isEmpty;
    final errorSinDatos = state.hasError && todosEventos.isEmpty;

    if (cargandoInicial) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calendario')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorSinDatos) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calendario')),
        body: _ErrorBody(
          message: state.error.toString(),
          onRetry: _reload,
        ),
      );
    }

    // Ya hay datos — mostrar calendario aunque esté recargando otro mes.
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario')),
      body: Column(
        children: [
          // Barra de progreso fina al cambiar de mes (sin ocultar el calendario)
          if (state.isLoading)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),

          // ── Calendario mensual ──────────────────────────────────────────────
          TableCalendar<CalendarioEvento>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => _mismoDay(day, _selectedDay),
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
            eventLoader: (day) => _eventosParaDia(day, todosEventos),
            onDaySelected: (selected, focused) => setState(() {
              _selectedDay = _normalizarDia(selected);
              _focusedDay = focused;
            }),
            onPageChanged: (focused) {
              setState(() => _focusedDay = focused);
              ref
                  .read(calendarioNotifierProvider.notifier)
                  .cargarMes(focused);
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              todayDecoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),

          const Divider(height: 1),

          // ── Cabecera del día ────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text(
                  _labelDia(_selectedDay),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

          // ── Lista de eventos del día ────────────────────────────────────────
          Expanded(
            child: _EventosDiaSection(
              dia: _selectedDay,
              onEditar: _showEditDialog,
              onEliminar: _confirmarEliminar,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        tooltip: 'Añadir evento',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Sección de eventos del día (Consumer) ──────────────────────────────────────

class _EventosDiaSection extends ConsumerWidget {
  const _EventosDiaSection({
    required this.dia,
    required this.onEditar,
    required this.onEliminar,
  });

  final DateTime dia;
  final ValueChanged<CalendarioEvento> onEditar;
  final ValueChanged<CalendarioEvento> onEliminar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventos = ref.watch(eventosDiaProvider(dia));

    if (eventos.isEmpty) {
      return Center(
        child: Text(
          'No hay eventos para este día.',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: eventos.length,
      itemBuilder: (_, i) => _EventoTile(
        evento: eventos[i],
        onEditar:
            eventos[i].autoGenerado ? null : () => onEditar(eventos[i]),
        onEliminar:
            eventos[i].autoGenerado ? null : () => onEliminar(eventos[i]),
      ),
    );
  }
}

// ── Tile de evento ─────────────────────────────────────────────────────────────

class _EventoTile extends StatelessWidget {
  const _EventoTile({
    required this.evento,
    this.onEditar,
    this.onEliminar,
  });

  final CalendarioEvento evento;
  final VoidCallback? onEditar;   // null → solo lectura
  final VoidCallback? onEliminar; // null → solo lectura

  @override
  Widget build(BuildContext context) {
    final color = _eventoColor(evento.tipo);
    final horaStr = _extraerHora(evento.fechaInicio);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Borde de color por tipo
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            evento.titulo,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _TipoBadge(tipo: evento.tipo),
                              if (horaStr != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  horaStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                              if (evento.autoGenerado) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.lock_outline,
                                  size: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ],
                          ),
                          if (evento.descripcion != null &&
                              evento.descripcion!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              evento.descripcion!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Acciones (solo para eventos manuales)
                    if (onEditar != null || onEliminar != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onEditar != null)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: onEditar,
                              tooltip: 'Editar',
                              visualDensity: VisualDensity.compact,
                            ),
                          if (onEliminar != null)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red,
                              ),
                              onPressed: onEliminar,
                              tooltip: 'Eliminar',
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Extrae "HH:mm" de un ISO 8601 si la hora no es medianoche.
  static String? _extraerHora(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null || (dt.hour == 0 && dt.minute == 0)) return null;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Badge de tipo de evento ────────────────────────────────────────────────────

class _TipoBadge extends StatelessWidget {
  const _TipoBadge({required this.tipo});

  final TipoEvento tipo;

  @override
  Widget build(BuildContext context) {
    final color = _eventoColor(tipo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _eventoLabel(tipo),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

Color _eventoColor(TipoEvento tipo) => switch (tipo) {
      TipoEvento.estudio => Colors.green,
      TipoEvento.simulacro => Colors.blue,
      TipoEvento.convocatoria => Colors.deepPurple,
      TipoEvento.manual => Colors.blueGrey,
    };

String _eventoLabel(TipoEvento tipo) => switch (tipo) {
      TipoEvento.estudio => 'Estudio',
      TipoEvento.simulacro => 'Simulacro',
      TipoEvento.convocatoria => 'Convocatoria',
      TipoEvento.manual => 'Personal',
    };

// ── Formulario de evento ───────────────────────────────────────────────────────

/// Datos que devuelve el formulario al caller.
/// El caller decide si construir [CreateEventoRequest] o [UpdateEventoRequest].
class _EventoFormData {
  const _EventoFormData({
    required this.titulo,
    required this.fechaInicio,
    this.descripcion,
    this.fechaFin,
  });

  final String titulo;
  final String? descripcion;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
}

/// Diálogo de creación/edición de eventos manuales.
///
/// Devuelve [_EventoFormData] vía [Navigator.pop] o null si se cancela.
class _EventoFormDialog extends StatefulWidget {
  const _EventoFormDialog({
    required this.fechaInicial,
    this.tituloInicial,
    this.descripcionInicial,
    this.fechaFinInicial,
  });

  final DateTime fechaInicial;
  final String? tituloInicial;
  final String? descripcionInicial;
  final DateTime? fechaFinInicial;

  @override
  State<_EventoFormDialog> createState() => _EventoFormDialogState();
}

class _EventoFormDialogState extends State<_EventoFormDialog> {
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descripcionCtrl;
  late DateTime _fecha;
  TimeOfDay? _hora;
  TimeOfDay? _horaFin;

  @override
  void initState() {
    super.initState();
    _tituloCtrl =
        TextEditingController(text: widget.tituloInicial ?? '');
    _descripcionCtrl =
        TextEditingController(text: widget.descripcionInicial ?? '');
    _fecha = widget.fechaInicial;

    // Pre-cargar hora desde la fecha inicial (si no es medianoche)
    if (widget.fechaInicial.hour != 0 || widget.fechaInicial.minute != 0) {
      _hora = TimeOfDay(
        hour: widget.fechaInicial.hour,
        minute: widget.fechaInicial.minute,
      );
    }
    if (widget.fechaFinInicial != null &&
        (widget.fechaFinInicial!.hour != 0 ||
            widget.fechaFinInicial!.minute != 0)) {
      _horaFin = TimeOfDay(
        hour: widget.fechaFinInicial!.hour,
        minute: widget.fechaFinInicial!.minute,
      );
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _pickHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hora ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _hora = picked);
  }

  Future<void> _pickHoraFin() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaFin ?? _hora ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _horaFin = picked);
  }

  void _submit() {
    final titulo = _tituloCtrl.text.trim();
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título es obligatorio')),
      );
      return;
    }

    final h = _hora?.hour ?? 0;
    final m = _hora?.minute ?? 0;
    final fechaInicio = DateTime(_fecha.year, _fecha.month, _fecha.day, h, m);

    DateTime? fechaFin;
    if (_horaFin != null) {
      fechaFin = DateTime(
        _fecha.year, _fecha.month, _fecha.day,
        _horaFin!.hour, _horaFin!.minute,
      );
    }

    Navigator.pop(
      context,
      _EventoFormData(
        titulo: titulo,
        descripcion: _descripcionCtrl.text.trim(),
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      ),
    );
  }

  String _formatFecha(DateTime d) {
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day} de ${meses[d.month - 1]} de ${d.year}';
  }

  String _formatHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.tituloInicial != null;

    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Título del diálogo ──
            Text(
              esEdicion ? 'Editar evento' : 'Nuevo evento',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // ── Título del evento ──
            TextField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(
                labelText: 'Título *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: 12),

            // ── Fecha ──
            OutlinedButton.icon(
              onPressed: _pickFecha,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(_formatFecha(_fecha)),
            ),
            const SizedBox(height: 8),

            // ── Hora inicio ──
            Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: _pickHora,
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(
                    _hora != null ? _formatHora(_hora!) : 'Hora inicio',
                  ),
                ),
                if (_hora != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: _pickHoraFin,
                    icon: const Icon(Icons.access_time_filled, size: 16),
                    label: Text(
                      _horaFin != null ? _formatHoraFin() : 'Hora fin',
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // ── Descripción ──
            TextField(
              controller: _descripcionCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            // ── Botones ──
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: _submit,
                  child: Text(esEdicion ? 'Guardar' : 'Crear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatHoraFin() =>
      _horaFin != null ? _formatHora(_horaFin!) : '';
}

// ── Estado error ───────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
