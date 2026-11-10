import '../domain/learning_unit.dart';
import '../domain/lesson.dart';
import '../domain/sign.dart';

/// Contenido de EJEMPLO para probar la app (3 unidades, 25 señas, 7 lecciones).
///
/// Solo son palabras en borrador: la selección definitiva de señas y unidades
/// se hace con personas sordas (Sprint 0 de la ficha técnica). Los videos NO
/// están incluidos: se suben a Cloud Storage en las rutas `videoPath`.
///
/// Se carga desde Administración → «Cargar contenido de ejemplo».
class SeedContent {
  const SeedContent._();

  /// Video público de muestra, usado SOLO en el modo de pruebas para poder
  /// ver el reproductor funcionando. No es una seña real.
  static const String testVideoUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

  static const List<LearningUnit> units = [
    LearningUnit(
      id: 'u1-saludos',
      title: 'Saludos y cortesía',
      order: 1,
      description: 'Saluda, despídete y sé cortés.',
      iconKey: 'saludos',
      culturalNote:
          'El Estado colombiano reconoce la Lengua de Señas Colombiana como '
          'lengua propia de la comunidad sorda del país (Ley 324 de 1996).',
    ),
    LearningUnit(
      id: 'u2-familia',
      title: 'Familia y personas',
      order: 2,
      description: 'Habla de tu familia y de las personas cercanas.',
      iconKey: 'familia',
    ),
    LearningUnit(
      id: 'u3-cotidiano',
      title: 'Vida cotidiana',
      order: 3,
      description: 'Palabras para el día a día.',
      iconKey: 'cotidiano',
    ),
  ];

  static final List<Sign> signs = [
    ..._unitSigns('u1-saludos', 'saludos', const [
      ('hola', 'Hola'),
      ('adios', 'Adiós'),
      ('buenos-dias', 'Buenos días'),
      ('buenas-tardes', 'Buenas tardes'),
      ('buenas-noches', 'Buenas noches'),
      ('por-favor', 'Por favor'),
      ('gracias', 'Gracias'),
      ('perdon', 'Perdón'),
    ]),
    ..._unitSigns('u2-familia', 'familia', const [
      ('mama', 'Mamá'),
      ('papa', 'Papá'),
      ('hermano', 'Hermano'),
      ('hermana', 'Hermana'),
      ('abuelo', 'Abuelo'),
      ('abuela', 'Abuela'),
      ('amigo', 'Amigo'),
      ('amiga', 'Amiga'),
    ]),
    ..._unitSigns('u3-cotidiano', 'cotidiano', const [
      ('agua', 'Agua'),
      ('comida', 'Comida'),
      ('casa', 'Casa'),
      ('colegio', 'Colegio'),
      ('trabajo', 'Trabajo'),
      ('bano', 'Baño'),
      ('ayuda', 'Ayuda'),
      ('si', 'Sí'),
      ('no', 'No'),
    ]),
  ];

  static const List<Lesson> lessons = [
    Lesson(
      id: 'l1-1',
      unitId: 'u1-saludos',
      title: 'Saludos básicos',
      order: 1,
      signIds: ['hola', 'adios', 'buenos-dias', 'buenas-tardes'],
    ),
    Lesson(
      id: 'l1-2',
      unitId: 'u1-saludos',
      title: 'Cortesía',
      order: 2,
      signIds: ['buenas-noches', 'por-favor', 'gracias', 'perdon'],
    ),
    Lesson(
      id: 'l2-1',
      unitId: 'u2-familia',
      title: 'Mi familia',
      order: 1,
      signIds: ['mama', 'papa', 'hermano', 'hermana'],
    ),
    Lesson(
      id: 'l2-2',
      unitId: 'u2-familia',
      title: 'Más personas',
      order: 2,
      signIds: ['abuelo', 'abuela', 'amigo', 'amiga'],
    ),
    Lesson(
      id: 'l3-1',
      unitId: 'u3-cotidiano',
      title: 'En casa',
      order: 1,
      signIds: ['agua', 'comida', 'casa'],
    ),
    Lesson(
      id: 'l3-2',
      unitId: 'u3-cotidiano',
      title: 'Fuera de casa',
      order: 2,
      signIds: ['colegio', 'trabajo', 'bano'],
    ),
    Lesson(
      id: 'l3-3',
      unitId: 'u3-cotidiano',
      title: 'Pedir y responder',
      order: 3,
      signIds: ['ayuda', 'si', 'no'],
    ),
  ];

  static List<Sign> _unitSigns(
    String unitId,
    String folder,
    List<(String, String)> items,
  ) {
    return [
      for (final (id, word) in items)
        Sign(
          id: id,
          word: word,
          unitId: unitId,
          videoPath: 'videos/$folder/$id.mp4',
        ),
    ];
  }
}
