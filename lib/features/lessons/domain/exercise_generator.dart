import 'dart:math';

import '../../../core/constants/app_constants.dart';
import '../../content/domain/sign.dart';
import 'exercise.dart';

/// Genera los pasos de una lección o de un repaso a partir de las señas.
/// Recibe un [Random] para poder hacer pruebas con resultados repetibles.
class ExerciseGenerator {
  ExerciseGenerator({Random? random, this.optionCount = GamificationConfig.optionCount})
      : _random = random ?? Random();

  final Random _random;
  final int optionCount;

  /// Señas distintas de [target] (también en su palabra) tomadas de [pool].
  List<Sign> _distractors(Sign target, List<Sign> pool, int count) {
    final seenWords = <String>{target.word};
    final candidates = <Sign>[];
    for (final sign in pool) {
      if (sign.id == target.id) continue;
      if (seenWords.add(sign.word)) candidates.add(sign);
    }
    candidates.shuffle(_random);
    return candidates.take(count).toList();
  }

  SeeAndChooseExercise seeAndChoose(Sign target, List<Sign> pool) {
    final options = <String>[
      target.word,
      for (final s in _distractors(target, pool, optionCount - 1)) s.word,
    ]..shuffle(_random);
    return SeeAndChooseExercise(sign: target, options: options);
  }

  WordToSignExercise wordToSign(Sign target, List<Sign> pool) {
    final options = <Sign>[
      target,
      ..._distractors(target, pool, optionCount - 1),
    ]..shuffle(_random);
    return WordToSignExercise(target: target, options: options);
  }

  PairsExercise pairs(List<Sign> signs) {
    final words = [for (final s in signs) s.word]..shuffle(_random);
    return PairsExercise(signs: List.unmodifiable(signs), words: words);
  }

  /// Lección: presentación de cada seña, «Ver y elegir», «Palabra a seña»
  /// y un ejercicio de «Parejas» con las señas de la lección.
  List<SessionStep> buildLessonSteps({
    required List<Sign> lessonSigns,
    required List<Sign> pool,
  }) {
    final steps = <SessionStep>[
      for (final sign in lessonSigns) IntroStep(sign),
    ];

    final seeOrder = [...lessonSigns]..shuffle(_random);
    for (final sign in seeOrder) {
      steps.add(ExerciseStep(seeAndChoose(sign, pool)));
    }

    final wordOrder = [...lessonSigns]..shuffle(_random);
    for (final sign in wordOrder) {
      steps.add(ExerciseStep(wordToSign(sign, pool)));
    }

    if (lessonSigns.length >= 2) {
      steps.add(ExerciseStep(pairs(lessonSigns.take(optionCount).toList())));
    }
    return steps;
  }

  /// Repaso: para cada seña un ejercicio de «Ver y elegir» o de «Palabra a
  /// seña» (al azar), sin presentación previa.
  List<SessionStep> buildReviewSteps({
    required List<Sign> signs,
    required List<Sign> pool,
  }) {
    final shuffled = [...signs]..shuffle(_random);
    final limited = shuffled.take(GamificationConfig.reviewSessionSize);
    return [
      for (final sign in limited)
        ExerciseStep(
          _random.nextBool() ? seeAndChoose(sign, pool) : wordToSign(sign, pool),
        ),
    ];
  }
}
