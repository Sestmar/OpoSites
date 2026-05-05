import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

// ── Colores locales (auth screen — no depende del brightness del tema) ─────────

const _kBg         = Color(0xFF080D0D);
const _kSurface    = Color(0xFF0F1A19);
const _kBorder     = Color(0xFF3C4947);
const _kPrimary    = Color(0xFF4FDBC8);
const _kTextMuted  = Color(0xFF8EA8A5);
const _kTextPrimary = Color(0xFFF0F4F4);

// ── Pantalla ───────────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Validadores ────────────────────────────────────────────────────────────

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'El email es obligatorio.';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Ingresá un email válido.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria.';
    if (value.length < 6) return 'Mínimo 6 caracteres.';
    return null;
  }

  // ── Acción ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    ref.read(authProvider.notifier).clearError();
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState    = ref.watch(authProvider);
    final isLoading    = authState is AuthLoading;
    final errorMessage = authState is AuthError ? authState.message : null;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── Fondo de partículas (widget aislado — ticker propio) ────────────
          const Positioned.fill(child: _ParticlesBackground()),

          // ── Formulario ──────────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icono ─────────────────────────────────────────────
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: _kPrimary.withOpacity(0.10),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _kPrimary.withOpacity(0.30),
                              ),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              size: 36,
                              color: _kPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Título ────────────────────────────────────────────
                        const Text(
                          'Bienvenido',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: _kTextPrimary,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Iniciá sesión para continuar',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: _kTextMuted,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Email ─────────────────────────────────────────────
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          enabled: !isLoading,
                          style: const TextStyle(color: _kTextPrimary),
                          decoration: _fieldDecoration(
                            label: 'Email',
                            icon: Icons.email_outlined,
                            context: context,
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 14),

                        // Contraseña ────────────────────────────────────────
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          enabled: !isLoading,
                          onFieldSubmitted: (_) => _submit(),
                          style: const TextStyle(color: _kTextPrimary),
                          decoration: _fieldDecoration(
                            label: 'Contraseña',
                            icon: Icons.lock_outline,
                            context: context,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: _kTextMuted,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 24),

                        // Error del servidor ─────────────────────────────────
                        if (errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              errorMessage,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Botón ──────────────────────────────────────────────
                        FilledButton(
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF003731),
                                  ),
                                )
                              : const Text('Iniciar sesión'),
                        ),
                        const SizedBox(height: 16),

                        // Registro ───────────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '¿No tenés cuenta?',
                              style: TextStyle(
                                color: _kTextMuted,
                                fontSize: 13.5,
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: const Size(0, 40),
                                foregroundColor: _kPrimary,
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () => context.go(AppRoutes.register),
                              child: const Text(
                                'Registrate',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Forgot password ────────────────────────────────────
                        Center(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              foregroundColor: _kTextMuted,
                            ),
                            onPressed: isLoading ? null : () {},
                            child: const Text(
                              'Olvidé mi contraseña',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    required BuildContext context,
    Widget? suffix,
  }) {
    const radius = BorderRadius.all(Radius.circular(12));
    const side   = BorderSide(color: _kBorder);
    const focSide = BorderSide(color: _kPrimary, width: 1.5);

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _kTextMuted, fontSize: 13.5),
      prefixIcon: Icon(icon, color: _kTextMuted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: _kSurface,
      border: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: side,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: side,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: focSide,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 1.5,
        ),
      ),
    );
  }
}

// ── Fondo de partículas ────────────────────────────────────────────────────────
//
// Widget aislado con su propio Ticker para no reconstruir el formulario
// en cada frame de animación.

class _ParticlesBackground extends StatefulWidget {
  const _ParticlesBackground();

  @override
  State<_ParticlesBackground> createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<_ParticlesBackground>
    with SingleTickerProviderStateMixin {

  static const int _kCount = 32;

  final List<_Particle> _particles =
      List.generate(_kCount, (_) => _Particle.random());

  late final Ticker _ticker;
  int _lastMicros = 0;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final micros = elapsed.inMicroseconds;
    final dt = _lastMicros == 0
        ? 0.016
        : (micros - _lastMicros) / 1e6;
    _lastMicros = micros;

    if (_size != Size.zero) {
      for (final p in _particles) {
        p.update(dt, _size);
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      _size = box.biggest;
      return CustomPaint(
        painter: _ParticlesPainter(_particles),
        size: _size,
      );
    });
  }
}

// ── Modelo de partícula ────────────────────────────────────────────────────────

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  final double radius;
  bool _placed = false;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
  });

  static final _rng = Random();

  factory _Particle.random() {
    final angle = _rng.nextDouble() * 2 * pi;
    final speed = 12.0 + _rng.nextDouble() * 20.0; // 12–32 px/s → movimiento lento
    return _Particle(
      x: _rng.nextDouble(), // normalizado 0–1, se convierte al primer update
      y: _rng.nextDouble(),
      vx: cos(angle) * speed,
      vy: sin(angle) * speed,
      radius: 1.5 + _rng.nextDouble() * 2.0,
    );
  }

  void update(double dt, Size size) {
    // Primera vez: convertir de normalizado a píxeles absolutos
    if (!_placed) {
      x = x * size.width;
      y = y * size.height;
      _placed = true;
    }

    x += vx * dt;
    y += vy * dt;

    // Rebote en los bordes
    if (x < 0)          { x = 0;           vx =  vx.abs(); }
    if (x > size.width) { x = size.width;  vx = -vx.abs(); }
    if (y < 0)          { y = 0;           vy =  vy.abs(); }
    if (y > size.height){ y = size.height; vy = -vy.abs(); }
  }
}

// ── Pintor ─────────────────────────────────────────────────────────────────────

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;

  static const double _connectionDist = 140.0;

  _ParticlesPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    final dotPaint = Paint()..style = PaintingStyle.fill;

    // Líneas de conexión
    for (int i = 0; i < particles.length; i++) {
      final a = particles[i];
      if (!a._placed) continue;

      for (int j = i + 1; j < particles.length; j++) {
        final b = particles[j];
        if (!b._placed) continue;

        final dx   = a.x - b.x;
        final dy   = a.y - b.y;
        final dist = sqrt(dx * dx + dy * dy);

        if (dist < _connectionDist) {
          final opacity = (1.0 - dist / _connectionDist) * 0.38;
          linePaint.color = _kPrimary.withOpacity(opacity);
          canvas.drawLine(Offset(a.x, a.y), Offset(b.x, b.y), linePaint);
        }
      }
    }

    // Nodos
    for (final p in particles) {
      if (!p._placed) continue;
      final center = Offset(p.x, p.y);

      // Halo exterior suave
      dotPaint.color = _kPrimary.withOpacity(0.12);
      canvas.drawCircle(center, p.radius * 2.8, dotPaint);

      // Núcleo brillante
      dotPaint.color = _kPrimary.withOpacity(0.80);
      canvas.drawCircle(center, p.radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter old) => true;
}
