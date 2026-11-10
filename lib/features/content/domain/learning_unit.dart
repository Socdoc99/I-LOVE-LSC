/// Unidad temática del mapa de aprendizaje (por ejemplo, «Saludos y cortesía»).
class LearningUnit {
  const LearningUnit({
    required this.id,
    required this.title,
    required this.order,
    this.description = '',
    this.iconKey = '',
    this.culturalNote = '',
  });

  final String id;
  final String title;
  final int order;
  final String description;

  /// Clave del ícono que se muestra en el mapa (ver `unitIconFor`).
  final String iconKey;

  /// Dato cultural sobre la comunidad sorda asociado a la unidad.
  /// Debe ser creado o validado por personas sordas.
  final String culturalNote;
}
