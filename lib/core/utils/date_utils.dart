/// Clave de calendario `yyyy-MM-dd` de una fecha (en su zona horaria local).
String dateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

const List<String> _monthNames = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Fecha en español, por ejemplo «20 de octubre de 2026».
String formatLongDate(DateTime date) {
  return '${date.day} de ${_monthNames[date.month - 1]} de ${date.year}';
}

/// Días de calendario entre dos claves `yyyy-MM-dd` (resultado = [b] - [a]).
///
/// Si alguna clave es inválida devuelve un valor muy grande, de modo que la
/// racha se considere interrumpida en lugar de lanzar una excepción.
int daysBetweenKeys(String a, String b) {
  try {
    final first = _parseKey(a);
    final second = _parseKey(b);
    return second.difference(first).inDays;
  } catch (_) {
    return 100000;
  }
}

DateTime _parseKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) {
    throw FormatException('Clave de fecha inválida: $key');
  }
  return DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}
