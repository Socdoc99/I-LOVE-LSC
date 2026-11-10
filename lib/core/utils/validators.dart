/// Validadores de formularios. Devuelven `null` si el valor es válido o el
/// mensaje de error en español.
class Validators {
  const Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? requiredField(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'Este campo es obligatorio';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe tu correo electrónico';
    return _emailPattern.hasMatch(text) ? null : 'Escribe un correo válido';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Escribe una contraseña';
    if (value.length < 8) return 'Usa al menos 8 caracteres';
    return null;
  }

  static String? alias(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe un nombre o alias';
    if (text.length < 2) return 'Usa al menos 2 caracteres';
    if (text.length > 30) return 'Usa máximo 30 caracteres';
    return null;
  }

  static String? fullName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe tu nombre completo';
    if (text.length < 5) return 'Escribe tu nombre y apellido';
    return null;
  }

  /// Teléfono con 7 a 15 dígitos (se aceptan espacios, guiones y `+`).
  static String? phone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Escribe un número de contacto';
    if (digits.length < 7 || digits.length > 15) {
      return 'Escribe un número de teléfono válido';
    }
    return null;
  }
}
