import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/unit_icons.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/course_catalog.dart';
import '../../content/domain/learning_unit.dart';
import '../../content/domain/lesson.dart';
import '../../progress/application/progress_providers.dart';
import '../../progress/presentation/stats_bar.dart';

/// Mapa de aprendizaje: unidades y lecciones con desbloqueo progresivo.
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(catalogProvider);
    final summary = ref.watch(progressSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: Column(
        children: [
          const StatsBar(),
          Expanded(
            child: catalogAsync.when(
              loading: () => const LoadingView(),
              error: (error, stack) => ErrorView(
                message: 'No pudimos cargar las lecciones. Revisa tu conexión.',
                onRetry: () => ref.invalidate(catalogProvider),
              ),
              data: (catalog) {
                if (catalog.lessonsInOrder.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => _refresh(ref),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        EmptyView(
                          icon: Icons.hourglass_empty,
                          message: 'Aún no hay lecciones publicadas. Las '
                              'lecciones aparecen cuando el equipo las valida '
                              'con personas sordas.',
                        ),
                      ],
                    ),
                  );
                }
                final completed =
                    (summary?.progress.completedLessonIds ?? const <String>[])
                        .toSet();
                return RefreshIndicator(
                  onRefresh: () => _refresh(ref),
                  child: _MapList(
                    catalog: catalog,
                    completed: completed,
                    reviewCount: summary?.progress.reviewSignIds.length ?? 0,
                    showStreakReminder: (summary?.streak ?? 0) > 0 &&
                        !(summary?.practicedToday ?? true),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(catalogProvider);
    try {
      await ref.read(catalogProvider.future);
    } catch (_) {
      // El error se muestra en la propia pantalla.
    }
  }
}

class _MapList extends StatelessWidget {
  const _MapList({
    required this.catalog,
    required this.completed,
    required this.reviewCount,
    required this.showStreakReminder,
  });

  final CourseCatalog catalog;
  final Set<String> completed;
  final int reviewCount;
  final bool showStreakReminder;

  @override
  Widget build(BuildContext context) {
    final statuses = catalog.statuses(completed);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (showStreakReminder)
          const _Banner(
            icon: Icons.local_fire_department,
            text: 'Practica hoy para no perder tu racha.',
          ),
        if (reviewCount > 0)
          Card(
            color: AppColors.mist,
            child: ListTile(
              leading: const Icon(Icons.refresh, color: AppColors.navy),
              title: Text(
                'Repasar $reviewCount ${reviewCount == 1 ? 'seña' : 'señas'}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Las señas en las que te equivocaste'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/repaso'),
            ),
          ),
        for (final unit in catalog.units) ..._unitSection(context, unit, statuses),
      ],
    );
  }

  List<Widget> _unitSection(
    BuildContext context,
    LearningUnit unit,
    Map<String, LessonStatus> statuses,
  ) {
    final lessons = catalog.lessonsOfUnit(unit.id);
    if (lessons.isEmpty) return const [];
    final progress = catalog.unitProgress(unit.id, completed);
    return [
      const SizedBox(height: 12),
      _UnitHeader(unit: unit, done: progress.done, total: progress.total),
      for (final lesson in lessons)
        _LessonTile(
          lesson: lesson,
          status: statuses[lesson.id] ?? LessonStatus.locked,
        ),
    ];
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9A3412)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitHeader extends StatelessWidget {
  const _UnitHeader({required this.unit, required this.done, required this.total});

  final LearningUnit unit;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final value = total == 0 ? 0.0 : done / total;
    return Card(
      color: AppColors.navy,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(unitIconFor(unit.iconKey), color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Unidad ${unit.order}: ${unit.title}',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (unit.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                unit.description,
                style: const TextStyle(color: Colors.white),
              ),
            ],
            const SizedBox(height: 10),
            Semantics(
              label: '$done de $total lecciones completadas',
              excludeSemantics: true,
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 10,
                        backgroundColor: Colors.white24,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$done/$total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (unit.culturalNote.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.diversity_3, color: AppColors.navy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        unit.culturalNote,
                        style: const TextStyle(color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson, required this.status});

  final Lesson lesson;
  final LessonStatus status;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    final String statusText;
    switch (status) {
      case LessonStatus.completed:
        icon = Icons.check_circle;
        color = AppColors.success;
        statusText = 'Completada';
      case LessonStatus.available:
        icon = Icons.play_circle_fill;
        color = AppColors.navy;
        statusText = 'Disponible';
      case LessonStatus.locked:
        icon = Icons.lock;
        color = AppColors.locked;
        statusText = 'Bloqueada: completa la lección anterior';
    }
    final locked = status == LessonStatus.locked;

    return Semantics(
      button: true,
      enabled: !locked,
      label: '${lesson.title}. $statusText. ${lesson.signIds.length} señas.',
      excludeSemantics: true,
      child: Card(
        margin: const EdgeInsets.only(top: 8),
        child: ListTile(
          minVerticalPadding: 12,
          leading: Icon(icon, color: color, size: 36),
          title: Text(
            lesson.title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: locked ? AppColors.locked : AppColors.ink,
            ),
          ),
          subtitle: Text('$statusText · ${lesson.signIds.length} señas'),
          trailing: Icon(locked ? null : Icons.chevron_right),
          onTap: () {
            if (locked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Completa la lección anterior para desbloquearla.'),
                ),
              );
              return;
            }
            context.push('/leccion/${lesson.id}');
          },
        ),
      ),
    );
  }
}
