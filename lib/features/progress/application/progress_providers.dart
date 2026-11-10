import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/progress_repository.dart';
import '../domain/gamification_rules.dart';
import '../domain/user_progress.dart';

final gamificationRulesProvider = Provider<GamificationRules>(
  (ref) => const GamificationRules(),
);

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(firestoreProvider)),
);

/// Progreso en tiempo real de la persona con sesión iniciada.
final progressProvider = StreamProvider<UserProgress>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return const Stream<UserProgress>.empty();
  return ref.watch(progressRepositoryProvider).watch(uid);
});

/// Cifras que se muestran en pantalla (vidas y racha ya ajustadas a la hora
/// actual).
class ProgressSummary {
  const ProgressSummary({
    required this.progress,
    required this.lives,
    required this.streak,
    required this.practicedToday,
    required this.minutesToNextLife,
  });

  final UserProgress progress;
  final int lives;
  final int streak;
  final bool practicedToday;
  final int? minutesToNextLife;

  int get xp => progress.xp;
}

final progressSummaryProvider = Provider<ProgressSummary?>((ref) {
  final progress = ref.watch(progressProvider).valueOrNull;
  if (progress == null) return null;
  final now = ref.watch(nowProvider).valueOrNull ?? DateTime.now();
  final rules = ref.watch(gamificationRulesProvider);
  return ProgressSummary(
    progress: progress,
    lives: rules.effectiveLives(progress, now),
    streak: rules.effectiveStreak(progress, now),
    practicedToday: rules.practicedToday(progress, now),
    minutesToNextLife: rules.minutesToNextLife(progress, now),
  );
});
