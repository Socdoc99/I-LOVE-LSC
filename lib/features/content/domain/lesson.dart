/// Lección: un grupo corto de señas que se aprende en una sesión.
///
/// Una lección solo se muestra a las personas aprendices cuando está
/// [published], y solo puede publicarse si ya fue [validated] por personas
/// sordas (validación lingüística y cultural).
class Lesson {
  const Lesson({
    required this.id,
    required this.unitId,
    required this.title,
    required this.order,
    this.signIds = const <String>[],
    this.published = false,
    this.validated = false,
  });

  final String id;
  final String unitId;
  final String title;
  final int order;
  final List<String> signIds;
  final bool published;
  final bool validated;
}
