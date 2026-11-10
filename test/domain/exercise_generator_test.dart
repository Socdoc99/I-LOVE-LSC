import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:i_love_lsc/core/constants/app_constants.dart';
import 'package:i_love_lsc/features/content/domain/sign.dart';
import 'package:i_love_lsc/features/lessons/domain/exercise.dart';
import 'package:i_love_lsc/features/lessons/domain/exercise_generator.dart';

List<Sign> makeSigns(int count) => [
      for (var i = 0; i < count; i++)
        Sign(id: 's$i', word: 'Palabra $i', unitId: 'u1'),
    ];

void main() {
  group('Ver y elegir', () {
    test('incluye la respuesta correcta y no repite opciones', () {
      final signs = makeSigns(8);
      final generator = ExerciseGenerator(random: Random(1));
      for (final sign in signs) {
        final exercise = generator.seeAndChoose(sign, signs);
        expect(exercise.options.length, GamificationConfig.optionCount);
        expect(exercise.options.toSet().length, exercise.options.length);
        expect(exercise.options, contains(sign.word));
      }
    });

    test('con pocas señas ofrece menos opciones, pero siempre la correcta', () {
      final signs = makeSigns(2);
      final exercise =
          ExerciseGenerator(random: Random(2)).seeAndChoose(signs[0], signs);
      expect(exercise.options.length, 2);
      expect(exercise.options, contains('Palabra 0'));
    });

    test('no usa como distractor una seña con la misma palabra', () {
      const signs = [
        Sign(id: 'a', word: 'Hola', unitId: 'u1'),
        Sign(id: 'b', word: 'Hola', unitId: 'u1'),
        Sign(id: 'c', word: 'Adiós', unitId: 'u1'),
      ];
      final exercise =
          ExerciseGenerator(random: Random(3)).seeAndChoose(signs[0], signs);
      expect(exercise.options.toSet(), {'Hola', 'Adiós'});
      expect(exercise.options.length, 2);
    });
  });

  group('Palabra a seña', () {
    test('las opciones son únicas e incluyen la seña correcta', () {
      final signs = makeSigns(6);
      final generator = ExerciseGenerator(random: Random(4));
      final exercise = generator.wordToSign(signs[2], signs);
      final ids = exercise.options.map((s) => s.id).toList();
      expect(ids.length, GamificationConfig.optionCount);
      expect(ids.toSet().length, ids.length);
      expect(ids, contains('s2'));
      expect(exercise.target.id, 's2');
    });
  });

  group('Parejas', () {
    test('las palabras son las mismas que las señas', () {
      final signs = makeSigns(4);
      final exercise = ExerciseGenerator(random: Random(5)).pairs(signs);
      final expected = signs.map((s) => s.word).toList()..sort();
      final actual = [...exercise.words]..sort();
      expect(actual, expected);
      expect(exercise.signs.length, 4);
    });
  });

  group('Lección completa', () {
    test('presenta las señas, luego los ejercicios y al final las parejas', () {
      final signs = makeSigns(6);
      final lessonSigns = signs.take(4).toList();
      final steps = ExerciseGenerator(random: Random(6)).buildLessonSteps(
        lessonSigns: lessonSigns,
        pool: signs,
      );

      expect(steps.take(4).every((s) => s is IntroStep), isTrue);
      expect(steps.whereType<IntroStep>().length, 4);

      final exercises = [
        for (final step in steps.whereType<ExerciseStep>()) step.exercise,
      ];
      expect(exercises.whereType<SeeAndChooseExercise>().length, 4);
      expect(exercises.whereType<WordToSignExercise>().length, 4);
      expect(exercises.whereType<PairsExercise>().length, 1);
      expect(exercises.last, isA<PairsExercise>());
      expect(steps.length, 4 + 4 + 4 + 1);
    });

    test('una lección con una sola seña no genera parejas', () {
      final signs = makeSigns(5);
      final steps = ExerciseGenerator(random: Random(7)).buildLessonSteps(
        lessonSigns: [signs.first],
        pool: signs,
      );
      final exercises = [
        for (final step in steps.whereType<ExerciseStep>()) step.exercise,
      ];
      expect(exercises.whereType<PairsExercise>(), isEmpty);
      expect(steps.length, 3);
    });
  });

  group('Repaso', () {
    test('limita el tamaño de la sesión y no incluye presentaciones', () {
      final signs = makeSigns(12);
      final steps = ExerciseGenerator(random: Random(8)).buildReviewSteps(
        signs: signs,
        pool: signs,
      );
      expect(steps.length, GamificationConfig.reviewSessionSize);
      expect(steps.every((s) => s is ExerciseStep), isTrue);
    });

    test('con pocas señas, una por ejercicio', () {
      final signs = makeSigns(3);
      final steps = ExerciseGenerator(random: Random(9)).buildReviewSteps(
        signs: signs,
        pool: signs,
      );
      expect(steps.length, 3);
    });
  });
}
