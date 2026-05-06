class NoticiaConteos {
  final int todas;
  final int convocatorias;
  final int cambios;
  final int noticias;

  const NoticiaConteos({
    required this.todas,
    required this.convocatorias,
    required this.cambios,
    required this.noticias,
  });

  factory NoticiaConteos.fromJson(Map<String, dynamic> json) => NoticiaConteos(
        todas: (json['todas'] as num).toInt(),
        convocatorias: (json['convocatorias'] as num).toInt(),
        cambios: (json['cambios'] as num).toInt(),
        noticias: (json['noticias'] as num).toInt(),
      );

  static const empty = NoticiaConteos(
    todas: 0,
    convocatorias: 0,
    cambios: 0,
    noticias: 0,
  );
}
