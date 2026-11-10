import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../analytics/analytics_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../progress/application/progress_providers.dart';
import '../../progress/domain/user_progress.dart';
import '../domain/exercise.dart';
import '../domain/lesson_session.dart';
import 'widgets/intro_view.dart';
import 'widgets/pairs_view.dart';
import 'widgets/see_and_choose_view.dart';
import 'widgets/word_to_sign_view.dart';

enum SessionMode { lesson, review }

enum _Phase { running, saving, result, outOfLives, error }

/// Pantalla de práctica: sirve para una lección (con vidas) y para un repaso
/// (sin gastar vidas). Recibe los pasos ya armados.
class PracticeSessionScreen extends ConsumerStatefulWidget {
  const PracticeSessionScreen({
    super.key,
    required this.mode,
    required this.title,
    required this.steps,
    required this.initialLives,
    this.lessonId,
    this.allLessonIds = const <String>[],
  });

  final SessionMode mode;
  final String title;
  final List<SessionStep> steps;
  final int initialLives;

  /// Solo para `SessionMode.lesson`.
  final String? lessonId;
  final List<String> allLessonIds;

  @override
  ConsumerState<PracticeSessionScreen> createState() =>
      _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen> {
  late final LessonSession _session;
  late int _lives;

  _Phase _phase = _Phase.running;
  bool _stepDone = false;
  bool _currentHadMistake = false;
  String _feedback = '';
  bool _allowExit = false;

  int _xpGained = 0;
  int _streakAfter = 0;
  bool _courseCompleted = false;

  bool get _isLesson => widget.mode == SessionMode.lesson;

  @override
  void initState() {
    super.initState();
    _session = LessonSession(steps: widget.steps);
    _lives = widget.initialLives;
    if (_isLesson) {
      if (_lives <= 0) {
        _phase = _Phase.outOfLives;
      } else {
        ref.read(analyticsProvider).lessonStarted(widget.lessonId ?? '');
      }
    }
  }

  // ------------------------------------------------------------ Respuestas

  void _onAnswer(bool correct, String signId) {
    if (correct) {
      _session.registerCorrect(signId);
      setState(() {});
      return;
    }

    _session.registerMistake(signId);
    var stopNow = false;
    if (_isLesson) {
      _lives = math.max(0, _lives - 1);
      _persistMistake(signId);
      // En «Parejas» no hay pantalla intermedia: si no quedan vidas se corta.
      final step = _session.current;
      final isPairs = step is ExerciseStep && step.exercise is PairsExercise;
      stopNow = _lives == 0 && isPairs;
    }
    setState(() {
      _currentHadMistake = true;
      if (stopNow) _phase = _Phase.outOfLives;
    });
    if (stopNow) {
      ref.read(analyticsProvider).lessonFailedNoLives(widget.lessonId ?? '');
    }
  }

  void _onDone() {
    final step = _session.current;
    var text = '';
    if (step is ExerciseStep) {
      final exercise = step.exercise;
      if (exercise is PairsExercise) {
        text = _currentHadMistake
            ? 'Completaste las parejas, con algunos errores.'
            : '¡Todas las parejas correctas!';
      } else {
        text = _currentHadMistake
            ? 'Respuesta correcta: ${exercise.correctLabel}'
            : '¡Correcto!';
      }
    }
    setState(() {
      _stepDone = true;
      _feedback = text;
    });
  }

  /// Guarda de inmediato el error: resta una vida y manda la seña a repaso.
  Future<void> _persistMistake(String signId) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    final repository = ref.read(progressRepositoryProvider);
    final rules = ref.read(gamificationRulesProvider);
    try {
      await repository.mutate(
        uid,
        (p) => rules.registerWrongAnswer(p, signId, DateTime.now()),
      );
    } catch (e) {
      debugPrint('No se pudo guardar el error: $e');
    }
  }

  // ------------------------------------------------------------ Navegación

  void _next() {
    if (_isLesson && _lives == 0) {
      ref.read(analyticsProvider).lessonFailedNoLives(widget.lessonId ?? '');
      setState(() => _phase = _Phase.outOfLives);
      return;
    }
    _session.advance();
    if (_session.isFinished) {
      _finish();
      return;
    }
    setState(() {
      _stepDone = false;
      _currentHadMistake = false;
      _feedback = '';
    });
  }

  Future<void> _finish() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) {
      setState(() => _phase = _Phase.error);
      return;
    }
    setState(() => _phase = _Phase.saving);

    final repository = ref.read(progressRepositoryProvider);
    final rules = ref.read(gamificationRulesProvider);
    final analytics = ref.read(analyticsProvider);
    final previous = ref.read(progressProvider).valueOrNull;
    final allLessonIds = widget.allLessonIds;
    final lessonId = widget.lessonId;
    final correctAnswers = _session.correctAnswers;
    final mistakes = _session.mistakes;
    final mastered = _session.masteredSignIds;
    final now = DateTime.now();

    try {
      final UserProgress next;
      final int xp;
      if (_isLesson && lessonId != null) {
        xp = rules.lessonXp(correctAnswers: correctAnswers, mistakes: mistakes);
        next = await repository.mutate(
          uid,
          (p) => rules.completeLesson(
            p,
            lessonId: lessonId,
            correctAnswers: correctAnswers,
            mistakes: mistakes,
            allLessonIds: allLessonIds,
            now: now,
          ),
        );
        analytics.lessonCompleted(
          lessonId: lessonId,
          correctAnswers: correctAnswers,
          mistakes: mistakes,
        );
      } else {
        xp = rules.reviewXp(mastered.length);
        next = await repository.mutate(
          uid,
          (p) => rules.completeReview(p, reviewedSignIds: mastered, now: now),
        );
        analytics.reviewCompleted(reviewedSigns: mastered.length);
      }

      final courseDone = previous?.completedAt == null && next.completedAt != null;
      if (courseDone) analytics.courseCompleted();
      if (!mounted) return;
      setState(() {
        _phase = _Phase.result;
        _xpGained = xp;
        _streakAfter = next.streak;
        _courseCompleted = courseDone;
      });
    } catch (e) {
      debugPrint('No se pudo guardar el progreso: $e');
      if (!mounted) return;
      setState(() => _phase = _Phase.error);
    }
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Salir de la sesión?'),
        content: const Text('Perderás el avance de esta sesión.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Seguir practicando'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      setState(() => _allowExit = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    }
  }

  // ---------------------------------------------------------------- Vistas

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowExit || _phase != _Phase.running,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _phase == _Phase.running) _confirmExit();
      },
      child: Scaffold(
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.running:
        return _buildRunning();
      case _Phase.saving:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Guardando tu progreso…'),
            ],
          ),
        );
      case _Phase.result:
        return _ResultView(
          isLesson: _isLesson,
          correctAnswers: _session.correctAnswers,
          mistakes: _session.mistakes,
          xpGained: _xpGained,
          streak: _streakAfter,
          courseCompleted: _courseCompleted,
        );
      case _Phase.outOfLives:
        return const _OutOfLivesView();
      case _Phase.error:
        return _ErrorSavingView(onRetry: _finish);
    }
  }

  Widget _buildRunning() {
    return Column(
      children: [
        _TopBar(
          progress: _session.progress,
          lives: _isLesson ? _lives : null,
          onClose: _confirmExit,
        ),
        Expanded(child: _buildStep()),
        _buildBottom(),
      ],
    );
  }

  Widget _buildStep() {
    final step = _session.current;
    final key = ValueKey('step-${_session.index}');
    if (step is IntroStep) {
      return IntroView(key: key, sign: step.sign);
    }
    final exercise = (step as ExerciseStep).exercise;
    return switch (exercise) {
      final SeeAndChooseExercise e => SeeAndChooseView(
          key: key,
          exercise: e,
          onAnswer: _onAnswer,
          onDone: _onDone,
        ),
      final WordToSignExercise e => WordToSignView(
          key: key,
          exercise: e,
          onAnswer: _onAnswer,
          onDone: _onDone,
        ),
      final PairsExercise e => PairsView(
          key: key,
          exercise: e,
          onAnswer: _onAnswer,
          onDone: _onDone,
        ),
    };
  }

  Widget _buildBottom() {
    final step = _session.current;
    if (step is IntroStep) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(onPressed: _next, child: const Text('Entendido')),
      );
    }
    if (!_stepDone) return const SizedBox.shrink();
    final isLast = _session.index == _session.steps.length - 1;
    return _FeedbackBar(
      isCorrect: !_currentHadMistake,
      message: _feedback,
      buttonLabel: isLast ? 'Finalizar' : 'Continuar',
      onContinue: _next,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.progress, required this.lives, required this.onClose});

  final double progress;
  final int? lives;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Salir de la sesión',
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
          Expanded(
            child: Semantics(
              label: 'Progreso de la sesión: $percent por ciento',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: progress, minHeight: 12),
              ),
            ),
          ),
          if (lives != null) ...[
            const SizedBox(width: 12),
            Semantics(
              label: 'Vidas: $lives',
              excludeSemantics: true,
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: AppColors.danger),
                  const SizedBox(width: 4),
                  Text(
                    '$lives',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedbackBar extends StatelessWidget {
  const _FeedbackBar({
    required this.isCorrect,
    required this.message,
    required this.buttonLabel,
    required this.onContinue,
  });

  final bool isCorrect;
  final String message;
  final String buttonLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.success : AppColors.danger;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: isCorrect ? AppColors.successSurface : AppColors.dangerSurface,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: color),
              onPressed: onContinue,
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.isLesson,
    required this.correctAnswers,
    required this.mistakes,
    required this.xpGained,
    required this.streak,
    required this.courseCompleted,
  });

  final bool isLesson;
  final int correctAnswers;
  final int mistakes;
  final int xpGained;
  final int streak;
  final bool courseCompleted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 88, color: AppColors.gold),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(
                isLesson ? '¡Lección completada!' : '¡Repaso terminado!',
                style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            _ResultRow(icon: Icons.bolt, label: 'XP ganada', value: '+$xpGained'),
            _ResultRow(
              icon: Icons.check_circle_outline,
              label: 'Aciertos',
              value: '$correctAnswers',
            ),
            _ResultRow(
              icon: Icons.highlight_off,
              label: 'Errores',
              value: '$mistakes',
            ),
            _ResultRow(
              icon: Icons.local_fire_department,
              label: 'Racha',
              value: '$streak ${streak == 1 ? 'día' : 'días'}',
            ),
            if (mistakes > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Las señas en las que te equivocaste quedaron en tu repaso.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(courseCompleted ? '/insignia' : '/aprender'),
              child: Text(courseCompleted ? 'Ver mi insignia' : 'Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: AppColors.navy),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 18))),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutOfLivesView extends ConsumerWidget {
  const _OutOfLivesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(progressSummaryProvider);
    final minutes = summary?.minutesToNextLife;
    final hasReview = (summary?.progress.reviewSignIds.isNotEmpty) ?? false;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.heart_broken, size: 80, color: AppColors.danger),
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(
                'Te quedaste sin vidas',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              minutes == null
                  ? 'Ya recuperaste tus vidas. Puedes volver a intentarlo.'
                  : 'Recuperarás una vida en $minutes min. Mientras tanto puedes '
                      'repasar tus errores: el repaso no gasta vidas.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            if (hasReview) ...[
              FilledButton(
                onPressed: () => context.go('/repaso'),
                child: const Text('Ir a repasar'),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton(
              onPressed: () => context.go('/aprender'),
              child: const Text('Volver al mapa'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorSavingView extends StatelessWidget {
  const _ErrorSavingView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: AppColors.danger),
            const SizedBox(height: 12),
            const Text(
              'No pudimos guardar tu progreso. Revisa tu conexión a internet.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/aprender'),
              child: const Text('Salir sin guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
