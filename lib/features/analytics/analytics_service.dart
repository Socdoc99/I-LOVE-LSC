import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Registro de eventos de uso para la evaluación del piloto (Firebase
/// Analytics). Nunca envía datos personales: solo identificadores de
/// contenido y contadores.
class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  Future<void> _log(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics ($name) falló: $e');
    }
  }

  Future<void> signUp() => _log('sign_up', {'method': 'email'});

  Future<void> lessonStarted(String lessonId) =>
      _log('lesson_started', {'lesson_id': lessonId});

  Future<void> lessonCompleted({
    required String lessonId,
    required int correctAnswers,
    required int mistakes,
  }) =>
      _log('lesson_completed', {
        'lesson_id': lessonId,
        'correct_answers': correctAnswers,
        'mistakes': mistakes,
      });

  Future<void> lessonFailedNoLives(String lessonId) =>
      _log('lesson_failed_no_lives', {'lesson_id': lessonId});

  Future<void> reviewCompleted({required int reviewedSigns}) =>
      _log('review_completed', {'reviewed_signs': reviewedSigns});

  Future<void> courseCompleted() => _log('course_completed');

  Future<void> surveySubmitted() => _log('survey_submitted');

  Future<void> collaboratorApplicationSent() =>
      _log('collaborator_application_sent');
}
