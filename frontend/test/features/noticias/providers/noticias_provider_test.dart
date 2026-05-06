import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oposites/core/api/api_exception.dart';
import 'package:oposites/features/noticias/data/models/noticia_resumen.dart';
import 'package:oposites/features/noticias/providers/noticias_provider.dart';

import '../helpers/fake_noticias_repository.dart';

void main() {
  test('recargarActual mantiene filtros actuales', () async {
    TipoNoticia? firstTipo;
    TipoNoticia? secondTipo;

    var call = 0;
    final fakeRepo = FakeNoticiasRepository(
      onGetNoticias: ({tipo, ramaId, page, size}) {
        if (call == 0) {
          firstTipo = tipo;
        } else {
          secondTipo = tipo;
        }
        call++;
      },
      pageBuilder: ({tipo, ramaId, page = 0, size = 20}) => NoticiasPage(
        content: const [],
        number: page,
        last: true,
        totalElements: 0,
      ),
    );

    final container = ProviderContainer(
      overrides: [
        noticiasRepositoryProvider.overrideWith((_) => fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(noticiasListNotifierProvider.notifier);
    await notifier.cargar(tipo: TipoNoticia.cambio);
    await notifier.recargarActual();

    expect(firstTipo, TipoNoticia.cambio);
    expect(secondTipo, TipoNoticia.cambio);
  });

  test('cargar propaga estado error cuando falla repository', () async {
    final fakeRepo = FakeNoticiasRepository(
      error: const NetworkException(),
    );
    final container = ProviderContainer(
      overrides: [
        noticiasRepositoryProvider.overrideWith((_) => fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(noticiasListNotifierProvider.notifier);
    await notifier.cargar();

    final state = container.read(noticiasListNotifierProvider);
    expect(state.hasError, isTrue);
  });
}
