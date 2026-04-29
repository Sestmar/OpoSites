import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  runApp(
    // ProviderScope es el contenedor raíz de Riverpod.
    // Todos los providers del proyecto viven dentro de este scope.
    const ProviderScope(
      child: OpoSitesApp(),
    ),
  );
}
