import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/state_views.dart';
import '../../content/application/content_providers.dart';
import '../../progress/application/progress_providers.dart';
import '../domain/exercise.dart';
import '../domain/exercise_generator.dart';
import 'practice_session_screen.dart';

/// Repaso de las señas en las que la persona se equivocó. No gasta vidas.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  List<SessionStep>? _steps;

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    if (steps != null) {
      return _session(steps);
    }

    final catalogAsync = ref.watch(catalogProvider);
    final progress = ref.watch(progressProvider).valueOrNull;

    return catalogAsync.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Repaso')),
        body: ErrorView(
          message: 'No pudimos cargar el repaso. Revisa tu conexión.',
          onRetry: () => ref.invalidate(catalogProvider),
        ),
      ),
      data: (catalog) {
        if (progress == null) return const Scaffold(body: LoadingView());
        final signs = catalog.signsByIds(progress.reviewSignIds);
        if (signs.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Repaso')),
            body: Column(
              children: [
                const Expanded(
                  child: EmptyView(
                    icon: Icons.verified_outlined,
                    message: 'No tienes señas pendientes de repaso. ¡Sigue así!',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: () => context.go('/aprender'),
                    child: const Text('Volver al mapa'),
                  ),
                ),
              ],
            ),
          );
        }
        final built = ExerciseGenerator().buildReviewSteps(
          signs: signs,
          pool: catalog.learnedPool(
            progress.completedLessonIds.toSet(),
            extraSignIds: progress.reviewSignIds,
          ),
        );
        _steps = built;
        return _session(built);
      },
    );
  }

  Widget _session(List<SessionStep> steps) {
    return PracticeSessionScreen(
      key: const ValueKey('review'),
      mode: SessionMode.review,
      title: 'Repaso',
      steps: steps,
      initialLives: 0,
    );
  }
}
