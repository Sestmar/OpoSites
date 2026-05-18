import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
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
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _particleController;
  late final Animation<double> _fadeHeader;
  late final Animation<Offset> _slideHeader;
  late final PageController _pageController;
  bool _selecting = false;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(viewportFraction: 0.50);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeHeader = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _slideHeader = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onSelectRama(RamaResponse rama) async {
    if (_selecting) return;
    setState(() => _selecting = true);
    try {
      await ref.read(oposicionRepositoryProvider).selectRama(rama.id);
      if (!mounted) return;

      if (widget.fromPerfil) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.perfil);
        }
        ref.read(authProvider.notifier).ramaSelected(rama.id);
        return;
      }

      context.go(AppRoutes.onboardingExtra);
      ref.read(authProvider.notifier).ramaSelected(rama.id);
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

    return Scaffold(
      backgroundColor: const Color(0xFF040E0C),
      body: Stack(
        children: [
          // ── Animated particle background ───────────────────────────────
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (_, __) => CustomPaint(
                  painter: _FlowPainter(_particleController.value),
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),

                // ── Header ──────────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeHeader,
                  child: SlideTransition(
                    position: _slideHeader,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.50),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.38),
                                  blurRadius: 32,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.track_changes_rounded,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '¿Qué oposición\nquerés preparar?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Personalizamos tu plan de estudio según tu oposición.',
                            style: TextStyle(
                              color: AppColors.darkTextMuted,
                              fontSize: 13.5,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Carousel vertical ──────────────────────────────────
                Expanded(
                  child: ramasAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                    error: (_, __) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No se pudieron cargar las oposiciones.\nComprobá tu conexión.',
                          style: TextStyle(color: AppColors.darkTextMuted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    data: (ramas) => ramas.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay oposiciones disponibles aún.',
                              style:
                                  TextStyle(color: AppColors.darkTextFaint),
                            ),
                          )
                        : _VerticalCarousel(
                            ramas: ramas,
                            pageController: _pageController,
                            selecting: _selecting,
                            onSelect: _onSelectRama,
                          ),
                  ),
                ),

                // Hint de scroll
                FadeTransition(
                  opacity: _fadeHeader,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary.withOpacity(0.55),
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Deslizá para ver más',
                          style: TextStyle(
                            color: AppColors.darkTextMuted.withOpacity(0.70),
                            fontSize: 11.5,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vertical carousel ──────────────────────────────────────────────────────────

class _VerticalCarousel extends StatelessWidget {
  const _VerticalCarousel({
    required this.ramas,
    required this.pageController,
    required this.selecting,
    required this.onSelect,
  });

  final List<RamaResponse> ramas;
  final PageController pageController;
  final bool selecting;
  final void Function(RamaResponse) onSelect;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      scrollDirection: Axis.vertical,
      itemCount: ramas.length,
      itemBuilder: (context, index) {
        final rama = ramas[index];
        return AnimatedBuilder(
          animation: pageController,
          builder: (context, child) {
            double scale = 1.0;
            double opacity = 1.0;

            if (pageController.hasClients &&
                pageController.position.haveDimensions) {
              final page = pageController.page ?? index.toDouble();
              final distance = (index - page).abs().clamp(0.0, 1.5);
              scale = (1.0 - distance * 0.055).clamp(0.90, 1.0);
              opacity = (1.0 - distance * 0.42).clamp(0.50, 1.0);
            }

            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: _RamaCard(
              rama: rama,
              loading: selecting,
              onTap: () => onSelect(rama),
            ),
          ),
        );
      },
    );
  }
}

// ── Animated flow painter ─────────────────────────────────────────────────────

class _FlowPainter extends CustomPainter {
  const _FlowPainter(this.t);

  final double t; // 0.0 → 1.0, looping

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(0, 0, size.width, size.height);

    // ── Background gradient ──────────────────────────────────────────────
    canvas.drawRect(
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0.55, -0.25),
          radius: 1.30,
          colors: [Color(0xFF0D2E28), Color(0xFF040E0C)],
          stops: [0.0, 1.0],
        ).createShader(r),
    );

    // ── Soft glow spots (slowly drifting) ───────────────────────────────
    _drawGlow(canvas, size, 0.78, 0.18, t, 0.00);
    _drawGlow(canvas, size, 0.22, 0.72, t, 0.50);

    // ── Flowing curve families ───────────────────────────────────────────
    _drawFamily(canvas, size, t, family: 0);
    _drawFamily(canvas, size, t, family: 1);

    // ── Subtle scattered dots ────────────────────────────────────────────
    _drawDots(canvas, size, t);
  }

  void _drawGlow(Canvas canvas, Size size, double rx, double ry,
      double t, double phase) {
    const twoPi = 2 * math.pi;
    final x = (rx + math.sin(twoPi * t + phase) * 0.04) * size.width;
    final y = (ry + math.cos(twoPi * t * 0.7 + phase) * 0.03) * size.height;
    final radius = size.shortestSide * 0.55;
    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF0D9B82).withOpacity(0.18),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(x, y),
          radius: radius,
        )),
    );
  }

  void _drawFamily(Canvas canvas, Size size, double t, {required int family}) {
    const lineCount = 12;
    const twoPi = 2 * math.pi;

    // Slowly morphing control points
    final d1x = math.sin(twoPi * t + family * 1.57) * 0.07;
    final d1y = math.cos(twoPi * t * 0.78 + family) * 0.055;
    final d2x = math.sin(twoPi * t * 0.91 + family * 0.8 + 1.1) * 0.065;
    final d2y = math.cos(twoPi * t * 1.05 + family * 1.3) * 0.045;

    double sx, sy, c1x, c1y, c2x, c2y, ex, ey;
    double odx, ody; // per-line offset direction

    if (family == 0) {
      // Top-right → bottom-left sweep
      sx  = (1.10 + d1x * 0.2) * size.width;
      sy  = (-0.05 + d1y * 0.2) * size.height;
      c1x = (0.68 + d1x) * size.width;
      c1y = (0.22 + d1y) * size.height;
      c2x = (0.32 + d2x) * size.width;
      c2y = (0.58 + d2y) * size.height;
      ex  = (-0.05 + d2x * 0.2) * size.width;
      ey  = (0.92 + d2y * 0.2) * size.height;
      odx = size.width  * 0.000;
      ody = size.height * 0.046;
    } else {
      // Upper-right → lower-right sweep
      sx  = (1.05 + d1x * 0.2) * size.width;
      sy  = (0.12 + d1y) * size.height;
      c1x = (0.82 + d1x * 0.6) * size.width;
      c1y = (0.38 + d1y * 0.6) * size.height;
      c2x = (0.58 + d2x * 0.6) * size.width;
      c2y = (0.68 + d2y * 0.6) * size.height;
      ex  = (0.28 + d2x * 0.2) * size.width;
      ey  = (1.10 + d2y * 0.2) * size.height;
      odx = size.width  * 0.046;
      ody = size.height * 0.000;
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < lineCount; i++) {
      final offset = i - lineCount / 2.0;
      final distRatio = (offset.abs() / (lineCount / 2)).clamp(0.0, 1.0);
      final opacity = (0.065 - distRatio * 0.045).clamp(0.008, 0.07);

      final path = Path()
        ..moveTo(sx + odx * offset, sy + ody * offset)
        ..cubicTo(
          c1x + odx * offset, c1y + ody * offset,
          c2x + odx * offset, c2y + ody * offset,
          ex  + odx * offset, ey  + ody * offset,
        );

      linePaint.color = const Color(0xFFB0E8D8).withOpacity(opacity);
      canvas.drawPath(path, linePaint);
    }
  }

  void _drawDots(Canvas canvas, Size size, double t) {
    const twoPi = 2 * math.pi;
    const dots = [
      (0.18, 0.62, 0.0),
      (0.45, 0.38, 1.2),
      (0.72, 0.55, 2.5),
      (0.30, 0.80, 3.8),
      (0.60, 0.20, 0.7),
    ];
    for (final (rx, ry, phase) in dots) {
      final x = (rx + math.sin(twoPi * t + phase) * 0.01) * size.width;
      final y = (ry + math.cos(twoPi * t * 0.8 + phase) * 0.008) * size.height;
      final op = 0.35 + 0.25 * math.sin(twoPi * t * 1.2 + phase).abs();
      canvas.drawCircle(
        Offset(x, y),
        1.8,
        Paint()..color = const Color(0xFF80F0DC).withOpacity(op),
      );
    }
  }

  @override
  bool shouldRepaint(_FlowPainter old) => old.t != t;
}

// ── Card de rama ───────────────────────────────────────────────────────────────

class _CardTheme {
  const _CardTheme({
    required this.icon,
    required this.accentColor,
    required this.imagePath,
    this.imageAlignment = Alignment.center,
    this.fallbackGradient = const [Color(0xFF0A1228), Color(0xFF1E3A5C)],
  });

  final IconData icon;
  final Color accentColor;
  final String imagePath;
  final Alignment imageAlignment;
  final List<Color> fallbackGradient;
}

class _RamaCard extends StatelessWidget {
  const _RamaCard({
    required this.rama,
    required this.onTap,
    required this.loading,
  });

  final RamaResponse rama;
  final VoidCallback onTap;
  final bool loading;

  _CardTheme _theme() {
    final n = rama.nombre.toLowerCase();
    if (n.contains('polic')) {
      return const _CardTheme(
        icon: Icons.local_police_rounded,
        accentColor: Color(0xFF2563EB),
        imagePath: 'assets/images/ramas/policia-nacional.jpg',
        imageAlignment: Alignment.topCenter,
        fallbackGradient: [Color(0xFF07102A), Color(0xFF1A2D5E)],
      );
    }
    if (n.contains('guardia')) {
      return const _CardTheme(
        icon: Icons.shield_rounded,
        accentColor: Color(0xFF16A34A),
        imagePath: 'assets/images/ramas/guardia-civil.jpg',
        imageAlignment: Alignment.topCenter,
        fallbackGradient: [Color(0xFF071A0C), Color(0xFF145228)],
      );
    }
    if (n.contains('pris') || n.contains('ayudant')) {
      return const _CardTheme(
        icon: Icons.account_balance_rounded,
        accentColor: Color(0xFF0891B2),
        imagePath: 'assets/images/ramas/prisiones.jpg',
        imageAlignment: const Alignment(0, -0.22),
        fallbackGradient: [Color(0xFF051418), Color(0xFF0C3D52)],
      );
    }
    if (n.contains('sanit') || n.contains('médic') || n.contains('medic')) {
      return const _CardTheme(
        icon: Icons.local_hospital_rounded,
        accentColor: Color(0xFF7C3AED),
        imagePath: 'assets/images/ramas/sanitario.jpeg',
        imageAlignment: Alignment.centerLeft,
        fallbackGradient: [Color(0xFF0C0A20), Color(0xFF312E81)],
      );
    }
    if (n.contains('milit') ||
        n.contains('fuerzas') ||
        n.contains('ejér') ||
        n.contains('ejercit')) {
      return const _CardTheme(
        icon: Icons.military_tech_rounded,
        accentColor: Color(0xFFD97706),
        imagePath: 'assets/images/ramas/ejercito.jpg',
        imageAlignment: const Alignment(0, 0.4),
        fallbackGradient: [Color(0xFF181008), Color(0xFF5C3D11)],
      );
    }
    return _CardTheme(
      icon: Icons.school_rounded,
      accentColor: AppColors.primary,
      imagePath: '',
      fallbackGradient: const [Color(0xFF0A1228), Color(0xFF1E3A5C)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _theme();
    final hasImage = t.imagePath.isNotEmpty;

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: t.accentColor.withOpacity(0.30),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: t.accentColor.withOpacity(0.12),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
          image: hasImage
              ? DecorationImage(
                  image: AssetImage(t.imagePath),
                  fit: BoxFit.cover,
                  alignment: t.imageAlignment,
                )
              : null,
          gradient: hasImage
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: t.fallbackGradient,
                ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: Stack(
            children: [
              // Gradient overlay: transparent top → dark bottom
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.08),
                        Colors.black.withOpacity(0.30),
                        Colors.black.withOpacity(0.82),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

              // Subtle teal glow on top edge
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        t.accentColor.withOpacity(0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon badge top-left
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.45),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.55),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        t.icon,
                        size: 22,
                        color: AppColors.primary,
                      ),
                    ),

                    const Spacer(),

                    // Title + chevron at bottom
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            rama.nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              height: 1.15,
                              letterSpacing: -0.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (loading)
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        else
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.18),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.50),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),

                    if (rama.descripcion != null &&
                        rama.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        rama.descripcion!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.60),
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
