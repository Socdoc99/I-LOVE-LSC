import 'package:flutter_test/flutter_test.dart';
import 'package:i_love_lsc/features/content/domain/course_catalog.dart';
import 'package:i_love_lsc/features/content/domain/learning_unit.dart';
import 'package:i_love_lsc/features/content/domain/lesson.dart';
import 'package:i_love_lsc/features/content/domain/sign.dart';

CourseCatalog buildCatalog() {
  return CourseCatalog(
    // Se entregan desordenados a propósito.
    units: const [
      LearningUnit(id: 'u2', title: 'Unidad 2', order: 2),
      LearningUnit(id: 'u1', title: 'Unidad 1', order: 1),
    ],
    lessons: const [
      Lesson(id: 'l3', unitId: 'u2', title: 'L3', order: 1, signIds: ['s5', 's6']),
      Lesson(id: 'l2', unitId: 'u1', title: 'L2', order: 2, signIds: ['s3', 's4']),
      Lesson(id: 'l1', unitId: 'u1', title: 'L1', order: 1, signIds: ['s1', 's2']),
      Lesson(id: 'lx', unitId: 'no-existe', title: 'LX', order: 1, signIds: ['s1']),
    ],
    signs: [
      for (var i = 1; i <= 6; i++) Sign(id: 's$i', word: 'Seña $i', unitId: 'u1'),
    ],
  );
}

void main() {
  group('Orden', () {
    test('ordena las lecciones por unidad y por orden', () {
      expect(buildCatalog().allLessonIds, ['l1', 'l2', 'l3']);
    });

    test('ordena las unidades', () {
      expect(buildCatalog().units.map((u) => u.id), ['u1', 'u2']);
    });

    test('descarta lecciones de unidades que no existen', () {
      expect(buildCatalog().lessonById('lx'), isNull);
    });
  });

  group('Desbloqueo progresivo', () {
    test('sin progreso solo la primera lección está disponible', () {
      expect(buildCatalog().statuses({}), {
        'l1': LessonStatus.available,
        'l2': LessonStatus.locked,
        'l3': LessonStatus.locked,
      });
    });

    test('al completar una lección se desbloquea la siguiente', () {
      expect(buildCatalog().statuses({'l1'}), {
        'l1': LessonStatus.completed,
        'l2': LessonStatus.available,
        'l3': LessonStatus.locked,
      });
    });

    test('se puede pasar de una unidad a la siguiente', () {
      expect(buildCatalog().statuses({'l1', 'l2'}), {
        'l1': LessonStatus.completed,
        'l2': LessonStatus.completed,
        'l3': LessonStatus.available,
      });
    });

    test('con todo completado, todo figura completado', () {
      final statuses = buildCatalog().statuses({'l1', 'l2', 'l3'});
      expect(statuses.values.every((s) => s == LessonStatus.completed), isTrue);
    });

    test('una lección posterior completada no desbloquea las demás', () {
      expect(buildCatalog().statuses({'l2'}), {
        'l1': LessonStatus.available,
        'l2': LessonStatus.completed,
        'l3': LessonStatus.locked,
      });
    });
  });

  group('Progreso por unidad', () {
    test('cuenta lecciones completadas y totales', () {
      final progress = buildCatalog().unitProgress('u1', {'l1', 'l3'});
      expect(progress.done, 1);
      expect(progress.total, 2);
    });
  });

  group('Señas', () {
    test('respeta el orden de la lección y omite señas inexistentes', () {
      const lesson = Lesson(
        id: 'lz',
        unitId: 'u1',
        title: 'LZ',
        order: 9,
        signIds: ['s4', 'fantasma', 's1'],
      );
      final signs = buildCatalog().signsOfLesson(lesson);
      expect(signs.map((s) => s.id), ['s4', 's1']);
    });

    test('el grupo de distractores incluye las señas de lecciones anteriores', () {
      final catalog = buildCatalog();
      final l2 = catalog.lessonById('l2')!;
      final ids = catalog.poolUpTo(l2).map((s) => s.id).toSet();
      expect(ids, {'s1', 's2', 's3', 's4'});
    });

    test('si son muy pocas, el grupo se completa con otras señas del curso', () {
      final catalog = buildCatalog();
      final l1 = catalog.lessonById('l1')!;
      expect(catalog.poolUpTo(l1).length, 6);
    });

    test('el grupo de repaso incluye las señas de lecciones completadas', () {
      final catalog = buildCatalog();
      final pool = catalog.learnedPool({'l1', 'l2'}, minSize: 2);
      expect(pool.map((s) => s.id).toSet(), {'s1', 's2', 's3', 's4'});
    });
  });
}
