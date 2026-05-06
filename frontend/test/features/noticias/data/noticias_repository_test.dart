import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oposites/features/noticias/data/models/noticia_resumen.dart';
import 'package:oposites/features/noticias/data/noticias_repository.dart';

class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    final body = jsonEncode({
      'content': [
        {
          'id': 1,
          'titulo': 'Noticia',
          'tipo': 'noticia',
          'fechaPublicacion': '01/01/2026 10:00',
          'leida': false,
          'ramaId': null,
          'nombreRama': null,
        },
      ],
      'number': 0,
      'last': true,
      'totalElements': 1,
    });
    return ResponseBody.fromString(
      body,
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }
}

void main() {
  test('getNoticias envía tipo en mayúsculas y page/size correctos', () async {
    final adapter = _CapturingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = NoticiasRepository(dio: dio);

    await repository.getNoticias(
      tipo: TipoNoticia.convocatoria,
      page: 2,
      size: 15,
    );

    expect(adapter.lastOptions, isNotNull);
    expect(adapter.lastOptions!.queryParameters['tipo'], 'CONVOCATORIA');
    expect(adapter.lastOptions!.queryParameters['page'], 2);
    expect(adapter.lastOptions!.queryParameters['size'], 15);
  });
}
