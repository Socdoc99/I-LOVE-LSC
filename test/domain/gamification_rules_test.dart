import 'package:flutter_test/flutter_test.dart';
import 'package:i_love_lsc/core/constants/app_constants.dart';
import 'package:i_love_lsc/features/progress/domain/gamification_rules.dart';
import 'package:i_love_lsc/features/progress/domain/user_progress.dart';

void main() {
  const rules = GamificationRules();
  final t0 = DateTime(2026, 10, 20, 9, 0);
  final day1 = DateTime(2026, 10, 20, 10, 0);

  group('Vidas', () {
    test('se empieza con las vidas máximas', () {
      expect(UserProgress.initial(t0).lives, GamificationConfig.maxLives);
    });

    test('perder una vida inicia el contador de recuperación', () {
      final p = rules.loseLife(UserProgress.initial(t0), t0);
      expect(p.lives, 4);
      expect(p.livesUpdatedAt, t0);
    });

    test('se recupera una vida cada 30 minutos', () {
      var p = UserProgress.initial(t0);
      p = rules.loseLife(p, t0); // 4
      p = rules.loseLife(p, t0); // 3

      expect(rules.effectiveLives(p, t0), 3);
      expect(rules.effectiveLives(p, t0.add(const Duration(minutes: 29))), 3);
      expect(rules.effectiveLives(p, t0.add(const Duration(minutes: 30))), 4);
      expect(rules.effectiveLives(p, t0.add(const Duration(minutes: 60))), 5);
      expect(rules.effectiveLives(p, t0.add(const Duration(hours: 10))), 5);
    });

    test('las vidas nunca bajan de cero', () {
      var p = UserProgress.initial(t0);
      for (var i = 0; i < 8; i++) {
        p = rules.loseLife(p, t0);
      }
      expect(p.lives, 0);
    });

    test('minutos para la próxima vida', () {
      final p = rules.loseLife(UserProgress.initial(t0), t0);
      expect(rules.minutesToNextLife(p, t0), 30);
      expect(
        rules.minutesToNextLife(p, t0.add(const Duration(minutes: 10))),
        20,
      );
      expect(rules.minutesToNextLife(UserProgress.initial(t0), t0), isNull);
    });

    test('una respuesta incorrecta resta una vida y manda la seña a repaso', () {
      var p = rules.registerWrongAnswer(UserProgress.initial(t0), 'hola', t0);
      p = rules.registerWrongAnswer(p, 'hola', t0);
      expect(p.lives, 3);
      expect(p.reviewSignIds, ['hola']);
    });
  });

  group('Racha', () {
    test('la primera práctica inicia la racha en 1', () {
      final p = rules.registerActivity(UserProgress.initial(day1), day1);
      expect(p.streak, 1);
      expect(p.lastActivityDate, '2026-10-20');
    });

    test('practicar dos veces el mismo día no suma', () {
      var p = rules.registerActivity(UserProgress.initial(day1), day1);
      p = rules.registerActivity(p, day1.add(const Duration(hours: 5)));
      expect(p.streak, 1);
    });

    test('días consecutivos suman a la racha', () {
      var p = rules.registerActivity(UserProgress.initial(day1), day1);
      p = rules.registerActivity(p, DateTime(2026, 10, 21, 8));
      p = rules.registerActivity(p, DateTime(2026, 10, 22, 8));
      expect(p.streak, 3);
    });

    test('saltarse un día reinicia la racha a 1', () {
      var p = rules.registerActivity(UserProgress.initial(day1), day1);
      p = rules.registerActivity(p, DateTime(2026, 10, 23, 8));
      expect(p.streak, 1);
    });

    test('la racha vigente vale 0 si pasó más de un día', () {
      final p = rules.registerActivity(UserProgress.initial(day1), day1);
      expect(rules.effectiveStreak(p, DateTime(2026, 10, 20, 23)), 1);
      expect(rules.effectiveStreak(p, DateTime(2026, 10, 21, 23)), 1);
      expect(rules.effectiveStreak(p, DateTime(2026, 10, 22, 1)), 0);
      expect(rules.effectiveStreak(UserProgress.initial(day1), day1), 0);
    });

    test('practicedToday', () {
      final p = rules.registerActivity(UserProgress.initial(day1), day1);
      expect(rules.practicedToday(p, DateTime(2026, 10, 20, 23)), isTrue);
      expect(rules.practicedToday(p, DateTime(2026, 10, 21, 1)), isFalse);
    });

    test('la racha continúa al cambiar de mes', () {
      var p = rules.registerActivity(
        UserProgress.initial(day1),
        DateTime(2026, 10, 31, 20),
      );
      p = rules.registerActivity(p, DateTime(2026, 11, 1, 9));
      expect(p.streak, 2);
    });
  });

  group('XP y cierre de sesión', () {
    test('XP de una lección', () {
      // 8 aciertos * 10 + 20 de la lección + 10 de bono sin errores.
      expect(rules.lessonXp(correctAnswers: 8, mistakes: 0), 110);
      // Con un error no hay bono.
      expect(rules.lessonXp(correctAnswers: 7, mistakes: 1), 90);
    });

    test('XP de un repaso', () {
      expect(rules.reviewXp(3), 15);
    });

    test('completar una lección suma XP, racha y la marca como hecha', () {
      final p = rules.completeLesson(
        UserProgress.initial(day1),
        lessonId: 'l1',
        correctAnswers: 4,
        mistakes: 0,
        allLessonIds: const ['l1', 'l2'],
        now: day1,
      );
      expect(p.xp, 70);
      expect(p.completedLessonIds, ['l1']);
      expect(p.streak, 1);
      expect(p.completedAt, isNull);
    });

    test('repetir una lección no la duplica', () {
      var p = UserProgress.initial(day1);
      for (var i = 0; i < 2; i++) {
        p = rules.completeLesson(
          p,
          lessonId: 'l1',
          correctAnswers: 4,
          mistakes: 0,
          allLessonIds: const ['l1', 'l2'],
          now: day1,
        );
      }
      expect(p.completedLessonIds, ['l1']);
    });

    test('al completar todas las lecciones se registra el cierre del recorrido', () {
      var p = UserProgress.initial(day1);
      p = rules.completeLesson(
        p,
        lessonId: 'l1',
        correctAnswers: 4,
        mistakes: 0,
        allLessonIds: const ['l1', 'l2'],
        now: day1,
      );
      expect(p.completedAt, isNull);
      final later = DateTime(2026, 10, 21, 10);
      p = rules.completeLesson(
        p,
        lessonId: 'l2',
        correctAnswers: 4,
        mistakes: 1,
        allLessonIds: const ['l1', 'l2'],
        now: later,
      );
      expect(p.completedAt, later);
      expect(p.streak, 2);
    });

    test('completar un repaso quita las señas dominadas y suma XP', () {
      final start = UserProgress(
        livesUpdatedAt: day1,
        reviewSignIds: const ['a', 'b', 'c'],
      );
      final p = rules.completeReview(
        start,
        reviewedSignIds: {'a', 'c'},
        now: day1,
      );
      expect(p.reviewSignIds, ['b']);
      expect(p.xp, 10);
      expect(p.streak, 1);
    });
  });
}
