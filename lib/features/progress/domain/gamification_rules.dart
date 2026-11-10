import 'dart:math' as math;

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import 'user_progress.dart';

/// Reglas de la gamificación. Son funciones puras: reciben un
/// [UserProgress] y devuelven uno nuevo, de modo que se pueden probar sin
/// Firebase.
class GamificationRules {
  const GamificationRules();

  // ---------------------------------------------------------------- Vidas

  /// Aplica la recuperación de vidas acumulada hasta [now].
  UserProgress refreshLives(UserProgress p, DateTime now) {
    const maxLives = GamificationConfig.maxLives;
    if (p.lives >= maxLives) {
      return p.copyWith(lives: maxLives, livesUpdatedAt: now);
    }
    final elapsedMinutes = now.difference(p.livesUpdatedAt).inMinutes;
    final gained = elapsedMinutes ~/ GamificationConfig.lifeRegenMinutes;
    if (gained <= 0) return p;
    final newLives = p.lives + gained;
    if (newLives >= maxLives) {
      return p.copyWith(lives: maxLives, livesUpdatedAt: now);
    }
    return p.copyWith(
      lives: newLives,
      livesUpdatedAt: p.livesUpdatedAt.add(
        Duration(minutes: gained * GamificationConfig.lifeRegenMinutes),
      ),
    );
  }

  int effectiveLives(UserProgress p, DateTime now) =>
      refreshLives(p, now).lives;

  /// Minutos que faltan para recuperar la próxima vida, o `null` si ya
  /// tiene todas.
  int? minutesToNextLife(UserProgress p, DateTime now) {
    final fresh = refreshLives(p, now);
    if (fresh.lives >= GamificationConfig.maxLives) return null;
    final elapsed = now.difference(fresh.livesUpdatedAt).inMinutes;
    return math.max(1, GamificationConfig.lifeRegenMinutes - elapsed);
  }

  UserProgress loseLife(UserProgress p, DateTime now) {
    final fresh = refreshLives(p, now);
    if (fresh.lives <= 0) return fresh;
    final wasFull = fresh.lives >= GamificationConfig.maxLives;
    return fresh.copyWith(
      lives: fresh.lives - 1,
      livesUpdatedAt: wasFull ? now : fresh.livesUpdatedAt,
    );
  }

  /// Una respuesta incorrecta resta una vida y manda la seña a repaso.
  UserProgress registerWrongAnswer(
    UserProgress p,
    String signId,
    DateTime now,
  ) {
    final afterLife = loseLife(p, now);
    if (afterLife.reviewSignIds.contains(signId)) return afterLife;
    return afterLife.copyWith(
      reviewSignIds: [...afterLife.reviewSignIds, signId],
    );
  }

  // ---------------------------------------------------------------- Racha

  /// Racha vigente: si pasó más de un día sin practicar, vale 0.
  int effectiveStreak(UserProgress p, DateTime now) {
    final last = p.lastActivityDate;
    if (last == null) return 0;
    final gap = daysBetweenKeys(last, dateKey(now));
    return gap <= 1 ? p.streak : 0;
  }

  bool practicedToday(UserProgress p, DateTime now) =>
      p.lastActivityDate == dateKey(now);

  /// Registra práctica en el día de [now] y actualiza la racha.
  UserProgress registerActivity(UserProgress p, DateTime now) {
    final today = dateKey(now);
    final last = p.lastActivityDate;
    if (last == today) return p;
    if (last == null) {
      return p.copyWith(streak: 1, lastActivityDate: today);
    }
    final gap = daysBetweenKeys(last, today);
    if (gap < 0) return p;
    final newStreak = gap == 1 ? p.streak + 1 : 1;
    return p.copyWith(streak: newStreak, lastActivityDate: today);
  }

  // ------------------------------------------------------------------ XP

  int lessonXp({required int correctAnswers, required int mistakes}) {
    final perfectBonus =
        mistakes == 0 ? GamificationConfig.xpPerfectLessonBonus : 0;
    return correctAnswers * GamificationConfig.xpPerCorrectAnswer +
        GamificationConfig.xpLessonCompletion +
        perfectBonus;
  }

  int reviewXp(int reviewedSigns) =>
      reviewedSigns * GamificationConfig.xpPerReviewedSign;

  // ------------------------------------------------- Cierre de una sesión

  UserProgress completeLesson(
    UserProgress p, {
    required String lessonId,
    required int correctAnswers,
    required int mistakes,
    required List<String> allLessonIds,
    required DateTime now,
  }) {
    final completed = p.completedLessonIds.contains(lessonId)
        ? p.completedLessonIds
        : [...p.completedLessonIds, lessonId];
    var next = p.copyWith(
      xp: p.xp +
          lessonXp(correctAnswers: correctAnswers, mistakes: mistakes),
      completedLessonIds: completed,
    );
    next = registerActivity(next, now);
    final courseDone =
        allLessonIds.isNotEmpty && allLessonIds.every(completed.contains);
    if (next.completedAt == null && courseDone) {
      next = next.copyWith(completedAt: now);
    }
    return next;
  }

  /// Cierra un repaso: quita de la lista las señas acertadas sin errores y
  /// suma XP. Un repaso no gasta vidas.
  UserProgress completeReview(
    UserProgress p, {
    required Set<String> reviewedSignIds,
    required DateTime now,
  }) {
    final remaining =
        p.reviewSignIds.where((id) => !reviewedSignIds.contains(id)).toList();
    final next = p.copyWith(
      xp: p.xp + reviewXp(reviewedSignIds.length),
      reviewSignIds: remaining,
    );
    return registerActivity(next, now);
  }
}
