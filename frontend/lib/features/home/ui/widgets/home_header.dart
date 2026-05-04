import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Header sticky de la Home — logo + nombre de la app + chip de racha.
///
/// Se usa como [title] del [SliverAppBar] en HomeScreen.
/// El fondo con blur lo gestiona el [SliverAppBar.flexibleSpace].
class HomeHeader extends StatelessWidget {
  final int rachaActual;

  const HomeHeader({super.key, required this.rachaActual});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Row(
      children: [
        _AppLogo(),
        const SizedBox(width: 8),
        Text(
          'opoSites',
          style: AppText.cardTitle.copyWith(color: AppColors.textFor(b)),
        ),
        const Spacer(),
        _StreakChip(rachaActual: rachaActual, brightness: b),
      ],
    );
  }
}

// ── Logo ──────────────────────────────────────────────────────────────────────

class _AppLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryStrong],
        ),
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'oS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

// ── Chip de racha ─────────────────────────────────────────────────────────────

class _StreakChip extends StatelessWidget {
  final int rachaActual;
  final Brightness brightness;

  const _StreakChip({required this.rachaActual, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(brightness),
        border: Border.all(
          color: AppColors.borderFor(brightness),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: AppColors.accentWarm,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '$rachaActual',
            style: AppText.label.copyWith(
              color: AppColors.textFor(brightness),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '· días',
            style: AppText.caption.copyWith(
              color: AppColors.textFaintFor(brightness),
            ),
          ),
        ],
      ),
    );
  }
}
