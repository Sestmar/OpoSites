import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/material_generado.dart';

class MapaMentalScreen extends StatelessWidget {
  const MapaMentalScreen({super.key, required this.material});

  final MaterialGenerado material;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final raiz = material.mapaMentalRaiz;

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa mental')),
      body: raiz == null
          ? Center(
              child: Text(
                'Sin contenido disponible.',
                style: AppText.body.copyWith(color: AppColors.textMutedFor(b)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // ── Nodo raíz ──────────────────────────────────────────────
                _NodoRaiz(nodo: raiz),
                const SizedBox(height: 8),
                // ── Ramas principales ───────────────────────────────────────
                ...raiz.hijos.map((hijo) => _NodoWidget(nodo: hijo, nivel: 0)),
              ],
            ),
    );
  }
}

// ── Nodo raíz (cabecera especial) ─────────────────────────────────────────────

class _NodoRaiz extends StatelessWidget {
  const _NodoRaiz({required this.nodo});
  final NodoMental nodo;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final primary = AppColors.primaryFor(b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.account_tree_outlined, color: primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nodo.titulo,
              style: AppText.cardTitle.copyWith(color: primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nodo recursivo ────────────────────────────────────────────────────────────

class _NodoWidget extends StatelessWidget {
  const _NodoWidget({required this.nodo, required this.nivel});

  final NodoMental nodo;
  final int nivel; // 0 = rama principal, 1 = sub-rama, 2 = hoja

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;

    if (nodo.esHoja) {
      return _HojaWidget(nodo: nodo, nivel: nivel);
    }

    return Padding(
      padding: EdgeInsets.only(left: _indentFor(nivel)),
      child: ExpansionTile(
        initiallyExpanded: nivel == 0, // Solo las ramas principales arrancan abiertas
        tilePadding: EdgeInsets.only(
          left: nivel == 0 ? 0 : 4,
          right: 8,
        ),
        shape: Border(
          bottom: BorderSide(color: AppColors.borderFor(b), width: 0.5),
        ),
        collapsedShape: Border(
          bottom: BorderSide(color: AppColors.borderFor(b), width: 0.5),
        ),
        leading: _LeadingIndicador(nivel: nivel),
        title: Text(
          nodo.titulo,
          style: _estiloTitulo(nivel, b),
        ),
        children: nodo.hijos
            .map((hijo) => _NodoWidget(nodo: hijo, nivel: nivel + 1))
            .toList(),
      ),
    );
  }

  TextStyle _estiloTitulo(int nivel, Brightness b) {
    final color = AppColors.textFor(b);
    return switch (nivel) {
      0 => AppText.body.copyWith(color: color, fontWeight: FontWeight.w700),
      1 => AppText.body.copyWith(color: color, fontWeight: FontWeight.w600),
      _ => AppText.bodySmall.copyWith(color: color),
    };
  }

  double _indentFor(int nivel) => switch (nivel) {
        0 => 0,
        1 => 16,
        _ => 32,
      };
}

// ── Hoja (nodo sin hijos) ─────────────────────────────────────────────────────

class _HojaWidget extends StatelessWidget {
  const _HojaWidget({required this.nodo, required this.nivel});

  final NodoMental nodo;
  final int nivel;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final indent = switch (nivel) {
      0 => 0.0,
      1 => 16.0,
      _ => 32.0,
    };

    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LeadingIndicador(nivel: nivel),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                nodo.titulo,
                style: AppText.bodySmall.copyWith(
                  color: AppColors.textMutedFor(b),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Indicador visual de nivel ─────────────────────────────────────────────────

class _LeadingIndicador extends StatelessWidget {
  const _LeadingIndicador({required this.nivel});
  final int nivel;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final primary = AppColors.primaryFor(b);

    return switch (nivel) {
      0 => Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      1 => Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        ),
      _ => Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.textFaintFor(b),
            shape: BoxShape.circle,
          ),
        ),
    };
  }
}
