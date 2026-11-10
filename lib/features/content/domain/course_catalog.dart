import 'learning_unit.dart';
import 'lesson.dart';
import 'sign.dart';

enum LessonStatus { locked, available, completed }

/// Contenido del curso ya cargado: unidades, lecciones publicadas y señas.
class CourseCatalog {
  CourseCatalog._(this.units, this.lessonsInOrder, this.signsById);

  /// Ordena las unidades y las lecciones; descarta lecciones de unidades
  /// que no existen.
  factory CourseCatalog({
    required List<LearningUnit> units,
    required List<Lesson> lessons,
    required List<Sign> signs,
  }) {
    final sortedUnits = [...units]..sort((a, b) => a.order.compareTo(b.order));
    final unitIndex = <String, int>{
      for (var i = 0; i < sortedUnits.length; i++) sortedUnits[i].id: i,
    };
    final sortedLessons =
        lessons.where((l) => unitIndex.containsKey(l.unitId)).toList()
          ..sort((a, b) {
            final byUnit = unitIndex[a.unitId]!.compareTo(unitIndex[b.unitId]!);
            return byUnit != 0 ? byUnit : a.order.compareTo(b.order);
          });
    return CourseCatalog._(
      List.unmodifiable(sortedUnits),
      List.unmodifiable(sortedLessons),
      <String, Sign>{for (final sign in signs) sign.id: sign},
    );
  }

  final List<LearningUnit> units;

  /// Lecciones en el orden global del curso (unidad y luego orden).
  final List<Lesson> lessonsInOrder;
  final Map<String, Sign> signsById;

  List<String> get allLessonIds => [for (final l in lessonsInOrder) l.id];

  List<Sign> get allSigns => signsById.values.toList();

  List<Lesson> lessonsOfUnit(String unitId) =>
      lessonsInOrder.where((l) => l.unitId == unitId).toList();

  Lesson? lessonById(String id) {
    for (final lesson in lessonsInOrder) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  /// Señas de una lección, en el orden definido por la lección.
  List<Sign> signsOfLesson(Lesson lesson) => signsByIds(lesson.signIds);

  List<Sign> signsByIds(Iterable<String> ids) {
    final result = <Sign>[];
    for (final id in ids) {
      final sign = signsById[id];
      if (sign != null) result.add(sign);
    }
    return result;
  }

  List<Sign> signsOfUnit(String unitId) =>
      signsById.values.where((s) => s.unitId == unitId).toList();

  /// Señas que se pueden usar como distractores en una lección: las de las
  /// lecciones anteriores y las de la propia lección. Si son muy pocas, se
  /// completan con otras señas del curso.
  List<Sign> poolUpTo(Lesson lesson, {int minSize = 4}) {
    final ids = <String>{};
    for (final l in lessonsInOrder) {
      ids.addAll(l.signIds);
      if (l.id == lesson.id) break;
    }
    return _withMinimum(signsByIds(ids), minSize);
  }

  /// Señas que la persona ya vio (lecciones completadas) más las indicadas,
  /// para armar sesiones de repaso.
  List<Sign> learnedPool(
    Set<String> completedLessonIds, {
    Iterable<String> extraSignIds = const [],
    int minSize = 4,
  }) {
    final ids = <String>{...extraSignIds};
    for (final l in lessonsInOrder) {
      if (completedLessonIds.contains(l.id)) ids.addAll(l.signIds);
    }
    return _withMinimum(signsByIds(ids), minSize);
  }

  List<Sign> _withMinimum(List<Sign> base, int minSize) {
    if (base.length >= minSize) return base;
    final baseIds = {for (final s in base) s.id};
    final extras = signsById.values.where((s) => !baseIds.contains(s.id));
    return [...base, ...extras];
  }

  /// Estado de cada lección: la primera no completada está disponible y las
  /// siguientes quedan bloqueadas (desbloqueo progresivo).
  Map<String, LessonStatus> statuses(Set<String> completedLessonIds) {
    final result = <String, LessonStatus>{};
    var previousDone = true;
    for (final lesson in lessonsInOrder) {
      if (completedLessonIds.contains(lesson.id)) {
        result[lesson.id] = LessonStatus.completed;
      } else {
        result[lesson.id] =
            previousDone ? LessonStatus.available : LessonStatus.locked;
        previousDone = false;
      }
    }
    return result;
  }

  /// Lecciones completadas y totales de una unidad.
  ({int done, int total}) unitProgress(
    String unitId,
    Set<String> completedLessonIds,
  ) {
    final lessons = lessonsOfUnit(unitId);
    final done = lessons.where((l) => completedLessonIds.contains(l.id)).length;
    return (done: done, total: lessons.length);
  }
}
