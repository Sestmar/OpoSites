import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../features/oposicion/data/models/rama_response.dart';
import '../../../../features/oposicion/providers/oposicion_provider.dart';

class SelectOposicionScreen extends ConsumerStatefulWidget {
  const SelectOposicionScreen({super.key, this.fromPerfil = false});

  final bool fromPerfil;

  @override
  ConsumerState<SelectOposicionScreen> createState() =>
      _SelectOposicionScreenState();
}

class _SelectOposicionScreenState extends ConsumerState<SelectOposicionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeHeader;
  late final Animation<Offset> _slideHeader;
  bool _selecting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fadeHeader = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _slideHeader = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _cardFade(int index) => CurvedAnimation(
        parent: _controller,
        curve: Interval(
          (0.35 + index * 0.07).clamp(0.0, 0.9),
          (0.65 + index * 0.07).clamp(0.0, 1.0),
          curve: Curves.easeOutBack,
        ),
      );

  Animation<Offset> _cardSlide(int index) => Tween<Offset>(
        begin: const Offset(0, 0.4),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(
          (0.35 + index * 0.07).clamp(0.0, 0.9),
          (0.65 + index * 0.07).clamp(0.0, 1.0),
          curve: Curves.easeOutBack,
        ),
      ));

  String _emojiForRama(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('polic')) return '🚔';
    if (n.contains('guardia')) return '🪖';
    if (n.contains('pris')) return '🏛️';
    if (n.contains('sanit') || n.contains('médic') || n.contains('medic')) {
      return '🏥';
    }
    if (n.contains('milit') || n.contains('ejércit') || n.contains('ejercit')) {
      return '⚔️';
    }
    return '📚';
  }

  Future<void> _onSelectRama(RamaResponse rama) async {
    if (_selecting) return;
    setState(() => _selecting = true);
    try {
      await ref.read(oposicionRepositoryProvider).selectRama(rama.id);
      ref.read(authProvider.notifier).ramaSelected(rama.id);
      if (mounted && widget.fromPerfil) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/perfil');
        }
        return;
      }
    } catch (_) {
      if (mounted) {
        setState(() => _selecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al seleccionar. Inténtalo de nuevo.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ramasAsync = ref.watch(ramasProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primary,
              primary.withOpacity(0.75),
              theme.colorScheme.surface,
            ],
            stops: const [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 44),

              // ── Header animado ──────────────────────────────────────────
              FadeTransition(
                opacity: _fadeHeader,
                child: SlideTransition(
                  position: _slideHeader,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const Text('🎯', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text(
                          '¿Qué oposición\nquerés preparar?',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Personalizamos tu plan de estudio\nsegún tu oposición.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── Lista de ramas ──────────────────────────────────────────
              Expanded(
                child: ramasAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (_, __) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No se pudieron cargar las oposiciones.\nComprobá tu conexión e inténtalo de nuevo.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  data: (ramas) => ramas.isEmpty
                      ? Center(
                          child: Text(
                            'No hay oposiciones disponibles aún.',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: ramas.length,
                          itemBuilder: (context, index) {
                            final rama = ramas[index];
                            return FadeTransition(
                              opacity: _cardFade(index),
                              child: SlideTransition(
                                position: _cardSlide(index),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _RamaCard(
                                    rama: rama,
                                    emoji: _emojiForRama(rama.nombre),
                                    loading: _selecting,
                                    onTap: () => _onSelectRama(rama),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Card de rama ───────────────────────────────────────────────────────────────

class _RamaCard extends StatelessWidget {
  const _RamaCard({
    required this.rama,
    required this.emoji,
    required this.onTap,
    required this.loading,
  });

  final RamaResponse rama;
  final String emoji;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rama.nombre,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (rama.descripcion != null &&
                        rama.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        rama.descripcion!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.55),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
