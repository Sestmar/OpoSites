import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  runApp(
    // ProviderScope es el contenedor raíz de Riverpod.
    // Todos los providers del proyecto viven dentro de este scope.
    const ProviderScope(
      child: OpoSitesApp(),
    ),
  );
}
