import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/user_progress.dart';

/// Guarda y lee el progreso de cada persona en `progress/{uid}`.
class ProgressRepository {
  ProgressRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('progress').doc(uid);

  /// Progreso en tiempo real. Si aún no existe, se emite el progreso inicial.
  Stream<UserProgress> watch(String uid) {
    return _doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      final now = DateTime.now();
      return data == null ? UserProgress.initial(now) : progressFromMap(data, now);
    });
  }

  /// Lee, transforma y guarda el progreso dentro de una transacción, para que
  /// varias respuestas seguidas no se pisen entre sí.
  Future<UserProgress> mutate(
    String uid,
    UserProgress Function(UserProgress current) change,
  ) {
    final ref = _doc(uid);
    return _firestore.runTransaction<UserProgress>((transaction) async {
      final snapshot = await transaction.get(ref);
      final now = DateTime.now();
      final data = snapshot.data();
      final current =
          data == null ? UserProgress.initial(now) : progressFromMap(data, now);
      final next = change(current);
      transaction.set(ref, progressToMap(next));
      return next;
    });
  }
}

UserProgress progressFromMap(Map<String, dynamic> data, DateTime fallbackNow) {
  final lives = (data['lives'] as num?)?.toInt() ?? GamificationConfig.maxLives;
  return UserProgress(
    xp: (data['xp'] as num?)?.toInt() ?? 0,
    streak: (data['streak'] as num?)?.toInt() ?? 0,
    lastActivityDate: data['lastActivityDate'] as String?,
    lives: math.max(0, math.min(GamificationConfig.maxLives, lives)),
    livesUpdatedAt:
        (data['livesUpdatedAt'] as Timestamp?)?.toDate() ?? fallbackNow,
    completedLessonIds:
        List<String>.from((data['completedLessonIds'] as List?) ?? const []),
    reviewSignIds:
        List<String>.from((data['reviewSignIds'] as List?) ?? const []),
    completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
  );
}

Map<String, dynamic> progressToMap(UserProgress p) {
  return {
    'xp': p.xp,
    'streak': p.streak,
    'lastActivityDate': p.lastActivityDate,
    'lives': p.lives,
    'livesUpdatedAt': Timestamp.fromDate(p.livesUpdatedAt),
    'completedLessonIds': p.completedLessonIds,
    'reviewSignIds': p.reviewSignIds,
    'completedAt':
        p.completedAt == null ? null : Timestamp.fromDate(p.completedAt!),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
