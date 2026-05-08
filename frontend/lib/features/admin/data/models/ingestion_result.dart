/// Resultado de una ejecución de ingesta de noticias.
/// Espejo de NoticiaIngestionService.IngestionResult (record Java).
class IngestionResult {
  const IngestionResult({
    required this.fuentesProcesadas,
    required this.itemsLeidos,
    required this.itemsCreados,
    required this.itemsDuplicados,
    required this.itemsFiltrados,
    required this.errores,
  });

  final int fuentesProcesadas;
  final int itemsLeidos;
  final int itemsCreados;
  final int itemsDuplicados;
  final int itemsFiltrados;
  final int errores;

  factory IngestionResult.fromJson(Map<String, dynamic> json) =>
      IngestionResult(
        fuentesProcesadas: json['fuentesProcesadas'] as int,
        itemsLeidos: json['itemsLeidos'] as int,
        itemsCreados: json['itemsCreados'] as int,
        itemsDuplicados: json['itemsDuplicados'] as int,
        itemsFiltrados: json['itemsFiltrados'] as int,
        errores: json['errores'] as int,
      );
}
