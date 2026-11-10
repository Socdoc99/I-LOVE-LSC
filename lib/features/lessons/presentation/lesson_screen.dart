import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/state_views.dart';
import '../../content/application/content_providers.dart';
import '../../progress/application/progress_providers.dart';
import '../domain/exercise.dart';
import '../domain/exercise_generator.dart';
import 'practice_session_screen.dart';

/// Carga el contenido de una lección y arma una sola vez sus pasos.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  List<SessionStep>? _steps;
  int _initialLives = 0;
  String _title = '';
  List<String> _allLessonIds = const [];

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    if (steps != null) {
      return PracticeSessionScreen(
        key: ValueKey('lesson-${widget.lessonId}'),
        mode: SessionMode.lesson,
        title: _title,
        steps: steps,
        initialLives: _initialLives,
        lessonId: widget.lessonId,
        allLessonIds: _allLessonIds,
      );
    }

    final catalogAsync = ref.watch(catalogProvider);
    final summary = ref.watch(progressSummaryProvider);

    return catalogAsync.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: 'No pudimos cargar la lección. Revisa tu conexión.',
          onRetry: () => ref.invalidate(catalogProvider),
        ),
      ),
      data: (catalog) {
        final lesson = catalog.lessonById(widget.lessonId);
        if (lesson == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyView(
              icon: Icons.search_off,
              message: 'Esta lección no está disponible.',
            ),
          );
        }
        final signs = catalog.signsOfLesson(lesson);
        if (signs.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyView(
              icon: Icons.hourglass_empty,
              message: 'Esta lección todavía no tiene señas.',
            ),
          );
        }
        if (summary == null) return const Scaffold(body: LoadingView());

        // Los pasos se arman una sola vez para que no cambien al recibir
        // actualizaciones de progreso durante la sesión.
        _steps = ExerciseGenerator().buildLessonSteps(
          lessonSigns: signs,
          pool: catalog.poolUpTo(lesson),
        );
        _initialLives = summary.lives;
        _title = lesson.title;
        _allLessonIds = catalog.allLessonIds;
        return PracticeSessionScreen(
          key: ValueKey('lesson-${widget.lessonId}'),
          mode: SessionMode.lesson,
          title: _title,
          steps: _steps!,
          initialLives: _initialLives,
          lessonId: widget.lessonId,
          allLessonIds: _allLessonIds,
        );
      },
    );
  }
}
