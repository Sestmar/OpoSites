import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../data/models/repaso_models.dart';
import '../providers/repaso_provider.dart';

class RepasoActiveScreen extends ConsumerStatefulWidget {
  const RepasoActiveScreen({super.key});

  @override
  ConsumerState<RepasoActiveScreen> createState() => _RepasoActiveScreenState();
}

class _RepasoActiveScreenState extends ConsumerState<RepasoActiveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(repasoNotifierProvider.notifier).iniciar();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<RepasoState>>(repasoNotifierProvider, (_, next) {
      if (next.valueOrNull?.completada == true &&
          next.valueOrNull?.mostrandoFeedback == false) {
        final sesionId = next.valueOrNull?.sesion.sesionId;
        if (sesionId != null) {
          context.pushReplacement(AppRoutes.repasoResultado(sesionId));
        }
      }
    });

    final state = ref.watch(repasoNotifierProvider);

    return state.when(
      loading: () => const _CargandoScaffold(),
      error: (e, _) => _ErrorScaffold(
        message: e.toString(),
        onRetry: () => ref.read(repasoNotifierProvider.notifier).iniciar(),
      ),
      data: (s) => _RepasoBody(state: s),
    );
  }
}

// ── Cuerpo principal ──────────────────────────────────────────────────────────

class _RepasoBody extends ConsumerWidget {
  const _RepasoBody({required this.state});

  final RepasoState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = state.sesion;
    final pregunta = state.preguntaActualObj;
    final mostrando = state.mostrandoFeedback;
    final feedback = state.ultimaRespuesta;
    final total = sesion.totalPreguntas;
    final actual = state.preguntaActual + 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repaso personalizado'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: actual / total,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contador + tema
              Row(
                children: [
                  Text(
                    'Pregunta $actual de $total',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (pregunta.temaNombre != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        pregunta.temaNombre!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Enunciado
              Text(
                pregunta.enunciado,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.5, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),

              // Opciones
              Expanded(
                child: ListView.separated(
                  itemCount: pregunta.opciones.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    return _OpcionTile(
                      opcion: pregunta.opciones[i],
                      index: i,
                      mostrandoFeedback: mostrando,
                      feedback: feedback,
                      respuestaSeleccionada: state.respuestaSeleccionada,
                      onTap: mostrando
                          ? null
                          : () => ref
                              .read(repasoNotifierProvider.notifier)
                              .responder(i),
                    );
                  },
                ),
              ),

              // Feedback + botón avanzar
              if (mostrando && feedback != null) ...[
                const SizedBox(height: 16),
                _FeedbackPanel(
                  feedback: feedback,
                  esUltima: state.esUltimaPregunta,
                  onAvanzar: state.completada
                      ? null
                      : () =>
                          ref.read(repasoNotifierProvider.notifier).avanzar(),
                  sesionId: sesion.sesionId,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tile de opción ─────────────────────────────────────────────────────────────

class _OpcionTile extends StatelessWidget {
  const _OpcionTile({
    required this.opcion,
    required this.index,
    required this.mostrandoFeedback,
    required this.feedback,
    required this.respuestaSeleccionada,
    required this.onTap,
  });

  final String opcion;
  final int index;
  final bool mostrandoFeedback;
  final RespuestaRepasoResult? feedback;
  final int respuestaSeleccionada;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color? borderColor;
    Color? textColor;

    if (mostrandoFeedback && feedback != null) {
      if (index == feedback!.respuestaCorrecta) {
        bgColor = Colors.green.shade50;
        borderColor = Colors.green.shade400;
        textColor = Colors.green.shade800;
      } else if (!feedback!.esCorrecta && index == respuestaSeleccionada) {
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade300;
        textColor = Colors.red.shade800;
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor ??
              Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor ??
                Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          opcion,
          style: TextStyle(
            fontSize: 14.5,
            color: textColor ?? Theme.of(context).colorScheme.onSurface,
            fontWeight:
                mostrandoFeedback && index == feedback?.respuestaCorrecta
                    ? FontWeight.w600
                    : FontWeight.normal,
          ),
        ),
      ),
    );
  }

}

// ── Panel de feedback ─────────────────────────────────────────────────────────

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({
    required this.feedback,
    required this.esUltima,
    required this.onAvanzar,
    required this.sesionId,
  });

  final RespuestaRepasoResult feedback;
  final bool esUltima;
  final VoidCallback? onAvanzar;
  final int sesionId;

  @override
  Widget build(BuildContext context) {
    final correcto = feedback.esCorrecta;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: correcto ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: correcto ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correcto ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: correcto ? Colors.green.shade600 : Colors.red.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                correcto ? '¡Correcto!' : 'Incorrecto',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color:
                      correcto ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ],
          ),
          if (feedback.explicacion != null &&
              feedback.explicacion!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              feedback.explicacion!,
              style: TextStyle(
                fontSize: 13,
                color: correcto
                    ? Colors.green.shade800
                    : Colors.red.shade800,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: esUltima
                ? FilledButton.icon(
                    onPressed: () =>
                        context.pushReplacement(AppRoutes.repasoResultado(sesionId)),
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('Ver resultado'),
                  )
                : OutlinedButton(
                    onPressed: onAvanzar,
                    child: const Text('Siguiente pregunta'),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Pantalla de resultado ─────────────────────────────────────────────────────

class RepasoResultadoScreen extends ConsumerStatefulWidget {
  const RepasoResultadoScreen({super.key, required this.sesionId});

  final int sesionId;

  @override
  ConsumerState<RepasoResultadoScreen> createState() =>
      _RepasoResultadoScreenState();
}

class _RepasoResultadoScreenState
    extends ConsumerState<RepasoResultadoScreen> {
  AsyncValue<ResultadoSesionRepaso> _resultado =
      const AsyncLoading();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    setState(() => _resultado = const AsyncLoading());
    try {
      final r = await ref
          .read(repasoRepositoryProvider)
          .obtenerResultado(widget.sesionId);
      if (mounted) setState(() => _resultado = AsyncData(r));
    } catch (e, st) {
      if (mounted) setState(() => _resultado = AsyncError(e, st));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _resultado.when(
      loading: () => const _CargandoScaffold(),
      error: (e, _) => _ErrorScaffold(
        message: e.toString(),
        onRetry: _cargar,
      ),
      data: (r) => Scaffold(
        appBar: AppBar(title: const Text('Resultado del repaso')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Puntuación
              _PuntuacionCard(resultado: r),
              const SizedBox(height: 20),

              // Desglose por pregunta
              ...r.respuestas.map((d) => _DetalleCard(detalle: d)),

              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PuntuacionCard extends StatelessWidget {
  const _PuntuacionCard({required this.resultado});

  final ResultadoSesionRepaso resultado;

  @override
  Widget build(BuildContext context) {
    final pct = resultado.correctas / resultado.totalPreguntas;
    final color = pct >= 0.7
        ? Colors.green.shade600
        : pct >= 0.5
            ? Colors.orange.shade700
            : Colors.red.shade600;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              '${resultado.correctas} / ${resultado.totalPreguntas}',
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              '${resultado.puntuacion.toStringAsFixed(1)} puntos',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              pct >= 0.7
                  ? '¡Muy bien! El progreso se ha actualizado.'
                  : pct >= 0.5
                      ? 'Buen intento. Seguí repasando estos temas.'
                      : 'Hay margen de mejora. ¡A repasar!',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetalleCard extends StatelessWidget {
  const _DetalleCard({required this.detalle});

  final DetalleRespuestaRepaso detalle;

  @override
  Widget build(BuildContext context) {
    final enunciado =
        detalle.enunciado?.isNotEmpty == true
            ? detalle.enunciado!
            : 'Pregunta ${detalle.preguntaIndex + 1}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: detalle.esCorrecta
            ? Colors.green.shade50
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: detalle.esCorrecta
              ? Colors.green.shade200
              : Colors.red.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            detalle.esCorrecta
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            size: 18,
            color: detalle.esCorrecta
                ? Colors.green.shade600
                : Colors.red.shade600,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enunciado,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (detalle.temaNombre != null)
                  Text(
                    detalle.temaNombre!,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scaffolds auxiliares ──────────────────────────────────────────────────────

class _CargandoScaffold extends StatelessWidget {
  const _CargandoScaffold();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Repaso personalizado')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generando preguntas personalizadas…'),
            ],
          ),
        ),
      );
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Repaso personalizado')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
}
