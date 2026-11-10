import 'package:flutter_test/flutter_test.dart';
import 'package:i_love_lsc/core/utils/date_utils.dart';
import 'package:i_love_lsc/core/utils/validators.dart';

void main() {
  group('Fechas', () {
    test('dateKey rellena con ceros', () {
      expect(dateKey(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
    });

    test('daysBetweenKeys cuenta días de calendario', () {
      expect(daysBetweenKeys('2026-10-20', '2026-10-20'), 0);
      expect(daysBetweenKeys('2026-10-20', '2026-10-21'), 1);
      expect(daysBetweenKeys('2026-10-31', '2026-11-01'), 1);
      expect(daysBetweenKeys('2026-12-31', '2027-01-01'), 1);
      expect(daysBetweenKeys('2026-10-22', '2026-10-20'), -2);
    });

    test('una clave inválida se trata como racha rota', () {
      expect(daysBetweenKeys('basura', '2026-10-20'), greaterThan(1));
    });

    test('formatLongDate', () {
      expect(formatLongDate(DateTime(2026, 10, 20)), '20 de octubre de 2026');
      expect(formatLongDate(DateTime(2027, 1, 5)), '5 de enero de 2027');
    });
  });

  group('Validadores', () {
    test('correo', () {
      expect(Validators.email('persona@correo.com'), isNull);
      expect(Validators.email(' persona@correo.co '), isNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('persona@correo'), isNotNull);
      expect(Validators.email('persona correo.com'), isNotNull);
    });

    test('contraseña', () {
      expect(Validators.password('12345678'), isNull);
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password(''), isNotNull);
      expect(Validators.password(null), isNotNull);
    });

    test('alias', () {
      expect(Validators.alias('Ana'), isNull);
      expect(Validators.alias('A'), isNotNull);
      expect(Validators.alias('   '), isNotNull);
      expect(Validators.alias('a' * 31), isNotNull);
      expect(Validators.alias('a' * 30), isNull);
    });

    test('nombre completo', () {
      expect(Validators.fullName('Ana Pérez'), isNull);
      expect(Validators.fullName('Ana'), isNotNull);
      expect(Validators.fullName(''), isNotNull);
    });

    test('teléfono', () {
      expect(Validators.phone('312 269 7240'), isNull);
      expect(Validators.phone('+57 312 2697240'), isNull);
      expect(Validators.phone('123'), isNotNull);
      expect(Validators.phone(''), isNotNull);
    });

    test('campo obligatorio', () {
      expect(Validators.requiredField('x'), isNull);
      expect(Validators.requiredField('  '), isNotNull);
      expect(Validators.requiredField(null, message: 'Falta'), 'Falta');
    });
  });
}
