/// Constantes generales de la aplicación.
class AppConstants {
  const AppConstants._();

  static const String appName = 'I Love LSC';
  static const String slogan = 'La Seña Universal para el Cambio';
  static const String supportEmail = 'love25universal@gmail.com';

  /// Versión de los textos legales que aceptó la persona al registrarse.
  static const String policyVersion = '1.0-borrador';

  /// Tema de Firebase Cloud Messaging para los recordatorios de práctica.
  static const String reminderTopic = 'recordatorios_practica';
}

/// Parámetros de la gamificación (XP, vidas, racha y repaso).
class GamificationConfig {
  const GamificationConfig._();

  static const int maxLives = 5;

  /// Cada cuántos minutos se recupera una vida.
  static const int lifeRegenMinutes = 30;

  static const int xpPerCorrectAnswer = 10;
  static const int xpLessonCompletion = 20;
  static const int xpPerfectLessonBonus = 10;
  static const int xpPerReviewedSign = 5;

  /// Máximo de señas por sesión de repaso.
  static const int reviewSessionSize = 8;

  /// Número de opciones en los ejercicios de elección.
  static const int optionCount = 4;
}
