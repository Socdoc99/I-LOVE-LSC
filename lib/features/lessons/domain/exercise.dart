import '../../content/domain/sign.dart';

/// Ejercicio de práctica. Hay tres tipos:
///
/// * [SeeAndChooseExercise] — «Ver y elegir»: se observa la seña y se elige
///   su significado.
/// * [WordToSignExercise] — «Palabra a seña»: se lee una palabra y se elige
///   el video correcto.
/// * [PairsExercise] — «Parejas»: se emparejan videos con palabras.
sealed class Exercise {
  const Exercise();

  /// Texto que se muestra como respuesta correcta al fallar.
  String get correctLabel;
}

class SeeAndChooseExercise extends Exercise {
  const SeeAndChooseExercise({required this.sign, required this.options});

  final Sign sign;

  /// Palabras posibles (incluye la correcta), ya mezcladas.
  final List<String> options;

  @override
  String get correctLabel => sign.word;
}

class WordToSignExercise extends Exercise {
  const WordToSignExercise({required this.target, required this.options});

  final Sign target;

  /// Señas posibles (incluye la correcta), ya mezcladas.
  final List<Sign> options;

  @override
  String get correctLabel => target.word;
}

class PairsExercise extends Exercise {
  const PairsExercise({required this.signs, required this.words});

  final List<Sign> signs;

  /// Las mismas palabras de [signs], en otro orden.
  final List<String> words;

  @override
  String get correctLabel => 'Une cada seña con su palabra';
}

/// Paso de una sesión de práctica.
sealed class SessionStep {
  const SessionStep();
}

/// Presentación de una seña nueva (video + palabra), sin calificación.
class IntroStep extends SessionStep {
  const IntroStep(this.sign);

  final Sign sign;
}

class ExerciseStep extends SessionStep {
  const ExerciseStep(this.exercise);

  final Exercise exercise;
}
