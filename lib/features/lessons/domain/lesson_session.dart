import 'exercise.dart';

/// Estado de una sesión de práctica (lección o repaso): paso actual,
/// aciertos y errores. No depende de Flutter ni de Firebase.
class LessonSession {
  LessonSession({required List<SessionStep> steps})
      : steps = List.unmodifiable(steps);

  final List<SessionStep> steps;

  int _index = 0;
  int _correctAnswers = 0;
  int _mistakes = 0;
  final Set<String> _missedSignIds = <String>{};
  final Set<String> _correctSignIds = <String>{};

  int get index => _index;
  int get correctAnswers => _correctAnswers;
  int get mistakes => _mistakes;
  bool get isFinished => _index >= steps.length;
  SessionStep get current => steps[_index];

  /// Avance de 0 a 1 para la barra de progreso.
  double get progress => steps.isEmpty ? 1 : _index / steps.length;

  Set<String> get missedSignIds => Set.unmodifiable(_missedSignIds);

  /// Señas acertadas y que nunca se fallaron en esta sesión.
  Set<String> get masteredSignIds =>
      _correctSignIds.difference(_missedSignIds);

  void registerCorrect(String signId) {
    _correctAnswers++;
    _correctSignIds.add(signId);
  }

  void registerMistake(String signId) {
    _mistakes++;
    _missedSignIds.add(signId);
  }

  void advance() {
    if (!isFinished) _index++;
  }
}
