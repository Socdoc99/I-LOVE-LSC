import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../content/application/content_providers.dart';
import '../application/progress_providers.dart';

/// Seguimiento: XP acumulada, racha, vidas y unidades completadas.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(progressSummaryProvider);
    final catalogAsync = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi progreso')),
      body: summary == null
          ? const LoadingView()
          : catalogAsync.when(
              loading: () => const LoadingView(),
              error: (error, stack) => ErrorView(
                message: 'No pudimos cargar tu progreso. Revisa tu conexión.',
                onRetry: () => ref.invalidate(catalogProvider),
              ),
              data: (catalog) {
                final progress = summary.progress;
                final completed = progress.completedLessonIds.toSet();
                final unitsWithLessons = [
                  for (final unit in catalog.units)
                    if (catalog.lessonsOfUnit(unit.id).isNotEmpty) unit,
                ];
                final unitsDone = unitsWithLessons.where((unit) {
                  final p = catalog.unitProgress(unit.id, completed);
                  return p.total > 0 && p.done == p.total;
                }).length;
                final reviewCount = progress.reviewSignIds.length;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _Metric(
                          icon: Icons.bolt,
                          label: 'XP acumulada',
                          value: '${summary.xp}',
                        ),
                        _Metric(
                          icon: Icons.local_fire_department,
                          label: 'Racha',
                          value:
                              '${summary.streak} ${summary.streak == 1 ? 'día' : 'días'}',
                        ),
                        _Metric(
                          icon: Icons.favorite,
                          label: 'Vidas',
                          value: '${summary.lives}/${GamificationConfig.maxLives}',
                        ),
                        _Metric(
                          icon: Icons.flag,
                          label: 'Unidades completadas',
                          value: '$unitsDone/${unitsWithLessons.length}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Semantics(
                      header: true,
                      child: Text(
                        'Avance por unidad',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (unitsWithLessons.isEmpty)
                      const Text('Aún no hay lecciones publicadas.'),
                    for (final unit in unitsWithLessons)
                      _UnitRow(
                        title: 'Unidad ${unit.order}: ${unit.title}',
                        done: catalog.unitProgress(unit.id, completed).done,
                        total: catalog.unitProgress(unit.id, completed).total,
                      ),
                    const SizedBox(height: 16),
                    if (reviewCount > 0)
                      Card(
                        color: AppColors.mist,
                        child: ListTile(
                          leading: const Icon(Icons.refresh, color: AppColors.navy),
                          title: Text(
                            'Tienes $reviewCount ${reviewCount == 1 ? 'seña' : 'señas'} para repasar',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/repaso'),
                        ),
                      ),
                    const SizedBox(height: 8),
                    progress.completedAt != null
                        ? FilledButton.icon(
                            onPressed: () => context.push('/insignia'),
                            icon: const Icon(Icons.workspace_premium),
                            label: const Text('Ver mi insignia digital'),
                          )
                        : Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.mist,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.workspace_premium, color: AppColors.navy),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Completa todas las lecciones para obtener '
                                    'tu constancia o insignia digital.',
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ],
                );
              },
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.navy),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({required this.title, required this.done, required this.total});

  final String title;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title: $done de $total lecciones completadas',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('$done/$total'),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : done / total,
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
