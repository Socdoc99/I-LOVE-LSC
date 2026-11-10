import '../../../core/constants/app_constants.dart';

/// Progreso de una persona: lecciones completadas, XP, racha, vidas y repaso.
/// Es inmutable: para cambiarlo se usa [copyWith].
class UserProgress {
  const UserProgress({
    this.xp = 0,
    this.streak = 0,
    this.lastActivityDate,
    this.lives = GamificationConfig.maxLives,
    required this.livesUpdatedAt,
    this.completedLessonIds = const <String>[],
    this.reviewSignIds = const <String>[],
    this.completedAt,
  });

  factory UserProgress.initial(DateTime now) =>
      UserProgress(livesUpdatedAt: now);

  final int xp;

  /// Días seguidos con práctica (ver `GamificationRules.effectiveStreak`).
  final int streak;

  /// Último día con práctica, como `yyyy-MM-dd`.
  final String? lastActivityDate;
  final int lives;

  /// Momento desde el cual se cuenta la recuperación de vidas.
  final DateTime livesUpdatedAt;
  final List<String> completedLessonIds;

  /// Señas en las que la persona se equivocó y debe repasar.
  final List<String> reviewSignIds;

  /// Momento en que completó todo el recorrido (constancia o insignia).
  final DateTime? completedAt;

  /// Copia con los campos indicados. No permite volver un campo opcional a
  /// `null` (la app nunca lo necesita).
  UserProgress copyWith({
    int? xp,
    int? streak,
    String? lastActivityDate,
    int? lives,
    DateTime? livesUpdatedAt,
    List<String>? completedLessonIds,
    List<String>? reviewSignIds,
    DateTime? completedAt,
  }) {
    return UserProgress(
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      lives: lives ?? this.lives,
      livesUpdatedAt: livesUpdatedAt ?? this.livesUpdatedAt,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      reviewSignIds: reviewSignIds ?? this.reviewSignIds,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
