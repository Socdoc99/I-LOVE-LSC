import 'package:flutter_test/flutter_test.dart';
import 'package:i_love_lsc/features/content/domain/sign.dart';
import 'package:i_love_lsc/features/lessons/domain/exercise.dart';
import 'package:i_love_lsc/features/lessons/domain/lesson_session.dart';

void main() {
  const a = Sign(id: 'a', word: 'A', unitId: 'u1');
  const b = Sign(id: 'b', word: 'B', unitId: 'u1');

  test('avanza por los pasos y termina al final', () {
    final session = LessonSession(steps: const [IntroStep(a), IntroStep(b)]);
    expect(session.isFinished, isFalse);
    expect(session.progress, 0);

    session.advance();
    expect(session.progress, 0.5);
    expect(session.isFinished, isFalse);

    session.advance();
    expect(session.progress, 1);
    expect(session.isFinished, isTrue);

    session.advance(); // No pasa del final.
    expect(session.index, 2);
  });

  test('cuenta aciertos y errores', () {
    final session = LessonSession(steps: const [IntroStep(a)]);
    session.registerCorrect('a');
    session.registerCorrect('a');
    session.registerMistake('b');
    expect(session.correctAnswers, 2);
    expect(session.mistakes, 1);
    expect(session.missedSignIds, {'b'});
  });

  test('una seña fallada alguna vez no cuenta como dominada', () {
    final session = LessonSession(steps: const [IntroStep(a)]);
    session.registerCorrect('a');
    session.registerMistake('b');
    session.registerCorrect('b');
    expect(session.masteredSignIds, {'a'});
  });

  test('una sesión sin pasos está terminada', () {
    final session = LessonSession(steps: const []);
    expect(session.isFinished, isTrue);
    expect(session.progress, 1);
  });
}
