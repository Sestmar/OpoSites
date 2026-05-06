import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oposites/core/api/api_exception.dart';
import 'package:oposites/features/noticias/data/models/noticia_resumen.dart';
import 'package:oposites/features/noticias/providers/noticias_provider.dart';
import 'package:oposites/features/noticias/ui/noticias_list_screen.dart';

import '../helpers/fake_noticias_repository.dart';

Widget _buildApp(FakeNoticiasRepository repo) {
  return ProviderScope(
    overrides: [
      noticiasRepositoryProvider.overrideWith((_) => repo),
    ],
    child: const MaterialApp(
      home: NoticiasListScreen(),
    ),
  );
}

void main() {
  testWidgets('muestra estado empty cuando no hay noticias', (tester) async {
    final repo = FakeNoticiasRepository(
      pageBuilder: ({tipo, ramaId, page = 0, size = 20}) => NoticiasPage(
        content: const [],
        number: page,
        last: true,
        totalElements: 0,
      ),
    );

    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();

    expect(find.text('No hay noticias para este filtro.'), findsOneWidget);
  });

  testWidgets('muestra estado error y permite reintentar', (tester) async {
    var fail = true;
    final repo = FakeNoticiasRepository(
      pageBuilder: ({tipo, ramaId, page = 0, size = 20}) {
        if (fail) throw const NetworkException();
        return NoticiasPage(
          content: const [
            NoticiaResumen(
              id: 1,
              titulo: 'Noticia publicada',
              tipo: TipoNoticia.noticia,
              fechaPublicacion: '01/01/2026 10:00',
              leida: false,
              ramaId: null,
              nombreRama: null,
            ),
          ],
          number: page,
          last: true,
          totalElements: 1,
        );
      },
    );

    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();

    expect(find.text('No se pudieron cargar las noticias'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Noticia publicada'), findsOneWidget);
  });

  testWidgets('chips de filtros cambian query y pull-to-refresh recarga', (tester) async {
    TipoNoticia? lastTipo;
    final repo = FakeNoticiasRepository(
      onGetNoticias: ({tipo, ramaId, page, size}) => lastTipo = tipo,
      pageBuilder: ({tipo, ramaId, page = 0, size = 20}) => NoticiasPage(
        content: const [
          NoticiaResumen(
            id: 1,
            titulo: 'Noticia 1',
            tipo: TipoNoticia.noticia,
            fechaPublicacion: '01/01/2026 10:00',
            leida: false,
            ramaId: null,
            nombreRama: null,
          ),
        ],
        number: page,
        last: true,
        totalElements: 1,
      ),
    );

    await tester.pumpWidget(_buildApp(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Convocatorias'));
    await tester.pumpAndSettle();
    expect(lastTipo, TipoNoticia.convocatoria);

    final listFinder = find.byType(ListView).first;
    await tester.drag(listFinder, const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(repo.getNoticiasCalls, greaterThanOrEqualTo(3));
  });
}
